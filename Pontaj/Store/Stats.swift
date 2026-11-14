import Foundation

/// Rezumat calculat pentru un set de pontaje (de obicei cele filtrate).
struct PeriodSummary {
    /// Total lucrat (suma duratelor).
    var total: TimeInterval = 0
    /// Ore in cadrul programului normal.
    var normal: TimeInterval = 0
    /// Ore suplimentare (peste pragul zilnic).
    var overtime: TimeInterval = 0
    /// Totaluri pe fiecare proiect, sortate descrescator dupa durata.
    var perProject: [ProjectTotal] = []
    /// Numarul de zile distincte in care s-a lucrat.
    var dayCount: Int = 0

    struct ProjectTotal: Identifiable {
        let id: UUID
        let name: String
        let total: TimeInterval
    }
}

/// Rezumat pentru o singura zi.
struct DaySummary: Identifiable {
    let day: Date
    let total: TimeInterval
    let normal: TimeInterval
    let overtime: TimeInterval
    var id: Date { day }
}

enum Stats {
    /// Imparte un interval (start..end) pe zile calendaristice, la limita de
    /// miezul noptii. Un pontaj care trece in ziua urmatoare este astfel
    /// contorizat corect pe fiecare zi in parte.
    static func dailyPortions(start: Date, end: Date, calendar: Calendar) -> [(day: Date, duration: TimeInterval)] {
        guard end > start else {
            return []
        }
        var portions: [(Date, TimeInterval)] = []
        var cursor = start
        while cursor < end {
            let dayStart = calendar.startOfDay(for: cursor)
            let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? end
            let segmentEnd = min(nextDay, end)
            portions.append((dayStart, segmentEnd.timeIntervalSince(cursor)))
            cursor = segmentEnd
        }
        return portions
    }

    /// Totaluri pe zi (cu split la miezul noptii, decupate la perioada).
    private static func dayTotals(for entries: [TimeEntry], calendar: Calendar, clip interval: DateInterval?) -> [Date: TimeInterval] {
        var totals: [Date: TimeInterval] = [:]
        for entry in entries {
            guard let range = entry.clippedInterval(to: interval) else { continue }
            for portion in dailyPortions(start: range.start, end: range.end, calendar: calendar) {
                let segment = DateInterval(start: max(range.start, portion.day), duration: portion.duration)
                let worked = entry.workedDuration(in: segment)
                guard worked > 0 else { continue }
                totals[portion.day, default: 0] += worked
            }
        }
        return totals
    }

    /// Calculeaza rezumatul. Orele suplimentare se calculeaza pe zi:
    /// pentru fiecare zi, ce depaseste `normalDaily` din totalul zilei este suplimentar.
    /// Daca `clip` este setat, se conteaza doar timpul din interiorul perioadei.
    static func summary(for entries: [TimeEntry], normalDaily: TimeInterval, clip interval: DateInterval? = nil) -> PeriodSummary {
        var result = PeriodSummary()
        guard !entries.isEmpty else { return result }

        let cal = Calendar.current

        // Total per proiect (decupat la perioada).
        var projectTotals: [UUID: (name: String, total: TimeInterval)] = [:]
        for entry in entries {
            let duration = entry.workedDuration(in: interval)
            guard duration > 0 else { continue }
            result.total += duration
            let existing = projectTotals[entry.projectId]
            projectTotals[entry.projectId] = (entry.projectName, (existing?.total ?? 0) + duration)
        }

        // Total per zi (cu split la miezul noptii) pentru normal vs suplimentar.
        let totalsByDay = Self.dayTotals(for: entries, calendar: cal, clip: interval)
        for (_, dayTotal) in totalsByDay {
            result.normal += min(dayTotal, normalDaily)
            result.overtime += max(0, dayTotal - normalDaily)
        }

        result.dayCount = totalsByDay.count
        result.perProject = projectTotals
            .map { PeriodSummary.ProjectTotal(id: $0.key, name: $0.value.name, total: $0.value.total) }
            .sorted { $0.total > $1.total }

        return result
    }

    /// Rezumat defalcat pe fiecare zi, sortat descrescator (cele mai noi primele).
    static func dailySummaries(for entries: [TimeEntry], normalDaily: TimeInterval, clip interval: DateInterval? = nil) -> [DaySummary] {
        let cal = Calendar.current
        return Self.dayTotals(for: entries, calendar: cal, clip: interval)
            .map { day, total in
                DaySummary(
                    day: day,
                    total: total,
                    normal: min(total, normalDaily),
                    overtime: max(0, total - normalDaily)
                )
            }
            .sorted { $0.day > $1.day }
    }
}

