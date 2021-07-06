import GRPC

/// Async-await variant of  `Echo_EchoProvider`.
public protocol Echo_AsyncEchoProvider: CallHandlerProvider {
  var interceptors: Echo_EchoServerInterceptorFactoryProtocol? { get }

  /// Immediately returns an echo of a request.
  func get(
    request: Echo_EchoRequest,
    context: AsyncServerCallContext
  ) async throws -> Echo_EchoResponse

  /// Splits a request into words and returns each word in a stream of messages.
  func expand(
    request: Echo_EchoRequest,
    responseStreamWriter: AsyncResponseStreamWriter<Echo_EchoResponse>,
    context: AsyncServerCallContext
  ) async throws

  /// Collects a stream of messages and returns them concatenated when the caller closes.
  func collect(
    requests: GRPCAsyncStream<Echo_EchoRequest>,
    context: AsyncServerCallContext
  ) async throws -> Echo_EchoResponse

  /// Streams back messages as they are received in an input stream.
  ///
  /// TODO: We should decide whether we want these functions to explicitly
  /// return a `GRPCStatus` or not. Doing so would be more similar to the
  /// non-async-await API where the user completes a `GRPCStatus` promise. But
  /// it might be nicer to move to an implicit `.ok` or throws model. The C# API
  /// has this but can also (probably) constain the throws which we cannot do in
  /// Swift. So, to summarise, the options are:
  ///
  /// 1. Have this function return void, or throw a `GRPCStatus` or `GRPCStatusTransformable`.
  /// 2. Have this function return `GRPCStatus` and allow throwing.
  /// 3. Have this function return `GRPCStatus` and _not_ throw.
  ///
  /// I think the best thing is to return void or throw because otherwise we
  /// would need the non-streaming calls to return a tuple for symmetry which
  /// would feel a bit clunky.
  func update(
    requests: GRPCAsyncStream<Echo_EchoRequest>,
    responseStreamWriter: AsyncResponseStreamWriter<Echo_EchoResponse>,
    context: AsyncServerCallContext
  ) async throws
}

extension Echo_AsyncEchoProvider {
  public var serviceName: Substring { return "echo.Echo" }

  /// Determines, calls and returns the appropriate request handler, depending on the request's method.
  /// Returns nil for methods not handled by this service.
  public func handle(
    method name: Substring,
    context: CallHandlerContext
  ) -> GRPCServerHandlerProtocol? {
    switch name {
    case "Get":
      return AsyncUnaryServerHandler(
        context: context,
        requestDeserializer: ProtobufDeserializer<Echo_EchoRequest>(),
        responseSerializer: ProtobufSerializer<Echo_EchoResponse>(),
        interceptors: self.interceptors?.makeGetInterceptors() ?? [],
        userFunction: self.get(request:context:)
      )

    case "Expand":
      return AsyncServerStreamingServerHandler(
        context: context,
        requestDeserializer: ProtobufDeserializer<Echo_EchoRequest>(),
        responseSerializer: ProtobufSerializer<Echo_EchoResponse>(),
        interceptors: self.interceptors?.makeExpandInterceptors() ?? [],
        userFunction: self.expand(request:responseStreamWriter:context:)
      )

    case "Collect":
      return AsyncClientStreamingServerHandler(
        context: context,
        requestDeserializer: ProtobufDeserializer<Echo_EchoRequest>(),
        responseSerializer: ProtobufSerializer<Echo_EchoResponse>(),
        interceptors: self.interceptors?.makeCollectInterceptors() ?? [],
        observer: self.collect(requests:context:)
      )

    case "Update":
      return AsyncBidirectionalStreamingServerHandler(
        context: context,
        requestDeserializer: ProtobufDeserializer<Echo_EchoRequest>(),
        responseSerializer: ProtobufSerializer<Echo_EchoResponse>(),
        interceptors: self.interceptors?.makeUpdateInterceptors() ?? [],
        observer: self.update(requests:responseStreamWriter:context:)
      )

    default:
      return nil
    }
  }
}