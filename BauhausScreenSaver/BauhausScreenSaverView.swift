import ScreenSaver
import AppKit

final class BauhausScreenSaverView: ScreenSaverView {

    private let imageView: NSImageView = {
        let v = NSImageView()
        v.imageScaling = .scaleProportionallyUpOrDown
        v.imageAlignment = .alignCenter
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var lastLoadedDate: String?
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 50 * 1024 * 1024,
            diskPath: "bauhaus-screensaver"
        )
        config.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: config)
    }()

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        animationTimeInterval = 60.0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func startAnimation() {
        super.startAnimation()
        loadTodayImage()
    }

    override func animateOneFrame() {
        // Refresh once per day at most
        let today = BauhausAPI.dateString(from: Date())
        if lastLoadedDate != today {
            loadTodayImage()
        }
    }

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }

    // MARK: - Private

    private func loadTodayImage() {
        lastLoadedDate = BauhausAPI.dateString(from: Date())
        let url = BauhausAPI.imageURL(for: Date())
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        session.dataTask(with: request) { [weak self] data, _, _ in
            guard let self, let data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }.resume()
    }
}
