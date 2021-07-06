public struct AsyncResponseStreamWriter<ResponsePayload> {
  @usableFromInline
  internal let _context: AsyncServerCallContext

  @usableFromInline
  internal let _sendResponse: (ResponsePayload, MessageMetadata) async throws -> Void

  @usableFromInline
  internal let _compressionEnabledOnServer: Bool

  // Create a new AsyncResponseStreamWriter.
  //
  // - Important: the `sendResponse` closure must be thread-safe.
  @inlinable
  internal init(
    context: AsyncServerCallContext,
    compressionIsEnabled: Bool,
    sendResponse: @escaping (ResponsePayload, MessageMetadata) async throws -> Void
  ) {
    self._context = context
    self._compressionEnabledOnServer = compressionIsEnabled
    self._sendResponse = sendResponse
  }

  @inlinable
  internal func shouldCompress(_ compression: Compression) -> Bool {
    guard self._compressionEnabledOnServer else {
      return false
    }
    return compression.isEnabled(callDefault: self._context.compressionEnabled)
  }

  @inlinable
  public func sendResponse(
    _ response: ResponsePayload,
    compression: Compression = .deferToCallDefault
  ) async throws {
    let compress = self.shouldCompress(compression)
    try await self._sendResponse(response, .init(compress: compress, flush: true))
  }
}
