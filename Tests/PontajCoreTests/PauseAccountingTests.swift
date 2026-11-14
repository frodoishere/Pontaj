import Foundation
import XCTest
@testable import PontajCore

final class PauseAccountingTests: XCTestCase {
    private let projectA = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let projectB = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let accuracy: Double = 0.000_001
    private var previousTimeZone: TimeZone!

    override func setUp() {
        super.setUp()
        previousTimeZone = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "Europe/Bucharest")!
        XCTAssertEqual(Calendar.current.timeZone.identifier, "Europe/Bucharest")
    }

    override func tearDown() {
        NSTimeZone.default = previousTimeZone
        super.tearDown()
    }

    private func date(_ year: Int = 2026, _ month: Int = 11, _ day: Int = 14,
                      _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Bucharest")!
        return calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute
        ))!
    }

    private func entry(start: Date, end: Date, pause: TimeInterval = 0,
                       project: UUID? = nil) -> TimeEntry {
        TimeEntry(
            projectId: project ?? projectA,
            projectName: project == projectB ? "Project B" : "Project A",
            start: start, end: end, pausedDuration: pause
        )
    }

    private func assertTotal(_ expected: TimeInterval, entries: [TimeEntry],
                             clip: DateInterval? = nil,
                             file: StaticString = #filePath, line: UInt = #line) {
        let summary = Stats.summary(for: entries, normalDaily: 8 * 3600, clip: clip)
        let days = Stats.dailySummaries(for: entries, normalDaily: 8 * 3600, clip: clip)
        XCTAssertEqual(summary.total, expected, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(summary.perProject.reduce(0) { $0 + $1.total }, expected,
                       accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(days.reduce(0) { $0 + $1.total }, expected,
                       accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(summary.normal + summary.overtime, expected,
                       accuracy: accuracy, file: file, line: line)
        XCTAssertTrue(days.allSatisfy { $0.total >= 0 && $0.normal >= 0 && $0.overtime >= 0 },
                      file: file, line: line)
    }

    func testFifteenMinutePauseIsExcludedFromEveryTotal() {
        let item = entry(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 10), pause: 900)
        XCTAssertEqual(item.duration, 2700, accuracy: accuracy)
        assertTotal(2700, entries: [item])
    }

    func testOneHourPauseDoesNotCreateFalseOvertime() {
        let item = entry(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 18), pause: 3600)
        let summary = Stats.summary(for: [item], normalDaily: 8 * 3600)
        XCTAssertEqual(summary.total, 28_800, accuracy: accuracy)
        XCTAssertEqual(summary.normal, 28_800, accuracy: accuracy)
        XCTAssertEqual(summary.overtime, 0, accuracy: accuracy)
        assertTotal(28_800, entries: [item])
    }

    func testMultipleEntriesAndProjectsUseNetDailyTime() {
        let morning = entry(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 13), pause: 1800)
        let afternoon = entry(start: date(2026, 11, 14, 14), end: date(2026, 11, 14, 19),
                              pause: 1800, project: projectB)
        let summary = Stats.summary(for: [morning, afternoon], normalDaily: 8 * 3600)
        XCTAssertEqual(summary.perProject.first { $0.id == projectA }?.total ?? -1,
                       12_600, accuracy: accuracy)
        XCTAssertEqual(summary.perProject.first { $0.id == projectB }?.total ?? -1,
                       16_200, accuracy: accuracy)
        XCTAssertEqual(summary.overtime, 0, accuracy: accuracy)
        assertTotal(28_800, entries: [morning, afternoon])
    }

    func testLegacyAggregatePauseIsSharedProportionallyAcrossMidnight() {
        // The historical record knows the pause total, not when it occurred.
        // Two equal one-hour portions therefore receive 45 net minutes each.
        let item = entry(start: date(2026, 11, 14, 23), end: date(2026, 11, 15, 1), pause: 1800)
        let days = Stats.dailySummaries(for: [item], normalDaily: 8 * 3600)
        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days.first { $0.day == date(2026, 11, 14, 0) }?.total ?? -1,
                       2700, accuracy: accuracy)
        XCTAssertEqual(days.first { $0.day == date(2026, 11, 15, 0) }?.total ?? -1,
                       2700, accuracy: accuracy)
        assertTotal(5400, entries: [item])
    }

    func testPartialFilterRetainsOnlyItsShareOfNetTime() {
        let item = entry(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 10), pause: 900)
        let window = DateInterval(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 9, 30))
        // Half of the session's 45 net minutes is 22.5 minutes.
        assertTotal(1350, entries: [item], clip: window)
    }

    func testAdjacentFiltersPartitionNetTimeWithoutSubtractingPauseTwice() {
        let item = entry(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 10), pause: 900)
        let first = DateInterval(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 9, 20))
        let second = DateInterval(start: first.end, end: date(2026, 11, 14, 10))
        let a = Stats.summary(for: [item], normalDaily: 8 * 3600, clip: first)
        let b = Stats.summary(for: [item], normalDaily: 8 * 3600, clip: second)
        XCTAssertEqual(a.total, 900, accuracy: accuracy)
        XCTAssertEqual(b.total, 1800, accuracy: accuracy)
        XCTAssertEqual(a.total + b.total, item.duration, accuracy: accuracy)
    }

    func testZeroAndInvertedIntervalsNeverProduceNegativeTotals() {
        let zero = entry(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 9))
        let inverted = entry(start: date(2026, 11, 14, 10), end: date(2026, 11, 14, 9))
        XCTAssertEqual(zero.duration, 0, accuracy: accuracy)
        XCTAssertEqual(inverted.duration, 0, accuracy: accuracy)
        assertTotal(0, entries: [zero, inverted])
    }

    func testPauseEqualToOrLongerThanSessionContributesZero() {
        let allPaused = entry(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 10), pause: 3600)
        let oversized = entry(start: date(2026, 11, 14, 11), end: date(2026, 11, 14, 12), pause: 7200)
        XCTAssertEqual(allPaused.duration, 0, accuracy: accuracy)
        XCTAssertEqual(oversized.duration, 0, accuracy: accuracy)
        assertTotal(0, entries: [allPaused, oversized])
    }

    func testWindowOutsideSessionAndExactBoundaryAreEmpty() {
        let item = entry(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 10), pause: 900)
        let outside = DateInterval(start: date(2026, 11, 14, 10), end: date(2026, 11, 14, 11))
        assertTotal(0, entries: [item], clip: outside)
    }

    func testRecordsWithoutPauseOrNoteStillDecode() throws {
        let object: [String: Any] = [
            "id": "33333333-3333-3333-3333-333333333333",
            "projectId": projectA.uuidString,
            "projectName": "Legacy project",
            "start": date(2026, 11, 14, 9).timeIntervalSinceReferenceDate,
            "end": date(2026, 11, 14, 10).timeIntervalSinceReferenceDate
        ]
        let data = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(TimeEntry.self, from: data)
        XCTAssertEqual(decoded.pausedDuration, 0, accuracy: accuracy)
        XCTAssertEqual(decoded.note, "")
        XCTAssertEqual(decoded.duration, 3600, accuracy: accuracy)
        assertTotal(3600, entries: [decoded])
    }

    func testExistingPauseSurvivesJSONRoundTrip() throws {
        let original = entry(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 10), pause: 900)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TimeEntry.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.pausedDuration, 900, accuracy: accuracy)
        XCTAssertEqual(decoded.duration, 2700, accuracy: accuracy)
    }

    func testSpringDSTUsesCalendarDaysAndPreservesNetTotal() {
        // Bucharest changes to summer time on 29 March 2026: this middle day
        // lasts 23 hours. The full session is 1 + 23 + 1 = 25 elapsed hours.
        // With one aggregate paused hour the net scale is 24 / 25.
        let item = entry(start: date(2026, 3, 28, 23), end: date(2026, 3, 30, 1), pause: 3600)
        XCTAssertEqual(item.end.timeIntervalSince(item.start), 90_000, accuracy: accuracy)
        XCTAssertEqual(item.duration, 86_400, accuracy: accuracy)
        let days = Stats.dailySummaries(for: [item], normalDaily: 8 * 3600)
        XCTAssertEqual(days.count, 3)
        XCTAssertEqual(days.first { $0.day == date(2026, 3, 28, 0) }?.total ?? -1,
                       3456, accuracy: accuracy)
        XCTAssertEqual(days.first { $0.day == date(2026, 3, 29, 0) }?.total ?? -1,
                       79_488, accuracy: accuracy)
        XCTAssertEqual(days.first { $0.day == date(2026, 3, 30, 0) }?.total ?? -1,
                       3456, accuracy: accuracy)
        assertTotal(86_400, entries: [item])
    }

    func testNoPauseCalculationsRemainUnchanged() {
        let item = entry(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 10))
        assertTotal(3600, entries: [item])
        let window = DateInterval(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 9, 30))
        assertTotal(1800, entries: [item], clip: window)
    }

    func testNegativePauseNeverAddsWorkedTime() {
        // A malformed imported pause must not manufacture extra billable time.
        let item = entry(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 10), pause: -900)
        XCTAssertEqual(item.duration, 3600, accuracy: accuracy)
        assertTotal(3600, entries: [item])
        let window = DateInterval(start: date(2026, 11, 14, 9), end: date(2026, 11, 14, 9, 30))
        assertTotal(1800, entries: [item], clip: window)
    }
}
