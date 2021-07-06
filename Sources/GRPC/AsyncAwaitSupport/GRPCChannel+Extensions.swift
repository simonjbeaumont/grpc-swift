import NIO
import NIOHTTP2
import NIOSSL
import SwiftProtobuf

extension GRPCChannel {
  /// Make a unary gRPC call.
  ///
  /// - Parameters:
  ///   - path: Path of the RPC, e.g. "/echo.Echo/Get"
  ///   - request: The request to send.
  ///   - callOptions: Options for the RPC.
  ///   - interceptors: A list of interceptors to intercept the request and response stream with.
  public func makeAsyncUnaryCall<Request: Message, Response: Message>(
    path: String,
    request: Request,
    callOptions: CallOptions,
    interceptors: [ClientInterceptor<Request, Response>] = []
  ) -> AsyncUnaryCall<Request, Response> {
    let unary: AsyncUnaryCall<Request, Response> = AsyncUnaryCall(
      call: self.makeCall(
        path: path,
        type: .unary,
        callOptions: callOptions,
        interceptors: interceptors
      )
    )
    unary.invoke(request)
    return unary
  }

  /// Make a unary gRPC call.
  ///
  /// - Parameters:
  ///   - path: Path of the RPC, e.g. "/echo.Echo/Get"
  ///   - request: The request to send.
  ///   - callOptions: Options for the RPC.
  ///   - interceptors: A list of interceptors to intercept the request and response stream with.
  public func makeAsyncUnaryCall<Request: GRPCPayload, Response: GRPCPayload>(
    path: String,
    request: Request,
    callOptions: CallOptions,
    interceptors: [ClientInterceptor<Request, Response>] = []
  ) -> AsyncUnaryCall<Request, Response> {
    let rpc: AsyncUnaryCall<Request, Response> = AsyncUnaryCall(
      call: self.makeCall(
        path: path,
        type: .unary,
        callOptions: callOptions,
        interceptors: interceptors
      )
    )
    rpc.invoke(request)
    return rpc
  }

  /// Makes a client-streaming gRPC call.
  ///
  /// - Parameters:
  ///   - path: Path of the RPC, e.g. "/echo.Echo/Get"
  ///   - callOptions: Options for the RPC.
  ///   - interceptors: A list of interceptors to intercept the request and response stream with.
  public func makeAsyncClientStreamingCall<Request: Message, Response: Message>(
    path: String,
    callOptions: CallOptions,
    interceptors: [ClientInterceptor<Request, Response>] = []
  ) -> AsyncClientStreamingCall<Request, Response> {
    let rpc: AsyncClientStreamingCall<Request, Response> = AsyncClientStreamingCall(
      call: self.makeCall(
        path: path,
        type: .clientStreaming,
        callOptions: callOptions,
        interceptors: interceptors
      )
    )
    rpc.invoke()
    return rpc
  }

  /// Makes a client-streaming gRPC call.
  ///
  /// - Parameters:
  ///   - path: Path of the RPC, e.g. "/echo.Echo/Get"
  ///   - callOptions: Options for the RPC.
  ///   - interceptors: A list of interceptors to intercept the request and response stream with.
  public func makeAsyncClientStreamingCall<Request: GRPCPayload, Response: GRPCPayload>(
    path: String,
    callOptions: CallOptions,
    interceptors: [ClientInterceptor<Request, Response>] = []
  ) -> AsyncClientStreamingCall<Request, Response> {
    let rpc: AsyncClientStreamingCall<Request, Response> = AsyncClientStreamingCall(
      call: self.makeCall(
        path: path,
        type: .clientStreaming,
        callOptions: callOptions,
        interceptors: interceptors
      )
    )
    rpc.invoke()
    return rpc
  }

  /// Make a server-streaming gRPC call.
  ///
  /// - Parameters:
  ///   - path: Path of the RPC, e.g. "/echo.Echo/Get"
  ///   - request: The request to send.
  ///   - callOptions: Options for the RPC.
  ///   - interceptors: A list of interceptors to intercept the request and response stream with.
  public func makeAsyncServerStreamingCall<Request: Message, Response: Message>(
    path: String,
    request: Request,
    callOptions: CallOptions,
    interceptors: [ClientInterceptor<Request, Response>] = []
  ) -> AsyncServerStreamingCall<Request, Response> {
    return AsyncServerStreamingCall.makeAndInvoke(
      call: self.makeCall(
        path: path,
        type: .serverStreaming,
        callOptions: callOptions,
        interceptors: interceptors
      ),
      request
    )
  }

  /// Make a server-streaming gRPC call.
  ///
  /// - Parameters:
  ///   - path: Path of the RPC, e.g. "/echo.Echo/Get"
  ///   - request: The request to send.
  ///   - callOptions: Options for the RPC.
  ///   - interceptors: A list of interceptors to intercept the request and response stream with.
  public func makeAsyncServerStreamingCall<Request: GRPCPayload, Response: GRPCPayload>(
    path: String,
    request: Request,
    callOptions: CallOptions,
    interceptors: [ClientInterceptor<Request, Response>] = []
  ) -> AsyncServerStreamingCall<Request, Response> {
    return AsyncServerStreamingCall.makeAndInvoke(
      call: self.makeCall(
        path: path,
        type: .serverStreaming,
        callOptions: callOptions,
        interceptors: []
      ),
      request
    )
  }

  /// Makes a bidirectional-streaming gRPC call.
  ///
  /// - Parameters:
  ///   - path: Path of the RPC, e.g. "/echo.Echo/Get"
  ///   - callOptions: Options for the RPC.
  ///   - interceptors: A list of interceptors to intercept the request and response stream with.
  public func makeAsyncBidirectionalStreamingCall<Request: Message, Response: Message>(
    path: String,
    callOptions: CallOptions,
    interceptors: [ClientInterceptor<Request, Response>] = []
  ) -> AsyncBidirectionalStreamingCall<Request, Response> {
    return AsyncBidirectionalStreamingCall.makeAndInvoke(
      call: self.makeCall(
        path: path,
        type: .bidirectionalStreaming,
        callOptions: callOptions,
        interceptors: interceptors
      )
    )
  }

  /// Makes a bidirectional-streaming gRPC call.
  ///
  /// - Parameters:
  ///   - path: Path of the RPC, e.g. "/echo.Echo/Get"
  ///   - callOptions: Options for the RPC.
  ///   - interceptors: A list of interceptors to intercept the request and response stream with.
  public func makeAsyncBidirectionalStreamingCall<Request: GRPCPayload, Response: GRPCPayload>(
    path: String,
    callOptions: CallOptions,
    interceptors: [ClientInterceptor<Request, Response>] = []
  ) -> AsyncBidirectionalStreamingCall<Request, Response> {
    return AsyncBidirectionalStreamingCall.makeAndInvoke(
      call: self.makeCall(
        path: path,
        type: .bidirectionalStreaming,
        callOptions: callOptions,
        interceptors: interceptors
      )
    )
  }
}