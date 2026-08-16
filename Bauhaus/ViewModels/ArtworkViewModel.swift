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

    private let api: any BauhausAPIProtocol
    private var loadTask: Task<Void, Never>?
    private var activeLoadID: UUID?

    init(api: any BauhausAPIProtocol = BauhausAPI.shared) {
        self.api = api
    }

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

        let loadID = UUID()
        activeLoadID = loadID
        isLoading = true
        error = nil
        isNotYetGenerated = false
        defer {
            if activeLoadID == loadID {
                isLoading = false
            }
        }

        do {
            async let meta = api.fetchMetadata(for: requestedDate)
            async let _ = api.prefetchImage(for: requestedDate)
            let result = try await meta
            guard isActive(loadID, for: requestedDate) else { return }
            metadata = result
            handleSuccessfulLoad(result: result, requestedDate: requestedDate)
        } catch BauhausAPI.APIError.notFound {
            guard isActive(loadID, for: requestedDate) else { return }
            isNotYetGenerated = Calendar.current.isDateInToday(requestedDate)
            error = BauhausAPI.APIError.notFound.errorDescription
        } catch {
            guard isActive(loadID, for: requestedDate) else { return }
            self.error = error.localizedDescription
        }

        guard isActive(loadID, for: requestedDate) else { return }
        isLoading = false
        if isInitialLoad(requestedDate: requestedDate) {
            await prefetchHistory()
        }
    }

    private func shouldFetch(for requestedDate: Date) -> Bool {
        let isLatest = latestArtworkDate.map { Calendar.current.isDate(requestedDate, inSameDayAs: $0) } ?? false
        let isCurrentOrLatest = Calendar.current.isDateInToday(requestedDate) || isLatest
        return !isCurrentOrLatest || metadata == nil
    }

    private func isActive(_ loadID: UUID, for requestedDate: Date) -> Bool {
        !Task.isCancelled && activeLoadID == loadID && currentDate == requestedDate
    }

    private func handleSuccessfulLoad(result: ArtworkMetadata, requestedDate: Date) {
        let isFirstLoad = Calendar.current.isDateInToday(requestedDate) || latestArtworkDate == nil
        guard isFirstLoad, let artDate = BauhausAPI.iso8601DateFormatter.date(from: result.date) else { return }

        latestArtworkDate = artDate
    }

    private func isInitialLoad(requestedDate: Date) -> Bool {
        let isLatest = latestArtworkDate.map { Calendar.current.isDate(requestedDate, inSameDayAs: $0) } ?? false
        return isLatest || Calendar.current.isDateInToday(requestedDate)
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
