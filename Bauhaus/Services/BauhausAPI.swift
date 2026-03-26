import Foundation

final class BauhausAPI {
    static let shared = BauhausAPI()

    private let session: URLSession

    static let imageURL = URL(string: "https://bauhaus.cascadiacollections.workers.dev/api/today?format=jpeg")!
    private static let metadataURL = URL(string: "https://bauhaus.cascadiacollections.workers.dev/api/today.json")!

    private init() {
        let cache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 50 * 1024 * 1024,
            diskPath: "bauhaus"
        )
        // Share this cache with AsyncImage (which uses URLSession.shared)
        URLCache.shared = cache

        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .useProtocolCachePolicy
        session = URLSession(configuration: config)
    }

    func fetchMetadata() async throws -> ArtworkMetadata {
        let (data, _) = try await session.data(from: Self.metadataURL)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ArtworkMetadata.self, from: data)
    }
}
