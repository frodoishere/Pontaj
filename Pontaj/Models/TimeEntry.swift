import Foundation

/// O sesiune de pontaj inregistrata: proiect, ora de start si ora de stop.
struct TimeEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var projectId: UUID
    var projectName: String
    var start: Date
    var end: Date
    /// Descrierea a ceea ce s-a lucrat in sesiune (optional).
    var note: String
    /// Timp scazut din durata (pauze in sesiune).
    var pausedDuration: TimeInterval

    init(id: UUID = UUID(), projectId: UUID, projectName: String, start: Date, end: Date,
         note: String = "", pausedDuration: TimeInterval = 0) {
        self.id = id
        self.projectId = projectId
        self.projectName = projectName
        self.start = start
        self.end = end
        self.note = note
        self.pausedDuration = pausedDuration
    }

    /// Durata efectiva lucrată (fara pauze).
    var duration: TimeInterval { max(0, end.timeIntervalSince(start) - pausedDuration) }
}

extension TimeEntry {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        projectId = try c.decode(UUID.self, forKey: .projectId)
        projectName = try c.decode(String.self, forKey: .projectName)
        start = try c.decode(Date.self, forKey: .start)
        end = try c.decode(Date.self, forKey: .end)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        pausedDuration = try c.decodeIfPresent(TimeInterval.self, forKey: .pausedDuration) ?? 0
    }
}
