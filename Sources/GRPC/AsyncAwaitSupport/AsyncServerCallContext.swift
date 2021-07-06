import Logging
import NIOHPACK

public protocol AsyncServerCallContext /* Do we want this to be an actor? */ {
  /// Request headers for this request.
  var headers: HPACKHeaders { get }

  /// A 'UserInfo' dictionary which is shared with the interceptor contexts for this RPC.
  var userInfo: UserInfo { get set }

  /// The logger used for this call.
  var logger: Logger { get }

  /// Whether compression should be enabled for responses, defaulting to `true`. Note that for
  /// this value to take effect compression must have been enabled on the server and a compression
  /// algorithm must have been negotiated with the client.
  var compressionEnabled: Bool { get set }

  // TODO: Probably need to be able to set some response headers and trailers.
}

/// The intention is that we will provide a new concrete implementation of
/// `AsyncServerCallContext` that is independent of the existing
/// `ServerCallContext` family of classes. But for now we just provide a view
/// over the existing ones to get us going.
extension ServerCallContextBase: AsyncServerCallContext {}
