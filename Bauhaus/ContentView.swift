import SwiftUI

struct ContentView: View {
    @State private var viewModel: ArtworkViewModel
    @State private var showMetadata = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: ArtworkViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    init() {
        self.init(viewModel: ArtworkViewModel())
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
                .accessibilityAddTraits(.isImage)

            // Bottom gradient scrim for metadata legibility
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.6), location: 0.6),
                        .init(color: .black.opacity(0.8), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 360)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
            .opacity(showMetadata && viewModel.metadata != nil ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: showMetadata)

            // Past-date indicator (top-leading, safe-area aware)
            if !Calendar.current.isDateInToday(viewModel.currentDate) {
                Text(viewModel.currentDate, style: .date)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .accessibilityLabel("Viewing \(viewModel.currentDate.formatted(date: .long, time: .omitted))")
            }

            // Loading indicator during navigation
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }

            // Metadata overlay
            if showMetadata, let metadata = viewModel.metadata {
                VStack(alignment: .leading, spacing: 12) {
                    Text(metadata.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text("\(metadata.styleArtist) · \(metadata.formattedDate)")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 80)
                .padding(.top, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                .accessibilityHidden(true)
            }

            // Error overlay
            if let errorMessage = viewModel.error, viewModel.metadata == nil, !viewModel.isLoading {
                ErrorOverlay(message: errorMessage, isNotYetGenerated: viewModel.isNotYetGenerated) {
                    Task { await viewModel.load() }
                }
            }
        }
        // Play/Pause: toggle metadata overlay
        .onPlayPauseCommand {
            withAnimation(.easeInOut(duration: 0.25)) {
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
            case .left:  withAnimation(.snappy) { viewModel.goToPreviousDay() }
            case .right: withAnimation(.snappy) { viewModel.goToNextDay() }
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
            return "Artwork: \(metadata.title) styled after \(metadata.styleArtist), \(metadata.formattedDate)"
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

        return BauhausAPI.iso8601DateFormatter.date(from: dateStr)
    }
}

// MARK: - Error overlay

private struct ErrorOverlay: View {
    let message: String
    let isNotYetGenerated: Bool
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: isNotYetGenerated ? "clock" : "exclamationmark.triangle")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text(isNotYetGenerated ? "Not ready yet" : "Couldn't load artwork")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(isNotYetGenerated
                     ? "Today's artwork is still being generated.\nCheck back after 4 AM UTC."
                     : message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 120)

                Button("Retry", action: onRetry)
                    .buttonStyle(.bordered)
            }
            .padding(60)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .accessibilityElement(children: .contain)
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

#Preview("Not yet generated") {
    let vm = ArtworkViewModel()
    vm.isNotYetGenerated = true
    vm.error = BauhausAPI.APIError.notFound.errorDescription
    return ContentView(viewModel: vm)
}

#Preview("Today (live)") {
    ContentView()
}
