import XCTest
@testable import Bauhaus

final class ArtworkMetadataTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private func makeJSON(date: String = "2026-03-25") -> Data {
        Data("""
        {
            "title": "Wheat Field with Crows",
            "artist": "Vincent van Gogh",
            "date": "\(date)",
            "style_title": "The Great Wave",
            "style_artist": "Katsushika Hokusai"
        }
        """.utf8)
    }

    func testDecoding() throws {
        let metadata = try decoder.decode(ArtworkMetadata.self, from: makeJSON())

        XCTAssertEqual(metadata.title, "Wheat Field with Crows")
        XCTAssertEqual(metadata.artist, "Vincent van Gogh")
        XCTAssertEqual(metadata.date, "2026-03-25")
        XCTAssertEqual(metadata.styleTitle, "The Great Wave")
        XCTAssertEqual(metadata.styleArtist, "Katsushika Hokusai")
    }

    func testFormattedDate() throws {
        let metadata = try decoder.decode(ArtworkMetadata.self, from: makeJSON(date: "2026-03-25"))
        XCTAssertEqual(metadata.formattedDate, "Mar 25")
    }

    func testFormattedDateJanuary() throws {
        let metadata = try decoder.decode(ArtworkMetadata.self, from: makeJSON(date: "2026-01-01"))
        XCTAssertEqual(metadata.formattedDate, "Jan 1")
    }

    func testFormattedDateInvalidFallsBack() throws {
        let metadata = try decoder.decode(ArtworkMetadata.self, from: makeJSON(date: "not-a-date"))
        XCTAssertEqual(metadata.formattedDate, "not-a-date")
    }

    func testDecodingFailsWithMissingRequiredField() {
        let json = Data("""
        {
            "title": "Test",
            "artist": "Artist",
            "date": "2026-03-25",
            "style_title": "Style"
        }
        """.utf8)

        XCTAssertThrowsError(try decoder.decode(ArtworkMetadata.self, from: json))
    }
}
