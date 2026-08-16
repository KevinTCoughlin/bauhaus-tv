#if targetEnvironment(macCatalyst)
import Foundation
import Darwin
import UIKit

final class WallpaperService {
    static let shared = WallpaperService()
    private init() {}

    enum WallpaperError: LocalizedError {
        case invalidImage
        case scriptFailed(Int32)

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "The downloaded file isn't a valid image."
            case .scriptFailed(let code): return "Failed to set wallpaper (exit \(code))."
            }
        }
    }

    /// Downloads the image at `url` and sets it as the desktop wallpaper on all screens.
    func setWallpaper(from url: URL) async throws {
        // Write to ~/Pictures so the file is accessible outside the sandbox
        let home = NSHomeDirectory()
        let dest = URL(fileURLWithPath: home)
            .appendingPathComponent("Pictures")
            .appendingPathComponent("bauhaus-wallpaper.jpg")

        let data = try await BauhausAPI.shared.fetchImageData(from: url)
        guard UIImage(data: data) != nil else {
            throw WallpaperError.invalidImage
        }

        try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: dest, options: .atomic)

        let script = """
        on run argv
            tell application "System Events" to tell every desktop to set picture to POSIX file (item 1 of argv)
        end run
        """

        var pid: pid_t = 0
        let args: [String] = ["/usr/bin/osascript", "-e", script, dest.path]
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
