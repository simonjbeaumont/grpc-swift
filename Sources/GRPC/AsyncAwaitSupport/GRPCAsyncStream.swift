/// This is currently a wrapper around AsyncThrowingStream because we want to be
/// able to swap out the implementation for something else in the future.
public struct GRPCAsyncStream<Element>: AsyncSequence {
  @usableFromInline
  internal let stream: AsyncThrowingStream<Element>

  @inlinable
  internal init(_ stream: AsyncThrowingStream<Element>) {
    self.stream = stream
  }

  __consuming public func makeAsyncIterator() -> Iterator {
    Self.AsyncIterator(self.stream)
  }

  public struct Iterator: AsyncIteratorProtocol {
    @usableFromInline
    internal var iterator: AsyncThrowingStream<Element>.AsyncIterator

    fileprivate init(_ stream: AsyncThrowingStream<Element>) {
      self.iterator = stream.makeAsyncIterator()
    }

    @inlinable
    public mutating func next() async throws -> Element? {
      try await self.iterator.next()
    }
  }
}


