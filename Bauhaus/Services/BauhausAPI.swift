import Foundation

protocol BauhausAPIProtocol {
    func fetchMetadata(for date: Date) async throws -> ArtworkMetadata
    func prefetchImage(for date: Date) async
}

final class BauhausAPI: BauhausAPIProtocol {
    static let shared = BauhausAPI()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache.shared
        config.requestCachePolicy = .useProtocolCachePolicy
        session = URLSession(configuration: config)
    }

    static func configureSharedCache() {
        URLCache.shared = URLCache(
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 50 * 1024 * 1024,
            diskPath: "bauhaus"
        )
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
        case invalidResponse
        case httpError(Int)

        var errorDescription: String? {
            switch self {
            case .notFound: return "Artwork isn't available for this date."
            case .invalidResponse: return "The server returned an invalid response."
            case .httpError(let code): return "Server error (\(code))."
            }
        }
    }

    // MARK: - Fetch

    func fetchMetadata(for date: Date = Date()) async throws -> ArtworkMetadata {
        let (data, response) = try await session.data(from: Self.metadataURL(for: date))
        try validate(response)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ArtworkMetadata.self, from: data)
    }

    func fetchImageData(for date: Date) async throws -> Data {
        try await fetchImageData(using: Self.imageRequest(for: date))
    }

    func fetchImageData(from url: URL) async throws -> Data {
        try await fetchImageData(using: Self.imageRequest(for: url))
    }

    static func imageRequest(for date: Date) -> URLRequest {
        imageRequest(for: imageURL(for: date))
    }

    static func imageRequest(for url: URL) -> URLRequest {
        URLRequest(url: url, cachePolicy: imageCachePolicy(for: url))
    }

    static func imageCachePolicy(for url: URL) -> URLRequest.CachePolicy {
        let components = url.pathComponents.filter { $0 != "/" }
        guard url.scheme == baseURL.scheme,
              url.host == baseURL.host,
              components.count == 2,
              components[0] == "api",
              let date = iso8601DateFormatter.date(from: components[1]),
              dateString(from: date) == components[1]
        else {
            return .useProtocolCachePolicy
        }
        return .returnCacheDataElseLoad
    }

    private func fetchImageData(using request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        try validate(response)
        return data
    }

    /// Prefetch the image into the shared URLCache so AsyncImage serves it from cache.
    func prefetchImage(for date: Date) async {
        let request = Self.imageRequest(for: date)

        if request.cachePolicy == .returnCacheDataElseLoad,
           URLCache.shared.cachedResponse(for: request) != nil {
            return
        }

        _ = try? await fetchImageData(using: request)
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        switch http.statusCode {
        case 200...299: return
        case 404: throw APIError.notFound
        default: throw APIError.httpError(http.statusCode)
        }
    }
}
