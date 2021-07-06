import GRPC

/// Some "convenience" wrappers for users who have an AsyncSequence to work with.
///
/// Thoughts: It's not super obvious that these _are_ convenient and it's
/// possible that they instead open up a can of worms. E.g. if we expose the
/// ability to pass in an AsyncSequence of requests and automagically send end
/// on behalf of the user then what would happen if they were also using the
/// other API to sendMessage/sendEnd concurrently?
///
/// It's for this reason that these currently do not return the `Call` object,
/// but instead just a response or response stream. But this limits their value
/// since the user will not be able to check for the metadata about the call
/// once it has completed.
///
/// Ways around this include:
///
/// 1. Provide a responseStream and a view over the Call that does not allow for
///    send message and send end.
///
/// 2. Rework the APIs so that they return a simple Call (that does not expose
///    sendMessage/End) that is used to get the response/responseStream and a
///    requestWriter which is used to sendMessage/SendEnd.
///
/// Neither of these seem amazing on the surface and maybe we should just allow
/// the user who has an AsyncSequecne source for their request to use the
/// builtin combinators for AsyncSequence to make calls to our
/// sendMessage/sendMessages.
extension Echo_AsyncEchoClientProtocol {
  public func get(
    _ request: Echo_EchoRequest,
    callOptions: CallOptions? = nil
  ) async throws -> Echo_EchoResponse {
    try await self.makeGetCall(request, callOptions: callOptions).response
  }

  public func collect<RequestStream>(
    requests: RequestStream,
    callOptions: CallOptions? = nil
  ) async throws -> Echo_EchoResponse
  where RequestStream: AsyncSequence, RequestStream.Element == Echo_EchoRequest {
    let collect = self.makeCollectCall(callOptions: callOptions)

    return try await withTaskCancellationHandler {
      try Task.checkCancellation()
      for try await request in requests {
        try Task.checkCancellation()
        try await collect.sendMessage(request)
      }
      try Task.checkCancellation()
      try await collect.sendEnd()
      return try await collect.response
    } onCancel: {
      Task.detached { try await collect.cancel() }
    }
  }

  public func expand(
    _ request: Echo_EchoRequest,
    callOptions: CallOptions? = nil
  ) -> GRPCAsyncStream<Echo_EchoResponse> {
    self.makeExpandCall(request, callOptions: callOptions).responseStream
  }

  public func update<RequestStream>(
    requests: RequestStream,
    callOptions: CallOptions? = nil
  ) -> GRPCAsyncStream<Echo_EchoResponse>
  where RequestStream: AsyncSequence, RequestStream.Element == Echo_EchoRequest {
    let update = self.makeUpdateCall(callOptions: callOptions)

    Task {
      try await withTaskCancellationHandler {
        try Task.checkCancellation()
        for try await request in requests {
          try Task.checkCancellation()
          try await update.sendMessage(request)
        }
        try Task.checkCancellation()
        try await update.sendEnd()
      } onCancel: {
        Task.detached { try await update.cancel() }
      }
    }

    return update.responseStream
  }
}
