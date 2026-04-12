import SwiftUI

/// AsyncImage wrapper that fades the image in once loaded.
/// Use `.id(url)` at the call site to reset the fade when the URL changes.
struct FadeInAsyncImage: View {
    let url: URL
    @State private var opacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .opacity(opacity)
                    .onAppear {
                        if reduceMotion {
                            opacity = 1
                        } else {
                            withAnimation(.easeIn(duration: 0.4)) {
                                opacity = 1
                            }
                        }
                    }
            case .failure:
                Color.black
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.tertiary)
                            Text("Unable to load image")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
            case .empty:
                Color.black
                    .overlay {
                        ProgressView()
                            .tint(.white.opacity(0.6))
                            .accessibilityLabel("Loading artwork")
                    }
            @unknown default:
                Color.black
            }
        }
    }
}

#Preview("Loading") {
    FadeInAsyncImage(url: URL(string: "https://bauhaus.cascadiacollections.workers.dev/api/today?format=jpeg")!)
        .ignoresSafeArea()
}
