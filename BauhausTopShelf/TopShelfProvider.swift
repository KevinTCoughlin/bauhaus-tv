import TVServices

class TopShelfProvider: NSObject, TVTopShelfContentProvider {
    var topShelfStyle: TVTopShelfContentStyle { .inset }

    func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        let items = last7Days().map { date -> TVTopShelfInsetItem in
            let dateStr = dateString(from: date)
            let isToday = Calendar.current.isDateInToday(date)

            let imageURL = URL(string: "https://bauhaus.cascadiacollections.workers.dev/api/\(isToday ? "today" : dateStr)?format=jpeg")!
            let launchURL = URL(string: "bauhaus://open?date=\(dateStr)")!

            let item = TVTopShelfInsetItem(identifier: dateStr)
            item.title = isToday ? "Today" : shortLabel(from: date)
            item.setImageURL(imageURL, for: .screenScale1x)
            item.displayAction = TVTopShelfAction(url: launchURL)
            return item
        }

        completionHandler(TVTopShelfInsetContent(items: items))
    }

    // MARK: - Helpers

    private func last7Days() -> [Date] {
        let cal = Calendar.current
        return (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: Date()) }
    }

    private func dateString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }

    private func shortLabel(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
