import SwiftUI

struct ContentView: View {
    @State private var viewModel: ArtworkViewModel
    @State private var showMetadata = true

    init(viewModel: ArtworkViewModel = ArtworkViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

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
                .frame(height: 300)
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
                            .padding(.horizontal, 20)
                            .padding(.top, 60)
                        Spacer()
                    }
                    Spacer()
                }
            }

            // Metadata overlay
            if showMetadata, let metadata = viewModel.metadata {
                VStack(alignment: .leading, spacing: 8) {
                    Text(metadata.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("\(metadata.styleArtist) · \(metadata.formattedDate)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(40)
                .transition(.opacity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(metadata.title), styled after \(metadata.styleArtist), \(metadata.formattedDate)")
            }

            // Error overlay
            if let errorMessage = viewModel.error, viewModel.metadata == nil, !viewModel.isLoading {
                ErrorOverlay(message: errorMessage, isNotYetGenerated: viewModel.isNotYetGenerated) {
                    Task { await viewModel.load() }
                }
            }
        }
        // Tap: toggle metadata overlay
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showMetadata.toggle()
            }
        }
        // Swipe left/right: navigate history
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    let dx = value.translation.width
                    if dx < -50 {
                        withAnimation { viewModel.goToPreviousDay() }
                    } else if dx > 50 {
                        guard viewModel.canGoForward else { return }
                        withAnimation { viewModel.goToNextDay() }
                    }
                }
        )
        // Deep link: bauhaus://open?date=YYYY-MM-DD or bauhaus-ios://open?date=YYYY-MM-DD
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

    /// Parses `bauhaus://open?date=YYYY-MM-DD` or `bauhaus-ios://open?date=YYYY-MM-DD` → Date
    private func date(from url: URL) -> Date? {
        guard (url.scheme == "bauhaus" || url.scheme == "bauhaus-ios"),
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
    let isNotYetGenerated: Bool
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: isNotYetGenerated ? "clock" : "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.6))

                Text(isNotYetGenerated ? "Not ready yet" : "Couldn't load artwork")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(isNotYetGenerated
                     ? "Today's artwork is still being generated. Check back after 4 AM UTC."
                     : message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button("Retry", action: onRetry)
                    .buttonStyle(.bordered)
                    .tint(.white)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isNotYetGenerated ? "Not ready yet" : "Error"): \(message). Retry button available.")
    }
}

// MARK: - Previews

#Preview("With metadata") {
    let vm = ArtworkViewModel()
    vm.metadata = ArtworkMetadata(
        title: "The Bedroom",
        artist: "Vincent van Gogh",
        date: "1888-10-16",
        styleTitle: "Suprematism",
        styleArtist: "Kazimir Malevich"
    )
    return ContentView(viewModel: vm)
}

#Preview("Today (live)") {
    ContentView()
}
