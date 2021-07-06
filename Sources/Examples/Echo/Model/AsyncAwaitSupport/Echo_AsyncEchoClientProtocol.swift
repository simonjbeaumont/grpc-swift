import GRPC

// TODO: Remove the UseingAsyncCall suffix from functions
public protocol Echo_AsyncEchoClientProtocol: GRPCClient {
	var serviceName: String { get }
	var interceptors: Echo_EchoClientInterceptorFactoryProtocol? { get }

	func makeGetCall(
		_ request: Echo_EchoRequest,
		callOptions: CallOptions?
	) -> AsyncUnaryCall<Echo_EchoRequest, Echo_EchoResponse>

	func makeExpandCall(
		_ request: Echo_EchoRequest,
		callOptions: CallOptions?
	) -> AsyncServerStreamingCall<Echo_EchoRequest, Echo_EchoResponse>

	func makeCollectCall(
		callOptions: CallOptions?
	) -> AsyncClientStreamingCall<Echo_EchoRequest, Echo_EchoResponse>

	func makeUpdateCall(
		callOptions: CallOptions?
	) -> AsyncBidirectionalStreamingCall<Echo_EchoRequest, Echo_EchoResponse>
}

extension Echo_AsyncEchoClientProtocol {
	public var serviceName: String {
		return "echo.Echo"
	}

  /// Immediately returns an echo of a request.
  ///
  /// - Parameters:
  ///   - request: Request to send to Get.
  ///   - callOptions: Call options.
  /// - Returns: An `AsyncUnaryCall` with properties for the metadata, status and response.
	public func makeGetCall(
		_ request: Echo_EchoRequest,
		callOptions: CallOptions? = nil
	) -> AsyncUnaryCall<Echo_EchoRequest, Echo_EchoResponse> {
		return self.makeAsyncUnaryCall(
			path: "/echo.Echo/Get",
			request: request,
			callOptions: callOptions ?? self.defaultCallOptions,
			interceptors: self.interceptors?.makeGetInterceptors() ?? []
		)
	}

  /// Splits a request into words and returns each word in a stream of messages.
  ///
  /// - Parameters:
  ///   - request: Request to send to Expand.
  ///   - callOptions: Call options.
  /// - Returns: An `AsyncServerStreamingCall` with properties for the metadata, status and response stream.
	public func makeExpandCall(
		_ request: Echo_EchoRequest,
		callOptions: CallOptions? = nil
	) -> AsyncServerStreamingCall<Echo_EchoRequest, Echo_EchoResponse> {
		return self.makeAsyncServerStreamingCall(
			path: "/echo.Echo/Expand",
			request: request,
			callOptions: callOptions ?? self.defaultCallOptions,
			interceptors: self.interceptors?.makeExpandInterceptors() ?? []
		)
	}

  /// Collects a stream of messages and returns them concatenated when the caller closes.
  ///
  /// Callers should use the `send` method on the returned object to send messages
  /// to the server. The caller should send an `.end` after the final message has been sent.
  ///
  /// - Parameters:
  ///   - callOptions: Call options.
  /// - Returns: An `AsyncClientStreamingCall` with properties for the metadata, status and response.
	public func makeCollectCall(
		callOptions: CallOptions? = nil
	) -> AsyncClientStreamingCall<Echo_EchoRequest, Echo_EchoResponse> {
		return self.makeAsyncClientStreamingCall(
			path: "/echo.Echo/Collect",
			callOptions: callOptions ?? self.defaultCallOptions,
			interceptors: self.interceptors?.makeCollectInterceptors() ?? []
		)
	}

  /// Streams back messages as they are received in an input stream.
  ///
  /// Callers should use the `send` method on the returned object to send messages
  /// to the server. The caller should send an `.end` after the final message has been sent.
  ///
  /// - Parameters:
  ///   - callOptions: Call options.
  /// - Returns: A `AsyncBidirectionalStreamingCall` with properties for the metadata, status and response stream.
	public func makeUpdateCall(
		callOptions: CallOptions? = nil
	) -> AsyncBidirectionalStreamingCall<Echo_EchoRequest, Echo_EchoResponse> {
		return self.makeAsyncBidirectionalStreamingCall(
			path: "/echo.Echo/Update",
			callOptions: callOptions ?? self.defaultCallOptions,
			interceptors: self.interceptors?.makeUpdateInterceptors() ?? []
		)
	}
}
