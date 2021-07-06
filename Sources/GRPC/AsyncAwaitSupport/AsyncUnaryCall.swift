import Foundation
import Logging
import NIO
import NIOHPACK
import NIOHTTP1
import NIOHTTP2
import SwiftProtobuf

/// A unary gRPC call. The request is sent on initialization.
///
/// Note: while this object is a `struct`, its implementation delegates to `Call`. It therefore
/// has reference semantics.
public struct AsyncUnaryCall<RequestPayload, ResponsePayload>: AsyncUnaryResponseClientCall {
  private let call: Call<RequestPayload, ResponsePayload>
  private let responseParts: UnaryResponseParts<ResponsePayload>

  /// The options used to make the RPC.
  public var options: CallOptions {
    self.call.options
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

  /// The response message returned from the service if the call is successful. This may be failed
  /// if the call encounters an error.
  ///
  /// Callers should rely on the `status` of the call for the canonical outcome.
  public var response: ResponsePayload {
    get async throws {
      try await self.responseParts.response.get()
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
      // force-try because this future will _always_ be fulfilled with success.
      try! await self.responseParts.status.get()
    }
  }

  internal init(call: Call<RequestPayload, ResponsePayload>) {
    self.call = call
    self.responseParts = UnaryResponseParts(on: call.eventLoop)
  }

  internal func invoke(_ request: RequestPayload) {
    self.call.invokeUnaryRequest(
      request,
      onError: self.responseParts.handleError(_:),
      onResponsePart: self.responseParts.handle(_:)
    )
  }
}
