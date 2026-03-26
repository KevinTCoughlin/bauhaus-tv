import TVServices

class TopShelfProvider: NSObject, TVTopShelfContentProvider {
    var topShelfStyle: TVTopShelfContentStyle { .inset }

    func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        let imageURL = URL(string: "https://bauhaus.cascadiacollections.workers.dev/api/today?format=jpeg")!
        let launchURL = URL(string: "bauhaus://open")!

        let item = TVTopShelfInsetItem(identifier: "today")
        item.title = "Today's Artwork"
        item.setImageURL(imageURL, for: .screenScale1x)
        item.displayAction = TVTopShelfAction(url: launchURL)

        let content = TVTopShelfInsetContent(items: [item])
        completionHandler(content)
    }
}
