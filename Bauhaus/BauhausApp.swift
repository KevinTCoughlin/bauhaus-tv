import SwiftUI
import BackgroundTasks
import os

private let refreshTaskID = "com.cascadiacollections.bauhaus-tv.refresh"

@main
struct BauhausApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        URLCache.shared = URLCache(
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 50 * 1024 * 1024,
            diskPath: "bauhaus"
        )
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskID, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleBackgroundRefresh(task: refreshTask)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                scheduleRefresh()
            }
        }
    }
}

// MARK: - Background refresh

private func handleBackgroundRefresh(task: BGAppRefreshTask) {
    scheduleRefresh() // Reschedule before doing work

    let completed = OSAllocatedUnfairLock(initialState: false)

    let completeOnce: (Bool) -> Void = { success in
        let alreadyCompleted = completed.withLock { done in
            if done { return true }
            done = true
            return false
        }
        guard !alreadyCompleted else { return }
        task.setTaskCompleted(success: success)
    }

    let fetch = Task {
        do {
            _ = try await BauhausAPI.shared.fetchMetadata()
            completeOnce(true)
        } catch {
            completeOnce(false)
        }
    }

    task.expirationHandler = {
        fetch.cancel()
        completeOnce(false)
    }
}

private func scheduleRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
    // Aim for ~6 hours from now; system will honour when resources allow
    request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600)
    try? BGTaskScheduler.shared.submit(request)
}
