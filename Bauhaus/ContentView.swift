import SwiftUI

struct ContentView: View {
    @State private var viewModel = ArtworkViewModel()
    @State private var showMetadata = true

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Full-screen artwork
            AsyncImage(url: viewModel.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Color.black
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.white.opacity(0.3))
                                .font(.system(size: 100))
                        )
                case .empty:
                    Color.black
                        .overlay(ProgressView().tint(.white))
                @unknown default:
                    Color.black
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()

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
            }
        }
        .onPlayPauseCommand {
            withAnimation(.easeInOut(duration: 0.3)) {
                showMetadata.toggle()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
