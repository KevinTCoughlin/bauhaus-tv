import XCTest
@testable import Bauhaus

@MainActor
final class ArtworkViewModelTests: XCTestCase {

    private var viewModel: ArtworkViewModel!

    override func setUp() {
        super.setUp()
        viewModel = ArtworkViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertNil(viewModel.metadata)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testImageURL() {
        XCTAssertEqual(
            viewModel.imageURL.absoluteString,
            "https://bauhaus.cascadiacollections.workers.dev/api/today?format=jpeg"
        )
    }
}
