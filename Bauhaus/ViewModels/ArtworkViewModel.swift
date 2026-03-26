import Foundation
import Observation

@Observable
final class ArtworkViewModel {
    var metadata: ArtworkMetadata?
    var isLoading = false
    var error: String?
    var isNotYetGenerated = false
    var currentDate: Date = Date()

    private let api = BauhausAPI.shared
    private let defaults = UserDefaults.standard
    private let lastUpdatedKey = "lastUpdatedDate"

    var imageURL: URL { BauhausAPI.imageURL(for: currentDate) }

    var canGoForward: Bool {
        !Calendar.current.isDateInToday(currentDate)
    }

    // MARK: - Navigation

    func goToPreviousDay() {
        guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { return }
        navigateTo(date: prev)
    }

    func goToNextDay() {
        guard canGoForward,
              let next = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else { return }
        navigateTo(date: next)
    }

    func returnToToday() {
        navigateTo(date: Date())
    }

    func navigateTo(date: Date) {
        currentDate = date
        metadata = nil
        error = nil
        isNotYetGenerated = false
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
        isNotYetGenerated = false

        do {
            metadata = try await api.fetchMetadata(for: currentDate)
            if Calendar.current.isDateInToday(currentDate) {
                defaults.set(BauhausAPI.dateString(from: Date()), forKey: lastUpdatedKey)
            }
        } catch BauhausAPI.APIError.notFound {
            isNotYetGenerated = true
            error = BauhausAPI.APIError.notFound.errorDescription
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
