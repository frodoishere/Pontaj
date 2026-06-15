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

    init(id: UUID = UUID(), projectId: UUID, projectName: String, start: Date, end: Date, note: String = "") {
        self.id = id
        self.projectId = projectId
        self.projectName = projectName
        self.start = start
        self.end = end
        self.note = note
    }

    /// Durata sesiunii in secunde.
    var duration: TimeInterval { end.timeIntervalSince(start) }
}

extension TimeEntry {
    /// Decoder personalizat ca pontajele salvate inainte de adaugarea
    /// campului `note` sa fie citite fara erori.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        projectId = try c.decode(UUID.self, forKey: .projectId)
        projectName = try c.decode(String.self, forKey: .projectName)
        start = try c.decode(Date.self, forKey: .start)
        end = try c.decode(Date.self, forKey: .end)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
    }
}
