import Foundation
import Observation

@MainActor
@Observable
final class ArtworkViewModel {
    var metadata: ArtworkMetadata?
    var isLoading = false
    var error: String?
    var isNotYetGenerated = false
    var currentDate: Date = Date()

    /// The date of the latest available artwork (from /api/today.json).
    /// Used as the anchor for history navigation so we only browse dates with actual content.
    private var latestArtworkDate: Date?

    private let api = BauhausAPI.shared
    private let defaults = UserDefaults.standard
    private let lastUpdatedKey = "lastUpdatedDate"
    private var loadTask: Task<Void, Never>?

    var imageURL: URL { BauhausAPI.imageURL(for: currentDate) }

    var canGoForward: Bool {
        let cal = Calendar.current
        if let latest = latestArtworkDate {
            // Can't go forward past the latest artwork
            return cal.startOfDay(for: currentDate) < cal.startOfDay(for: latest)
        }
        return !cal.isDateInToday(currentDate)
    }

    var canGoBack: Bool {
        let cal = Calendar.current
        let anchor = latestArtworkDate ?? Date()
        guard let earliest = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: anchor)) else { return false }
        return cal.startOfDay(for: currentDate) > earliest
    }

    // MARK: - Navigation

    func goToPreviousDay() {
        guard canGoBack,
              let prev = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { return }
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
        loadTask?.cancel()
        currentDate = date
        metadata = nil
        error = nil
        isNotYetGenerated = false
        loadTask = Task { await load() }
    }

    // MARK: - Load

    func load() async {
        let requestedDate = currentDate

        guard shouldFetch(for: requestedDate) else { return }

        isLoading = true
        error = nil
        isNotYetGenerated = false

        do {
            async let meta = api.fetchMetadata(for: requestedDate)
            async let _ = api.prefetchImage(for: requestedDate)
            let result = try await meta
            guard !Task.isCancelled, currentDate == requestedDate else { return }
            metadata = result
            handleSuccessfulLoad(result: result, requestedDate: requestedDate)
        } catch BauhausAPI.APIError.notFound {
            guard !Task.isCancelled, currentDate == requestedDate else { return }
            isNotYetGenerated = true
            error = BauhausAPI.APIError.notFound.errorDescription
        } catch {
            guard !Task.isCancelled, currentDate == requestedDate else { return }
            self.error = error.localizedDescription
        }

        isLoading = false

        if isInitialLoad(requestedDate: requestedDate) {
            await prefetchHistory()
        }
    }

    private func shouldFetch(for requestedDate: Date) -> Bool {
        let isCurrentOrLatest = Calendar.current.isDateInToday(requestedDate) || requestedDate == latestArtworkDate
        guard isCurrentOrLatest else { return true }
        let today = BauhausAPI.dateString(from: Date())
        if let last = defaults.string(forKey: lastUpdatedKey), last == today, metadata != nil {
            return false
        }
        return true
    }

    private func handleSuccessfulLoad(result: ArtworkMetadata, requestedDate: Date) {
        let isFirstLoad = Calendar.current.isDateInToday(requestedDate) || latestArtworkDate == nil
        guard isFirstLoad, let artDate = BauhausAPI.iso8601DateFormatter.date(from: result.date) else { return }

        latestArtworkDate = artDate
        defaults.set(BauhausAPI.dateString(from: Date()), forKey: lastUpdatedKey)
    }

    private func isInitialLoad(requestedDate: Date) -> Bool {
        requestedDate == latestArtworkDate || Calendar.current.isDateInToday(requestedDate)
    }

    /// Prefetch metadata + images for the past 6 days so swipe navigation is instant.
    private func prefetchHistory() async {
        let anchor = latestArtworkDate ?? Date()
        let cal = Calendar.current
        await withTaskGroup(of: Void.self) { group in
            for offset in 1...6 {
                guard let date = cal.date(byAdding: .day, value: -offset, to: anchor) else { continue }
                group.addTask { [api] in
                    async let _ = try? api.fetchMetadata(for: date)
                    async let _ = api.prefetchImage(for: date)
                }
            }
        }
    }
}
