import Foundation

/// Un proiect pe care se face pontajul.
struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    /// Tarif pe ora (optional). Folosit pentru total facturabil in rezumat.
    var hourlyRate: Double?

    init(id: UUID = UUID(), name: String, hourlyRate: Double? = nil) {
        self.id = id
        self.name = name
        self.hourlyRate = hourlyRate
    }
}

extension Project {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        hourlyRate = try c.decodeIfPresent(Double.self, forKey: .hourlyRate)
    }
}
