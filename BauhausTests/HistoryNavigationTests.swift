import XCTest
@testable import Bauhaus

@MainActor
final class HistoryNavigationTests: XCTestCase {

    private var viewModel: ArtworkViewModel!

    override func setUp() {
        super.setUp()
        viewModel = ArtworkViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testStartsOnToday() {
        XCTAssertTrue(Calendar.current.isDateInToday(viewModel.currentDate))
    }

    func testCannotGoForwardFromToday() {
        XCTAssertFalse(viewModel.canGoForward)
    }

    func testGoToPreviousDayMovesBackOne() {
        let before = viewModel.currentDate
        viewModel.goToPreviousDay()
        let diff = Calendar.current.dateComponents([.day], from: viewModel.currentDate, to: before).day
        XCTAssertEqual(diff, 1)
    }

    func testCanGoForwardAfterGoingBack() {
        viewModel.goToPreviousDay()
        XCTAssertTrue(viewModel.canGoForward)
    }

    func testGoNextDayFromYesterdayReturnsToToday() {
        viewModel.goToPreviousDay()
        viewModel.goToNextDay()
        XCTAssertTrue(Calendar.current.isDateInToday(viewModel.currentDate))
    }

    func testGoNextDayFromTodayIsNoop() {
        let before = viewModel.currentDate
        viewModel.goToNextDay() // Should be a no-op
        XCTAssertEqual(
            Calendar.current.startOfDay(for: viewModel.currentDate),
            Calendar.current.startOfDay(for: before)
        )
    }

    func testNavigatingClearsMetadata() {
        viewModel.goToPreviousDay()
        XCTAssertNil(viewModel.metadata)
    }

    func testImageURLChangesWithDate() {
        let todayURL = viewModel.imageURL
        viewModel.goToPreviousDay()
        XCTAssertNotEqual(viewModel.imageURL, todayURL)
    }
}
