import XCTest
@testable import Bauhaus

final class BauhausAPITests: XCTestCase {

    func testTodayImageURL() {
        let url = BauhausAPI.imageURL(for: Date())
        XCTAssertEqual(
            url.absoluteString,
            "https://bauhaus.cascadiacollections.workers.dev/api/today?format=jpeg"
        )
    }

    func testTodayMetadataURL() {
        let url = BauhausAPI.metadataURL(for: Date())
        XCTAssertEqual(
            url.absoluteString,
            "https://bauhaus.cascadiacollections.workers.dev/api/today.json"
        )
    }

    func testPastDateImageURL() {
        let date = date(year: 2026, month: 3, day: 20)
        let url = BauhausAPI.imageURL(for: date)
        XCTAssertEqual(
            url.absoluteString,
            "https://bauhaus.cascadiacollections.workers.dev/api/2026-03-20?format=jpeg"
        )
    }

    func testPastDateMetadataURL() {
        let date = date(year: 2026, month: 3, day: 1)
        let url = BauhausAPI.metadataURL(for: date)
        XCTAssertEqual(
            url.absoluteString,
            "https://bauhaus.cascadiacollections.workers.dev/api/2026-03-01.json"
        )
    }

    func testDateStringFormat() {
        let date = date(year: 2026, month: 1, day: 5)
        XCTAssertEqual(BauhausAPI.dateString(from: date), "2026-01-05")
    }

    func testTodayImageUsesProtocolCachePolicy() {
        let request = BauhausAPI.imageRequest(for: Date())
        XCTAssertEqual(request.cachePolicy, .useProtocolCachePolicy)
    }

    func testPastImageUsesCachedDataElseLoad() {
        let request = BauhausAPI.imageRequest(for: date(year: 2026, month: 3, day: 20))
        XCTAssertEqual(request.cachePolicy, .returnCacheDataElseLoad)
    }

    func testUnknownImageURLUsesProtocolCachePolicy() {
        let url = URL(string: "https://example.com/api/2026-03-20?format=jpeg")!
        XCTAssertEqual(BauhausAPI.imageCachePolicy(for: url), .useProtocolCachePolicy)
    }

    // MARK: - Helpers

    private func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12 // Midday to avoid any timezone edge cases
        return Calendar.current.date(from: components)!
    }
}
