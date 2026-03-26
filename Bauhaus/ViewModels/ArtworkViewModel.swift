import Foundation
import Observation

@Observable
final class ArtworkViewModel {
    var metadata: ArtworkMetadata?
    var isLoading = false
    var error: String?

    private let api = BauhausAPI.shared
    private let defaults = UserDefaults.standard
    private let lastUpdatedKey = "lastUpdatedDate"

    var imageURL: URL { BauhausAPI.imageURL }

    func load() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        // Skip if metadata already loaded today
        if let last = defaults.string(forKey: lastUpdatedKey), last == today, metadata != nil {
            return
        }

        isLoading = true
        error = nil

        do {
            metadata = try await api.fetchMetadata()
            defaults.set(today, forKey: lastUpdatedKey)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
