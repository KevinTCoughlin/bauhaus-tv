import Foundation

struct ArtworkMetadata: Codable {
    let title: String
    let artist: String
    let date: String
    let styleTitle: String
    let styleArtist: String

    var formattedDate: String {
        guard let d = Self.inputFormatter.date(from: date) else { return date }
        return Self.outputFormatter.string(from: d)
    }

    private static let inputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let outputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
}
