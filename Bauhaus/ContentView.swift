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
                .accessibilityHidden(false)

            // Bottom gradient scrim (always visible)
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
        }
        // Play/Pause toggles metadata overlay
        .onPlayPauseCommand {
            withAnimation(.easeInOut(duration: 0.3)) {
                showMetadata.toggle()
            }
        }
        // D-pad left/right navigates history
        .focusable()
        .onMoveCommand { direction in
            switch direction {
            case .left:
                withAnimation { viewModel.goToPreviousDay() }
            case .right:
                withAnimation { viewModel.goToNextDay() }
            default:
                break
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var accessibilityImageLabel: String {
        if let metadata = viewModel.metadata {
            return "Artwork: \(metadata.title) styled after \(metadata.styleArtist)"
        }
        return Calendar.current.isDateInToday(viewModel.currentDate)
            ? "Today's daily artwork, loading"
            : "Artwork for \(viewModel.currentDate.formatted(date: .abbreviated, time: .omitted)), loading"
    }
}

#Preview("Today") {
    ContentView()
}
