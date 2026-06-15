import Foundation
import Combine

/// Sesiunea activa (in desfasurare), salvata pe disc ca sa supravietuiasca
/// inchiderii aplicatiei.
private struct ActiveSession: Codable {
    var projectId: UUID
    var projectName: String
    var start: Date
}

/// Gestioneaza proiectele, pontajele si sesiunea activa.
/// Toate datele sunt salvate local pe telefon (fisiere JSON in Documents).
@MainActor
final class PontajStore: ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published private(set) var entries: [TimeEntry] = []
    @Published private(set) var active: ActiveSessionState?

    /// Durata programului normal pe zi (in secunde). Implicit 8h30m.
    /// Ce depaseste acest prag intr-o zi este considerat ore suplimentare.
    @Published var normalDailyDuration: TimeInterval = 8.5 * 3600 {
        didSet { UserDefaults.standard.set(normalDailyDuration, forKey: Self.normalKey) }
    }

    private static let normalKey = "normalDailyDuration"

    /// Starea publica a sesiunii active, fara detalii de persistenta.
    struct ActiveSessionState: Equatable {
        var projectId: UUID
        var projectName: String
        var start: Date
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

    /// Rezumat (total/normal/suplimentar + per proiect) pentru pontajele date.
    /// `clip` decupeaza timpul la o perioada (ex: doar ziua de azi).
    func summary(for entries: [TimeEntry], clip: DateInterval? = nil) -> PeriodSummary {
        Stats.summary(for: entries, normalDaily: normalDailyDuration, clip: clip)
    }

    // MARK: - Stare derivata

    var isRunning: Bool { active != nil }

    /// Totalul (in secunde) pe fiecare proiect, din pontajele finalizate.
    func totalDuration(forProjectId id: UUID) -> TimeInterval {
        entries.filter { $0.projectId == id }.reduce(0) { $0 + $1.duration }
    }

    /// Pontajele sortate descrescator dupa ora de start (cele mai noi primele).
    var sortedEntries: [TimeEntry] {
        entries.sorted { $0.start > $1.start }
    }

    // MARK: - Proiecte

    func addProject(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        projects.append(Project(name: trimmed))
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
        // Nu sterge proiectul daca exact acela este pontat acum.
        if let active, toDelete.contains(where: { $0.id == active.projectId }) {
            return
        }
        projects.remove(atOffsets: offsets)
        saveProjects()
    }

    // MARK: - Pontaj (Start / Stop)

    /// Porneste pontajul pentru un proiect. Ora de start este preluata de la telefon.
    func start(project: Project) {
        guard active == nil else { return }
        let session = ActiveSession(projectId: project.id, projectName: project.name, start: Date())
        active = ActiveSessionState(projectId: session.projectId, projectName: session.projectName, start: session.start)
        saveActive(session)
    }

    /// Opreste pontajul curent si salveaza sesiunea. Ora de stop e preluata de la telefon.
    @discardableResult
    func stop() -> TimeEntry? {
        guard let active else { return nil }
        let entry = TimeEntry(
            projectId: active.projectId,
            projectName: active.projectName,
            start: active.start,
            end: Date()
        )
        entries.append(entry)
        self.active = nil
        saveEntries()
        clearActive()
        return entry
    }

    func deleteEntries(at offsets: IndexSet) {
        // offsets se refera la lista sortata afisata in UI.
        let displayed = sortedEntries
        let ids = offsets.map { displayed[$0].id }
        entries.removeAll { ids.contains($0.id) }
        saveEntries()
    }

    func deleteEntry(_ entry: TimeEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    /// Actualizeaza descrierea (ce s-a lucrat) pentru un pontaj.
    func updateNote(for entryId: UUID, note: String) {
        guard let idx = entries.firstIndex(where: { $0.id == entryId }) else { return }
        entries[idx].note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        saveEntries()
    }

    // MARK: - Export CSV

    /// Construieste continutul CSV pentru pontajele date: lista de pontaje +
    /// un rezumat pe zile (Total / Normal / Suplimentar) si totalurile generale.
    /// `clip` decupeaza rezumatul la perioada filtrata.
    func csvString(for entries: [TimeEntry], clip: DateInterval? = nil) -> String {
        var lines: [String] = []

        // Sectiunea 1: pontajele (durata si ore zecimale).
        lines.append("Pontaje")
        lines.append("Proiect,Start,Stop,Durata,Ore,Ce am facut")
        for entry in entries {
            let fields = [
                entry.projectName,
                Formatters.csv.string(from: entry.start),
                Formatters.csv.string(from: entry.end),
                Formatters.duration(entry.duration),
                Formatters.decimalHours(entry.duration),
                entry.note
            ]
            lines.append(fields.map(Self.escapeCSV).joined(separator: ","))
        }

        // Sectiunea 2: rezumat pe zile (in ore zecimale, pentru calcule).
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

        // Sectiunea 3: totaluri generale (ore zecimale).
        let summary = self.summary(for: entries, clip: clip)
        lines.append("")
        lines.append("Total,\(Formatters.decimalHours(summary.total)),\(Formatters.decimalHours(summary.normal)),\(Formatters.decimalHours(summary.overtime))")

        return lines.joined(separator: "\n")
    }

    /// Scrie CSV-ul intr-un fisier temporar si returneaza URL-ul lui (pentru share).
    func exportCSVFile(for entries: [TimeEntry], clip: DateInterval? = nil) -> URL? {
        let csv = csvString(for: entries, clip: clip)
        let name = "pontaje-\(Formatters.fileStamp.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        // BOM ca Excel sa recunoasca diacriticele UTF-8.
        guard let data = ("\u{FEFF}" + csv).data(using: .utf8) else { return nil }
        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }

    private static func escapeCSV(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    // MARK: - Persistenta

    private func load() {
        projects = decode([Project].self, from: projectsURL) ?? []
        entries = decode([TimeEntry].self, from: entriesURL) ?? []
        if let session = decode(ActiveSession.self, from: activeURL) {
            active = ActiveSessionState(
                projectId: session.projectId,
                projectName: session.projectName,
                start: session.start
            )
        }
    }

    private func saveProjects() { encode(projects, to: projectsURL) }
    private func saveEntries() { encode(entries, to: entriesURL) }

    private func saveActive(_ session: ActiveSession) { encode(session, to: activeURL) }

    private func clearActive() {
        try? FileManager.default.removeItem(at: activeURL)
    }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
