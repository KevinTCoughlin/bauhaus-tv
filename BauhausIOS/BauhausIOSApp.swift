import SwiftUI

@main
struct BauhausIOSApp: App {
    init() {
        URLCache.shared = URLCache(
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 50 * 1024 * 1024,
            diskPath: "bauhaus"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
