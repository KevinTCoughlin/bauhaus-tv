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

    // MARK: - Initial state

    func testStartsOnToday() {
        XCTAssertTrue(Calendar.current.isDateInToday(viewModel.currentDate))
    }

    func testCannotGoForwardFromToday() {
        XCTAssertFalse(viewModel.canGoForward)
    }

    func testCanGoBackFromToday() {
        XCTAssertTrue(viewModel.canGoBack)
    }

    // MARK: - goToPreviousDay

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

    func testNavigatingClearsMetadataAndError() {
        viewModel.goToPreviousDay()
        XCTAssertNil(viewModel.metadata)
        XCTAssertNil(viewModel.error)
    }

    func testImageURLChangesWithDate() {
        let todayURL = viewModel.imageURL
        viewModel.goToPreviousDay()
        XCTAssertNotEqual(viewModel.imageURL, todayURL)
    }

    // MARK: - canGoBack boundary (7-day window)

    func testCannotGoBackBeyondSevenDays() {
        // Navigate back 6 times (today + 6 = 7 days)
        for _ in 0..<6 {
            viewModel.goToPreviousDay()
        }
        XCTAssertFalse(viewModel.canGoBack, "Should not be able to go beyond 7-day window")
    }

    func testGoToPreviousDayStopsAtBoundary() {
        // Navigate to boundary
        for _ in 0..<6 {
            viewModel.goToPreviousDay()
        }
        let dateAtBoundary = viewModel.currentDate
        viewModel.goToPreviousDay() // Should be a no-op
        XCTAssertEqual(
            Calendar.current.startOfDay(for: viewModel.currentDate),
            Calendar.current.startOfDay(for: dateAtBoundary)
        )
    }

    // MARK: - goToNextDay

    func testGoNextDayFromYesterdayReturnsToToday() {
        viewModel.goToPreviousDay()
        viewModel.goToNextDay()
        XCTAssertTrue(Calendar.current.isDateInToday(viewModel.currentDate))
    }

    func testGoNextDayFromTodayIsNoop() {
        let before = viewModel.currentDate
        viewModel.goToNextDay()
        XCTAssertEqual(
            Calendar.current.startOfDay(for: viewModel.currentDate),
            Calendar.current.startOfDay(for: before)
        )
    }

    // MARK: - navigateTo

    func testNavigateToSpecificDate() {
        let target = date(year: 2026, month: 1, day: 15)
        viewModel.navigateTo(date: target)
        XCTAssertEqual(
            Calendar.current.startOfDay(for: viewModel.currentDate),
            Calendar.current.startOfDay(for: target)
        )
    }

    func testNavigateClearsMetadataAndError() {
        viewModel.navigateTo(date: date(year: 2026, month: 1, day: 1))
        XCTAssertNil(viewModel.metadata)
        XCTAssertNil(viewModel.error)
    }

    func testNavigateToFutureDateSetsCurrent() {
        let future = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        viewModel.navigateTo(date: future)
        XCTAssertFalse(Calendar.current.isDateInToday(viewModel.currentDate))
    }

    // MARK: - returnToToday

    func testReturnToTodayFromPastDate() {
        viewModel.goToPreviousDay()
        viewModel.returnToToday()
        XCTAssertTrue(Calendar.current.isDateInToday(viewModel.currentDate))
    }

    func testReturnToTodayWhenAlreadyToday() {
        viewModel.returnToToday()
        XCTAssertTrue(Calendar.current.isDateInToday(viewModel.currentDate))
    }

    func testReturnToTodayResetsCanGoForward() {
        viewModel.goToPreviousDay()
        XCTAssertTrue(viewModel.canGoForward)
        viewModel.returnToToday()
        XCTAssertFalse(viewModel.canGoForward)
    }

    // MARK: - Helpers

    private func date(year: Int, month: Int, day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day; comps.hour = 12
        return Calendar.current.date(from: comps)!
    }
}
