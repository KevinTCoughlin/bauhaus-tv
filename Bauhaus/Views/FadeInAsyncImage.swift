import SwiftUI

/// AsyncImage wrapper that fades the image in once loaded.
/// Use `.id(url)` at the call site to reset the fade when the URL changes.
struct FadeInAsyncImage: View {
    let url: URL
    @State private var opacity: Double = 0

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2)) {
                            opacity = 1
                        }
                    }
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
    }
}

#Preview("Loading") {
    FadeInAsyncImage(url: URL(string: "https://bauhaus.cascadiacollections.workers.dev/api/today?format=jpeg")!)
        .ignoresSafeArea()
}
