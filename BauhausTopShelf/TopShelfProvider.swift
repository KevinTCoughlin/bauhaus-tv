import TVServices

class TopShelfProvider: TVTopShelfContentProvider {
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        let base = "https://bauhaus.cascadiacollections.workers.dev"
        let items = last7Days().map { date -> TVTopShelfSectionedItem in
            let dateStr = dateString(from: date)
            let isToday = Calendar.current.isDateInToday(date)

            // Past dates use immutable 1-year cache; today uses 5-min cache
            let imageURL = URL(string: "\(base)/api/\(isToday ? "today" : dateStr)?format=jpeg")!
            let launchURL = URL(string: "bauhaus://open?date=\(dateStr)")!

            let item = TVTopShelfSectionedItem(identifier: dateStr)
            item.title = isToday ? "Today" : shortLabel(from: date)
            item.imageShape = .hdtv
            item.setImageURL(imageURL, for: .screenScale1x)
            item.displayAction = TVTopShelfAction(url: launchURL)
            return item
        }

        let collection = TVTopShelfItemCollection(items: items)
        completionHandler(TVTopShelfSectionedContent(sections: [collection]))
    }

    // MARK: - Helpers

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let shortLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private func last7Days() -> [Date] {
        let cal = Calendar.current
        return (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: Date()) }
    }

    private func dateString(from date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    private func shortLabel(from date: Date) -> String {
        Self.shortLabelFormatter.string(from: date)
    }
}
