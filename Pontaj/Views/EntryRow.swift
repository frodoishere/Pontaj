import SwiftUI

struct EntryRow: View {
    let entry: TimeEntry

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.badge.checkmark")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.projectName)
                    .font(.headline)
                Text("\(Formatters.dateTime.string(from: entry.start)) - \(Formatters.timeOnly.string(from: entry.end))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if entry.note.isEmpty {
                    Label("Adauga ce ai facut", systemImage: "square.and.pencil")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(entry.note)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            Text(Formatters.duration(entry.duration))
                .font(.subheadline.monospacedDigit())
                .fontWeight(.semibold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    EntryRow(
        entry: TimeEntry(
            projectId: UUID(),
            projectName: "Proiect demo",
            start: Date().addingTimeInterval(-3600),
            end: Date()
        )
    )
    .padding()
}
