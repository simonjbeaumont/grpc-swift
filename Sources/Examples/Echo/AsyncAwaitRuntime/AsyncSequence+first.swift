import Foundation

internal extension AsyncSequence {
 func first() async throws -> Element? {
   return try await self.first { _ in true }
 }
}