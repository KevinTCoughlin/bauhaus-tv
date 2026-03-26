import Foundation
import Observation

@Observable
final class ArtworkViewModel {
    var metadata: ArtworkMetadata?
    var isLoading = false
    var error: String?
    var currentDate: Date = Date()

    private let api = BauhausAPI.shared
    private let defaults = UserDefaults.standard
    private let lastUpdatedKey = "lastUpdatedDate"

    var imageURL: URL { BauhausAPI.imageURL(for: currentDate) }

    var canGoForward: Bool {
        !Calendar.current.isDateInToday(currentDate)
    }

    // MARK: - History navigation

    func goToPreviousDay() {
        guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { return }
        currentDate = prev
        metadata = nil
        Task { await load() }
    }

    func goToNextDay() {
        guard canGoForward,
              let next = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else { return }
        currentDate = next
        metadata = nil
        Task { await load() }
    }

    // MARK: - Load

    func load() async {
        // Application-level skip for today only; past dates rely on URLCache's immutable CDN cache
        if Calendar.current.isDateInToday(currentDate) {
            let today = BauhausAPI.dateString(from: Date())
            if let last = defaults.string(forKey: lastUpdatedKey), last == today, metadata != nil {
                return
            }
        }

        isLoading = true
        error = nil

        do {
            metadata = try await api.fetchMetadata(for: currentDate)
            if Calendar.current.isDateInToday(currentDate) {
                defaults.set(BauhausAPI.dateString(from: Date()), forKey: lastUpdatedKey)
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
