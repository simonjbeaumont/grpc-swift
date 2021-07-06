import NIO
import NIOHTTP2
import SwiftProtobuf

extension GRPCClient {
  public func makeAsyncUnaryCall<Request: SwiftProtobuf.Message, Response: SwiftProtobuf.Message>(
    path: String,
    request: Request,
    callOptions: CallOptions? = nil,
    interceptors: [ClientInterceptor<Request, Response>] = [],
    responseType: Response.Type = Response.self
  ) -> AsyncUnaryCall<Request, Response> {
    return self.channel.makeAsyncUnaryCall(
      path: path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: interceptors
    )
  }

  public func makeAsyncUnaryCall<Request: GRPCPayload, Response: GRPCPayload>(
    path: String,
    request: Request,
    callOptions: CallOptions? = nil,
    interceptors: [ClientInterceptor<Request, Response>] = [],
    responseType: Response.Type = Response.self
  ) -> AsyncUnaryCall<Request, Response> {
    return self.channel.makeAsyncUnaryCall(
      path: path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: interceptors
    )
  }

  public func makeAsyncServerStreamingCall<
    Request: SwiftProtobuf.Message,
    Response: SwiftProtobuf.Message
  >(
    path: String,
    request: Request,
    callOptions: CallOptions? = nil,
    interceptors: [ClientInterceptor<Request, Response>] = [],
    responseType: Response.Type = Response.self
  ) -> AsyncServerStreamingCall<Request, Response> {
    return self.channel.makeAsyncServerStreamingCall(
      path: path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: interceptors
    )
  }

  public func makeAsyncServerStreamingCall<Request: GRPCPayload, Response: GRPCPayload>(
    path: String,
    request: Request,
    callOptions: CallOptions? = nil,
    interceptors: [ClientInterceptor<Request, Response>] = [],
    responseType: Response.Type = Response.self
  ) -> AsyncServerStreamingCall<Request, Response> {
    return self.channel.makeAsyncServerStreamingCall(
      path: path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: interceptors
    )
  }

  public func makeAsyncClientStreamingCall<
    Request: SwiftProtobuf.Message,
    Response: SwiftProtobuf.Message
  >(
    path: String,
    callOptions: CallOptions? = nil,
    interceptors: [ClientInterceptor<Request, Response>] = [],
    requestType: Request.Type = Request.self,
    responseType: Response.Type = Response.self
  ) -> AsyncClientStreamingCall<Request, Response> {
    return self.channel.makeAsyncClientStreamingCall(
      path: path,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: interceptors
    )
  }

  public func makeAsyncClientStreamingCall<Request: GRPCPayload, Response: GRPCPayload>(
    path: String,
    callOptions: CallOptions? = nil,
    interceptors: [ClientInterceptor<Request, Response>] = [],
    requestType: Request.Type = Request.self,
    responseType: Response.Type = Response.self
  ) -> AsyncClientStreamingCall<Request, Response> {
    return self.channel.makeAsyncClientStreamingCall(
      path: path,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: interceptors
    )
  }

  public func makeAsyncBidirectionalStreamingCall<
    Request: SwiftProtobuf.Message,
    Response: SwiftProtobuf.Message
  >(
    path: String,
    callOptions: CallOptions? = nil,
    interceptors: [ClientInterceptor<Request, Response>] = [],
    requestType: Request.Type = Request.self,
    responseType: Response.Type = Response.self
  ) -> AsyncBidirectionalStreamingCall<Request, Response> {
    return self.channel.makeAsyncBidirectionalStreamingCall(
      path: path,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: interceptors
    )
  }

  public func makeAsyncBidirectionalStreamingCall<
    Request: GRPCPayload,
    Response: GRPCPayload
  >(
    path: String,
    callOptions: CallOptions? = nil,
    interceptors: [ClientInterceptor<Request, Response>] = [],
    requestType: Request.Type = Request.self,
    responseType: Response.Type = Response.self
  ) -> AsyncBidirectionalStreamingCall<Request, Response> {
    return self.channel.makeAsyncBidirectionalStreamingCall(
      path: path,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: interceptors
    )
  }
}