import SwiftUI
import BackgroundTasks

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

    let fetch = Task {
        _ = try? await BauhausAPI.shared.fetchMetadata()
        task.setTaskCompleted(success: true)
    }

    task.expirationHandler = {
        fetch.cancel()
        task.setTaskCompleted(success: false)
    }
}

private func scheduleRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
    // Aim for ~6 hours from now; system will honour when resources allow
    request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600)
    try? BGTaskScheduler.shared.submit(request)
}
