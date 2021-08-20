/*
 * Copyright 2021, gRPC Authors All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Logging
import NIOCore
import NIOHPACK
import NIOHTTP2

#if compiler(>=5.5)

/// Async-await variant of `ServerStreamingCall`.
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public struct AsyncServerStreamingCall<RequestPayload, ResponsePayload>: AsyncClientCall {
  private let call: Call<RequestPayload, ResponsePayload>
  private let responseParts: StreamingResponseParts<ResponsePayload>
  public let responseStream: GRPCAsyncStream<ResponsePayload>

  /// The options used to make the RPC.
  public var options: CallOptions {
    return self.call.options
  }

  /// The `Channel` used to transport messages for this RPC.
  public var subchannel: Channel {
    get async throws {
      try await self.call.channel.get()
    }
  }

  /// Cancel this RPC if it hasn't already completed.
  public func cancel() async throws {
    try await self.call.cancel().get()
  }

  // MARK: - Response Parts

  /// The initial metadata returned from the server.
  public var initialMetadata: HPACKHeaders {
    get async throws {
      try await self.responseParts.initialMetadata.get()
    }
  }

  /// The trailing metadata returned from the server.
  public var trailingMetadata: HPACKHeaders {
    get async throws {
      try await self.responseParts.trailingMetadata.get()
    }
  }

  /// The final status of the the RPC.
  public var status: GRPCStatus {
    get async {
      try! await self.responseParts.status.get()
    }
  }

  private init(
    call: Call<RequestPayload, ResponsePayload>,
    _ request: RequestPayload
  ) {
    self.call = call
    // Initialise `responseParts` with an empty response handler because we
    // provide the responses as an AsyncSequence in `responseStream`.
    self.responseParts = StreamingResponseParts(on: call.eventLoop) { _ in }

    // Call and StreamingResponseParts are reference types so we grab a
    // referecence to them here to avoid capturing mutable self in the  closure
    // passed to the AsyncThrowingStream initializer.
    //
    // The alternative would be to declare the responseStream as:
    // ```
    // public private(set) var responseStream: AsyncThrowingStream<ResponsePayload>!
    // ```
    //
    // UPDATE: Additionally we expect to replace this soon with an AsyncSequence
    // implementation that supports yielding values from outside the closure.
    let call = self.call
    let responseParts = self.responseParts
    self
      .responseStream = GRPCAsyncStream(AsyncThrowingStream(ResponsePayload.self) { continuation in
        call.invokeUnaryRequest(request) { error in
          responseParts.handleError(error)
          continuation.finish(throwing: error)
        } onResponsePart: { responsePart in
          responseParts.handle(responsePart)
          switch responsePart {
          case let .message(response): continuation.yield(response)
          case .metadata: break
          case .end: continuation.finish()
          }
        }
      })
  }

  /// We expose this as the only non-private initializer so that the caller
  /// knows that invocation is part of initialisation.
  internal static func makeAndInvoke(
    call: Call<RequestPayload, ResponsePayload>,
    _ request: RequestPayload
  ) -> Self {
    Self(call: call, request)
  }
}

#endif