import Foundation

final class BauhausAPI {
    static let shared = BauhausAPI()

    private let session: URLSession

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

    private static let baseURL = URL(string: "https://bauhaus.cascadiacollections.workers.dev")!

    static func imageURL(for date: Date = Date()) -> URL {
        if Calendar.current.isDateInToday(date) {
            var components = URLComponents(url: baseURL.appendingPathComponent("api/today"), resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "format", value: "jpeg")]
            return components.url!
        }
        var components = URLComponents(url: baseURL.appendingPathComponent("api/\(dateString(from: date))"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "format", value: "jpeg")]
        return components.url!
    }

    static func metadataURL(for date: Date = Date()) -> URL {
        if Calendar.current.isDateInToday(date) {
            return baseURL.appendingPathComponent("api/today.json")
        }
        return baseURL.appendingPathComponent("api/\(dateString(from: date)).json")
    }

    static func dateString(from date: Date) -> String {
        iso8601DateFormatter.string(from: date)
    }

    /// Cached POSIX date formatter for YYYY-MM-DD strings.
    static let iso8601DateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Errors

    enum APIError: LocalizedError {
        case notFound
        case httpError(Int)

        var errorDescription: String? {
            switch self {
            case .notFound:    return "Today's artwork hasn't been generated yet."
            case .httpError(let code): return "Server error (\(code))."
            }
        }
    }

    // MARK: - Fetch

    func fetchMetadata(for date: Date = Date()) async throws -> ArtworkMetadata {
        let (data, response) = try await session.data(from: Self.metadataURL(for: date))
        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200...299: break
            case 404:       throw APIError.notFound
            default:        throw APIError.httpError(http.statusCode)
            }
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ArtworkMetadata.self, from: data)
    }

    /// Prefetch the image into the shared URLCache so AsyncImage serves it from cache.
    func prefetchImage(for date: Date) async {
        let url = Self.imageURL(for: date)
        let request = URLRequest(url: url)

        // Skip if already cached
        if URLCache.shared.cachedResponse(for: request) != nil { return }

        // Fire the request; response is stored in URLCache.shared automatically
        _ = try? await session.data(for: request)
    }
}
