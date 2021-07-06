import EchoModel
import GRPC

public class EchoAsyncProvider: Echo_AsyncEchoProvider {
  public let interceptors: Echo_EchoServerInterceptorFactoryProtocol?

  public init(interceptors: Echo_EchoServerInterceptorFactoryProtocol? = nil) {
    self.interceptors = interceptors
  }

  public func get(
    request: Echo_EchoRequest,
    context: AsyncServerCallContext
  ) async throws -> Echo_EchoResponse {
    .with { $0.text = "Swift echo get: \(request.text)" }
  }

  public func expand(
    request: Echo_EchoRequest,
    responseStreamWriter: AsyncResponseStreamWriter<Echo_EchoResponse>,
    context: AsyncServerCallContext
  ) async throws {
    for (i, part) in request.text.components(separatedBy: " ").lazy.enumerated() {
      try await responseStreamWriter.sendResponse(.with { $0.text = "Swift echo expand (\(i)): \(part)" })
    }
  }

  public func collect(
    requests: GRPCAsyncStream<Echo_EchoRequest>,
    context: AsyncServerCallContext
  ) async throws -> Echo_EchoResponse {
    var parts: [String] = []
    for try await request in requests {
      parts.append(request.text)
    }
    return .with {
      $0.text = "Swift echo collect: \(parts.joined(separator: " "))"
    }
  }

  public func update(
    requests: GRPCAsyncStream<Echo_EchoRequest>,
    responseStreamWriter: AsyncResponseStreamWriter<Echo_EchoResponse>,
    context: AsyncServerCallContext
  ) async throws {
    var count = 0
    for try await request in requests {
        let response = Echo_EchoResponse.with {
          $0.text = "Swift echo update (\(count)): \(request.text)"
        }
        count += 1
        try await responseStreamWriter.sendResponse(response)
    }
  }
}