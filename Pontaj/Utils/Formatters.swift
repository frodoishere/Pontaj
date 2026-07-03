import Foundation

enum Formatters {
    /// Data + ora in formatul local al telefonului (ex: 14.06.2026, 17:30).
    static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    /// Doar ora (ex: 17:30).
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    /// Doar data, folosita pentru gruparea pontajelor pe zile.
    static let dayHeader: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f
    }()

    /// Data + ora pentru export CSV (format fix, usor de prelucrat).
    static let csv: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    /// Doar data pentru export CSV (yyyy-MM-dd).
    static let csvDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Marca de timp folosita in numele fisierului exportat.
    static let fileStamp: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return f
    }()

    /// Durata ca HH:MM:SS.
    static func duration(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// Durata in ore zecimale, pentru calcule in Excel (ex: 8:30 -> "8.50").
    /// Foloseste punct ca separator zecimal (independent de limba).
    static func decimalHours(_ interval: TimeInterval) -> String {
        String(format: "%.2f", max(0, interval) / 3600)
    }

    /// Durata ca H:MM (ex: 8:30), folosita pentru programul normal.
    static func hoursMinutes(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        return String(format: "%d:%02d", h, m)
    }

    /// Durata scurta, prietenoasa (ex: 1h 30m sau 45m).
    static func durationShort(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    /// Suma in lei (ex: 1.250,50 lei).
    static func money(_ amount: Double) -> String {
        String(format: "%.2f lei", amount)
    }
}
