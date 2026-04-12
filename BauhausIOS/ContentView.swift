import SwiftUI
import Photos

struct ContentView: View {
    @State private var viewModel: ArtworkViewModel
    @State private var wallpaperToast: WallpaperToastState?

    private enum WallpaperToastState: Equatable {
        case success, saveSuccess, failure(String)

        var message: String {
            switch self {
            case .success:           return "Wallpaper set!"
            case .saveSuccess:       return "Saved to Photos!"
            case .failure(let msg):  return "Failed: \(msg)"
            }
        }

        var isError: Bool {
            if case .failure = self { return true }
            return false
        }
    }

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

            // Past-date indicator (top-leading, safe-area aware)
            if !Calendar.current.isDateInToday(viewModel.currentDate) {
                Text(viewModel.currentDate, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding()
                    .accessibilityLabel("Viewing \(viewModel.currentDate.formatted(date: .long, time: .omitted))")
            }

            // Loading indicator during navigation
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }

            // Metadata: accessible via VoiceOver only, no visible text
            if let metadata = viewModel.metadata {
                Color.clear
                    .accessibilityLabel("Artwork: \(metadata.title) styled after \(metadata.styleArtist), \(metadata.formattedDate)")
                    .accessibilityAddTraits(.isStaticText)
            }

            // Error overlay
            if let errorMessage = viewModel.error, viewModel.metadata == nil, !viewModel.isLoading {
                ErrorOverlay(message: errorMessage, isNotYetGenerated: viewModel.isNotYetGenerated) {
                    Task { await viewModel.load() }
                }
            }

            // Wallpaper toast
            if let toast = wallpaperToast {
                toastView(toast)
            }
        }
        // Swipe left/right: navigate history (touch)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    let dx = value.translation.width
                    if dx < -50 {
                        withAnimation(.snappy) { viewModel.goToPreviousDay() }
                    } else if dx > 50 {
                        guard viewModel.canGoForward else { return }
                        withAnimation(.snappy) { viewModel.goToNextDay() }
                    }
                }
        )
        // Arrow keys: navigate history (Mac keyboard/trackpad)
        .focusable()
        .onKeyPress(.leftArrow) {
            withAnimation(.snappy) { viewModel.goToPreviousDay() }
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard viewModel.canGoForward else { return .ignored }
            withAnimation(.snappy) { viewModel.goToNextDay() }
            return .handled
        }
        // Deep link: bauhaus://open?date=YYYY-MM-DD or bauhaus-ios://open?date=YYYY-MM-DD
        .onOpenURL { url in
            guard let date = date(from: url) else { return }
            withAnimation { viewModel.navigateTo(date: date) }
        }
        // Long press: set as macOS wallpaper
        #if targetEnvironment(macCatalyst)
        .onLongPressGesture(minimumDuration: 0.6) {
            Task { await setWallpaper() }
        }
        .contextMenu {
            Button {
                Task { await setWallpaper() }
            } label: {
                Label("Set as Wallpaper", systemImage: "photo.on.rectangle.angled")
            }
        }
        #else
        .contextMenu {
            Button {
                Task { await saveToPhotos() }
            } label: {
                Label("Save to Photos", systemImage: "square.and.arrow.down")
            }
        }
        #endif
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func toastView(_ toast: WallpaperToastState) -> some View {
        HStack(spacing: 8) {
            Image(systemName: toast.isError ? "exclamationmark.circle" : "checkmark.circle.fill")
            Text(toast.message)
                .fontWeight(.medium)
        }
        .font(.subheadline)
        .foregroundStyle(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .allowsHitTesting(false)
        .accessibilityLabel(toast.message)
        .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Helpers

    #if targetEnvironment(macCatalyst)
    @MainActor
    private func setWallpaper() async {
        let url = viewModel.imageURL
        do {
            try await WallpaperService.shared.setWallpaper(from: url)
            withAnimation(.snappy) { wallpaperToast = .success }
        } catch {
            withAnimation(.snappy) { wallpaperToast = .failure(error.localizedDescription) }
        }
        try? await Task.sleep(for: .seconds(2.5))
        withAnimation(.easeOut) { wallpaperToast = nil }
    }
    #else
    @MainActor
    private func saveToPhotos() async {
        let url = viewModel.imageURL
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                withAnimation(.snappy) { wallpaperToast = .failure("Couldn't decode image.") }
                return
            }
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            withAnimation(.snappy) { wallpaperToast = .saveSuccess }
        } catch {
            withAnimation(.snappy) { wallpaperToast = .failure(error.localizedDescription) }
        }
        try? await Task.sleep(for: .seconds(2.5))
        withAnimation(.easeOut) { wallpaperToast = nil }
    }
    #endif

    private var accessibilityImageLabel: String {
        if let metadata = viewModel.metadata {
            return "Artwork: \(metadata.title) styled after \(metadata.styleArtist), \(metadata.formattedDate)"
        }
        return Calendar.current.isDateInToday(viewModel.currentDate)
            ? "Today's daily artwork, loading"
            : "Artwork for \(viewModel.currentDate.formatted(date: .abbreviated, time: .omitted)), loading"
    }

    /// Parses `bauhaus://open?date=YYYY-MM-DD` or `bauhaus-ios://open?date=YYYY-MM-DD` → Date
    private func date(from url: URL) -> Date? {
        guard url.scheme == "bauhaus" || url.scheme == "bauhaus-ios",
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
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: isNotYetGenerated ? "clock" : "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text(isNotYetGenerated ? "Not ready yet" : "Couldn't load artwork")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(isNotYetGenerated
                     ? "Today's artwork is still being generated.\nCheck back after 4 AM UTC."
                     : message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)

                Button("Retry", action: onRetry)
                    .buttonStyle(.bordered)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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

#Preview("Today (live)") {
    ContentView()
}
