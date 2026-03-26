import Foundation

struct ArtworkMetadata: Codable {
    let title: String
    let artist: String
    let date: String
    let styleTitle: String
    let styleArtist: String

    var formattedDate: String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        guard let d = input.date(from: date) else { return date }
        let output = DateFormatter()
        output.dateFormat = "MMM d"
        return output.string(from: d)
    }
}
