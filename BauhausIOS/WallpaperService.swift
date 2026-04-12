#if targetEnvironment(macCatalyst)
import Foundation
import Darwin

final class WallpaperService {
    static let shared = WallpaperService()
    private init() {}

    enum WallpaperError: LocalizedError {
        case scriptFailed(Int32)

        var errorDescription: String? {
            switch self {
            case .scriptFailed(let code): return "Failed to set wallpaper (exit \(code))."
            }
        }
    }

    /// Downloads the image at `url` and sets it as the desktop wallpaper on all screens.
    func setWallpaper(from url: URL) async throws {
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("bauhaus-wallpaper.jpg")

        // Use the shared cache — the image is likely already cached by AsyncImage
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let (data, _) = try await URLSession.shared.data(for: request)

        try data.write(to: dest, options: .atomic)

        // Use POSIX file coercion so no path escaping is needed.
        // dest.path is fully app-controlled (tmp dir + hardcoded filename).
        let script = "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"\(dest.path)\""

        var pid: pid_t = 0
        let args: [String] = ["/usr/bin/osascript", "-e", script]
        var cArgs = args.map { strdup($0) }
        cArgs.append(nil)
        defer { cArgs.compactMap { $0 }.forEach { free($0) } }

        let status = posix_spawn(&pid, "/usr/bin/osascript", nil, nil, &cArgs, nil)

        guard status == 0 else {
            throw WallpaperError.scriptFailed(status)
        }

        var exitStatus: Int32 = 0
        waitpid(pid, &exitStatus, 0)

        let exitCode = (exitStatus >> 8) & 0xff
        guard exitCode == 0 else {
            throw WallpaperError.scriptFailed(exitCode)
        }
    }
}
#endif
