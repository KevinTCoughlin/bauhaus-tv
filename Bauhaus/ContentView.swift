import SwiftUI

struct ContentView: View {
    @State private var viewModel = ArtworkViewModel()
    @State private var showMetadata = true

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Full-screen artwork with crossfade on URL change
            FadeInAsyncImage(url: viewModel.imageURL)
                .id(viewModel.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .accessibilityLabel(accessibilityImageLabel)

            // Bottom gradient scrim
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 400)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)

            // Past-date indicator (top-left when browsing history)
            if !Calendar.current.isDateInToday(viewModel.currentDate) {
                VStack {
                    HStack {
                        Text(viewModel.currentDate, style: .date)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.55))
                            .padding(.horizontal, 80)
                            .padding(.top, 60)
                        Spacer()
                    }
                    Spacer()
                }
            }

            // Metadata overlay
            if showMetadata, let metadata = viewModel.metadata {
                VStack(alignment: .leading, spacing: 16) {
                    Text(metadata.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("\(metadata.styleArtist) · \(metadata.formattedDate)")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(80)
                .transition(.opacity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(metadata.title), styled after \(metadata.styleArtist), \(metadata.formattedDate)")
            }

            // Error overlay
            if let errorMessage = viewModel.error, viewModel.metadata == nil, !viewModel.isLoading {
                ErrorOverlay(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            }
        }
        // Play/Pause: toggle metadata overlay
        .onPlayPauseCommand {
            withAnimation(.easeInOut(duration: 0.3)) {
                showMetadata.toggle()
            }
        }
        // Select (click): return to today when browsing history
        .onTapGesture {
            guard viewModel.canGoForward else { return }
            withAnimation { viewModel.returnToToday() }
        }
        // D-pad: navigate history
        .focusable()
        .onMoveCommand { direction in
            switch direction {
            case .left:  withAnimation { viewModel.goToPreviousDay() }
            case .right: withAnimation { viewModel.goToNextDay() }
            default: break
            }
        }
        // Deep link from Top Shelf: bauhaus://open?date=YYYY-MM-DD
        .onOpenURL { url in
            guard let date = date(from: url) else { return }
            withAnimation { viewModel.navigateTo(date: date) }
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Helpers

    private var accessibilityImageLabel: String {
        if let metadata = viewModel.metadata {
            return "Artwork: \(metadata.title) styled after \(metadata.styleArtist)"
        }
        return Calendar.current.isDateInToday(viewModel.currentDate)
            ? "Today's daily artwork, loading"
            : "Artwork for \(viewModel.currentDate.formatted(date: .abbreviated, time: .omitted)), loading"
    }

    /// Parses `bauhaus://open?date=YYYY-MM-DD` → Date
    private func date(from url: URL) -> Date? {
        guard url.scheme == "bauhaus",
              url.host == "open",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let dateStr = components.queryItems?.first(where: { $0.name == "date" })?.value
        else { return nil }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: dateStr)
    }
}

// MARK: - Error overlay

private struct ErrorOverlay: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.6))

                Text("Couldn't load artwork")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 120)

                Button("Retry", action: onRetry)
                    .buttonStyle(.bordered)
                    .tint(.white)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message). Retry button available.")
    }
}

#Preview("Today") {
    ContentView()
}
