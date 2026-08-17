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
    private var imageTask: URLSessionDataTask?
    private var activeRequestID: UUID?
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
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    override func startAnimation() {
        super.startAnimation()
        loadTodayImage()
    }

    override func stopAnimation() {
        imageTask?.cancel()
        imageTask = nil
        activeRequestID = nil
        super.stopAnimation()
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

    private func configureView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        guard imageView.superview == nil else { return }
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        animationTimeInterval = 60.0
    }

    private func loadTodayImage() {
        guard imageTask == nil else { return }
        let date = Date()
        let requestedDate = BauhausAPI.dateString(from: date)
        let requestID = UUID()
        activeRequestID = requestID
        let request = BauhausAPI.imageRequest(for: date)
        imageTask = session.dataTask(with: request) { [weak self] data, response, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                guard self.activeRequestID == requestID else { return }
                self.imageTask = nil
                self.activeRequestID = nil
                guard self.isAnimating else { return }
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode),
                      let data,
                      let image = NSImage(data: data)
                else { return }
                self.lastLoadedDate = requestedDate
                self.imageView.image = image
            }
        }
        imageTask?.resume()
    }
}
