import Foundation

final class BauhausAPI {
    static let shared = BauhausAPI()

    private let session: URLSession
    private static let base = "https://bauhaus.cascadiacollections.workers.dev"

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

    // MARK: - URL builders

    static func imageURL(for date: Date = Date()) -> URL {
        if Calendar.current.isDateInToday(date) {
            return URL(string: "\(base)/api/today?format=jpeg")!
        }
        return URL(string: "\(base)/api/\(dateString(from: date))?format=jpeg")!
    }

    static func metadataURL(for date: Date = Date()) -> URL {
        if Calendar.current.isDateInToday(date) {
            return URL(string: "\(base)/api/today.json")!
        }
        return URL(string: "\(base)/api/\(dateString(from: date)).json")!
    }

    static func dateString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }

    // MARK: - Fetch

    func fetchMetadata(for date: Date = Date()) async throws -> ArtworkMetadata {
        let (data, _) = try await session.data(from: Self.metadataURL(for: date))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ArtworkMetadata.self, from: data)
    }
}
