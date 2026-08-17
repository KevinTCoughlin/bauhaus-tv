import SwiftUI

@main
struct BauhausIOSApp: App {
    init() {
        BauhausAPI.configureSharedCache()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
