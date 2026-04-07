import Foundation

enum ViewDataCommon {
    nonisolated private static let slashDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    nonisolated private static let yearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    nonisolated private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    nonisolated static func slashDateString(from date: Date) -> String {
        slashDateFormatter.string(from: date)
    }

    nonisolated static func yearMonthString(from date: Date) -> String {
        yearMonthFormatter.string(from: date)
    }

    nonisolated static func monthDayString(from date: Date) -> String {
        monthDayFormatter.string(from: date)
    }

    nonisolated static func yenString(from amount: Int) -> String {
        amount.formatted(.currency(code: "JPY"))
    }

    nonisolated static func intValue(from text: String) -> Int {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    nonisolated static var mondayFirstCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.firstWeekday = 2
        return calendar
    }
}

extension String {
    var trimmedText: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isTrimmedEmpty: Bool {
        trimmedText.isEmpty
    }

    var nilIfTrimmedEmpty: String? {
        let trimmed = trimmedText
        return trimmed.isEmpty ? nil : trimmed
    }
}
