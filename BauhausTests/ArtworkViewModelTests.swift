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

    func testSuccessfulLoadUpdatesMetadataAndStopsLoading() async {
        let metadata = ArtworkMetadata(
            title: "Test",
            artist: "Artist",
            date: BauhausAPI.dateString(from: Date()),
            styleTitle: "Style",
            styleArtist: "Style Artist"
        )
        viewModel = ArtworkViewModel(api: MockAPI(result: .success(metadata)))

        await viewModel.load()

        XCTAssertEqual(viewModel.metadata?.title, "Test")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testMissingPastArtworkIsNotReportedAsStillGenerating() async {
        viewModel = ArtworkViewModel(api: MockAPI(result: .failure(BauhausAPI.APIError.notFound)))
        viewModel.currentDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        await viewModel.load()

        XCTAssertFalse(viewModel.isNotYetGenerated)
        XCTAssertEqual(viewModel.error, "Artwork isn't available for this date.")
        XCTAssertFalse(viewModel.isLoading)
    }
}

private struct MockAPI: BauhausAPIProtocol {
    let result: Result<ArtworkMetadata, Error>

    func fetchMetadata(for date: Date) async throws -> ArtworkMetadata {
        try result.get()
    }

    func prefetchImage(for date: Date) async {}
}
