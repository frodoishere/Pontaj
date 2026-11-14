import Foundation
import Combine

/// Sesiunea activa (in desfasurare), salvata pe disc ca sa supravietuiasca
/// inchiderii aplicatiei.
private struct ActiveSession: Codable {
    var projectId: UUID
    var projectName: String
    var start: Date
    var pausedAt: Date?
    var totalPaused: TimeInterval

    init(projectId: UUID, projectName: String, start: Date, pausedAt: Date? = nil, totalPaused: TimeInterval = 0) {
        self.projectId = projectId
        self.projectName = projectName
        self.start = start
        self.pausedAt = pausedAt
        self.totalPaused = totalPaused
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try c.decode(UUID.self, forKey: .projectId)
        projectName = try c.decode(String.self, forKey: .projectName)
        start = try c.decode(Date.self, forKey: .start)
        pausedAt = try c.decodeIfPresent(Date.self, forKey: .pausedAt)
        totalPaused = try c.decodeIfPresent(TimeInterval.self, forKey: .totalPaused) ?? 0
    }
}

/// Date exportate pentru backup/restore.
struct BackupData: Codable {
    var projects: [Project]
    var entries: [TimeEntry]
    var normalDailyDuration: TimeInterval
}

/// Gestioneaza proiectele, pontajele si sesiunea activa.
@MainActor
final class PontajStore: ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published private(set) var entries: [TimeEntry] = []
    @Published private(set) var active: ActiveSessionState?

    @Published var normalDailyDuration: TimeInterval = 8.5 * 3600 {
        didSet { UserDefaults.standard.set(normalDailyDuration, forKey: Self.normalKey) }
    }

    private static let normalKey = "normalDailyDuration"

    struct ActiveSessionState: Equatable {
        var projectId: UUID
        var projectName: String
        var start: Date
        var pausedAt: Date?
        var totalPaused: TimeInterval

        var isPaused: Bool { pausedAt != nil }

        func elapsed(at now: Date) -> TimeInterval {
            var elapsed = now.timeIntervalSince(start) - totalPaused
            if let pausedAt { elapsed -= now.timeIntervalSince(pausedAt) }
            return max(0, elapsed)
        }
    }

    private let projectsURL: URL
    private let entriesURL: URL
    private let activeURL: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        projectsURL = dir.appendingPathComponent("projects.json")
        entriesURL = dir.appendingPathComponent("entries.json")
        activeURL = dir.appendingPathComponent("active.json")
        let savedNormal = UserDefaults.standard.double(forKey: Self.normalKey)
        if savedNormal > 0 { normalDailyDuration = savedNormal }
        load()
    }

    func summary(for entries: [TimeEntry], clip: DateInterval? = nil) -> PeriodSummary {
        Stats.summary(for: entries, normalDaily: normalDailyDuration, clip: clip)
    }

    // MARK: - Stare derivata

    var isRunning: Bool { active != nil }

    func totalDuration(forProjectId id: UUID) -> TimeInterval {
        entries.filter { $0.projectId == id }.reduce(0) { $0 + $1.duration }
    }

    func billingTotal(for entries: [TimeEntry], clip: DateInterval? = nil) -> Double {
        entries.reduce(0) { sum, entry in
            let rate = projects.first { $0.id == entry.projectId }?.hourlyRate ?? 0
            return sum + (entry.workedDuration(in: clip) / 3600) * rate
        }
    }

    var sortedEntries: [TimeEntry] {
        entries.sorted { $0.start > $1.start }
    }

    // MARK: - Proiecte

    func addProject(name: String, hourlyRate: Double? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        projects.append(Project(name: trimmed, hourlyRate: hourlyRate))
        saveProjects()
    }

    func updateProject(_ project: Project) {
        guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[idx] = project
        saveProjects()
    }

    func renameProject(_ project: Project, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[idx].name = trimmed
        saveProjects()
    }

    func deleteProjects(at offsets: IndexSet) {
        let toDelete = offsets.map { projects[$0] }
        if let active, toDelete.contains(where: { $0.id == active.projectId }) { return }
        projects.remove(atOffsets: offsets)
        saveProjects()
    }

    // MARK: - Pontaj (Start / Pauza / Stop)

    func start(project: Project) {
        guard active == nil else { return }
        let session = ActiveSession(projectId: project.id, projectName: project.name, start: Date())
        active = state(from: session)
        saveActive(session)
        NotificationManager.scheduleLongSessionReminder(projectName: project.name)
    }

    func pause() {
        guard var session = loadActiveSession(), session.pausedAt == nil else { return }
        session.pausedAt = Date()
        active = state(from: session)
        saveActive(session)
    }

    func resume() {
        guard var session = loadActiveSession(), let pausedAt = session.pausedAt else { return }
        session.totalPaused += Date().timeIntervalSince(pausedAt)
        session.pausedAt = nil
        active = state(from: session)
        saveActive(session)
    }

    @discardableResult
    func stop() -> TimeEntry? {
        guard let active, var session = loadActiveSession() else { return nil }
        let end = Date()
        var paused = session.totalPaused
        if let pausedAt = session.pausedAt {
            paused += end.timeIntervalSince(pausedAt)
        }
        let entry = TimeEntry(
            projectId: active.projectId,
            projectName: active.projectName,
            start: active.start,
            end: end,
            pausedDuration: paused
        )
        entries.append(entry)
        self.active = nil
        saveEntries()
        clearActive()
        NotificationManager.cancelLongSessionReminder()
        return entry
    }

    func deleteEntry(_ entry: TimeEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    func updateEntry(_ entry: TimeEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = entry
        saveEntries()
    }

    func addEntry(projectId: UUID, projectName: String, start: Date, end: Date, note: String) {
        let entry = TimeEntry(
            projectId: projectId,
            projectName: projectName,
            start: start,
            end: end,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        entries.append(entry)
        saveEntries()
    }

    // MARK: - Backup / Restore

    func exportBackupFile() -> URL? {
        let backup = BackupData(projects: projects, entries: entries, normalDailyDuration: normalDailyDuration)
        guard let data = try? JSONEncoder().encode(backup) else { return nil }
        let name = "pontaj-backup-\(Formatters.fileStamp.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }

    func importBackup(from url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let backup = try? JSONDecoder().decode(BackupData.self, from: data) else { return false }
        projects = backup.projects
        entries = backup.entries
        normalDailyDuration = backup.normalDailyDuration
        saveProjects()
        saveEntries()
        return true
    }

    // MARK: - Export CSV

    func csvString(for entries: [TimeEntry], clip: DateInterval? = nil) -> String {
        var lines: [String] = []

        lines.append("Pontaje")
        lines.append("Proiect,Start,Stop,Durata,Ore,Ce am facut")
        for entry in entries {
            guard let range = entry.clippedInterval(to: clip) else { continue }
            let worked = entry.workedDuration(in: clip)
            let fields = [
                entry.projectName,
                Formatters.csv.string(from: range.start),
                Formatters.csv.string(from: range.end),
                Formatters.duration(worked),
                Formatters.decimalHours(worked),
                entry.note
            ]
            lines.append(fields.map(Self.escapeCSV).joined(separator: ","))
        }

        let days = Stats.dailySummaries(for: entries, normalDaily: normalDailyDuration, clip: clip)
        lines.append("")
        lines.append("Rezumat pe zile (prag \(Formatters.hoursMinutes(normalDailyDuration))/zi, ore zecimale)")
        lines.append("Data,Total,Normal,Suplimentar")
        for day in days {
            let fields = [
                Formatters.csvDate.string(from: day.day),
                Formatters.decimalHours(day.total),
                Formatters.decimalHours(day.normal),
                Formatters.decimalHours(day.overtime)
            ]
            lines.append(fields.map(Self.escapeCSV).joined(separator: ","))
        }

        let summary = self.summary(for: entries, clip: clip)
        lines.append("")
        lines.append("Total,\(Formatters.decimalHours(summary.total)),\(Formatters.decimalHours(summary.normal)),\(Formatters.decimalHours(summary.overtime))")

        let billing = billingTotal(for: entries, clip: clip)
        if billing > 0 {
            lines.append("")
            lines.append("Total facturabil,\(Formatters.money(billing))")
        }

        return lines.joined(separator: "\n")
    }

    func exportCSVFile(for entries: [TimeEntry], clip: DateInterval? = nil) -> URL? {
        let csv = csvString(for: entries, clip: clip)
        let name = "pontaje-\(Formatters.fileStamp.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        guard let data = ("\u{FEFF}" + csv).data(using: .utf8) else { return nil }
        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }

    private static func escapeCSV(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    // MARK: - Persistenta

    private func load() {
        projects = decode([Project].self, from: projectsURL) ?? []
        entries = decode([TimeEntry].self, from: entriesURL) ?? []
        if let session = loadActiveSession() {
            active = state(from: session)
        }
    }

    private func loadActiveSession() -> ActiveSession? {
        decode(ActiveSession.self, from: activeURL)
    }

    private func state(from session: ActiveSession) -> ActiveSessionState {
        ActiveSessionState(
            projectId: session.projectId,
            projectName: session.projectName,
            start: session.start,
            pausedAt: session.pausedAt,
            totalPaused: session.totalPaused
        )
    }

    private func saveProjects() { encode(projects, to: projectsURL) }
    private func saveEntries() { encode(entries, to: entriesURL) }
    private func saveActive(_ session: ActiveSession) { encode(session, to: activeURL) }
    private func clearActive() { try? FileManager.default.removeItem(at: activeURL) }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}

