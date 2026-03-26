import AppIntents

struct ShowTodayArtworkIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Today's Artwork"
    static var description = IntentDescription("Opens Bauhaus to today's daily artwork.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct BauhausShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowTodayArtworkIntent(),
            phrases: [
                "Show today's \(.applicationName)",
                "Open \(.applicationName)",
                "Show \(.applicationName) artwork"
            ],
            shortTitle: "Today's Artwork",
            systemImageName: "photo.artframe"
        )
    }
}
