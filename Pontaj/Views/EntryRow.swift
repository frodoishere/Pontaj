import SwiftUI

struct EntryRow: View {
    let entry: TimeEntry
    var clip: DateInterval? = nil

    private var displayedRange: DateInterval {
        entry.clippedInterval(to: clip) ?? DateInterval(start: entry.start, duration: 0)
    }

    private var worked: TimeInterval { entry.workedDuration(in: clip) }
    private var allocatedPause: TimeInterval { max(0, displayedRange.duration - worked) }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.badge.checkmark")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.projectName)
                    .font(.headline)
                Text("\(Formatters.dateTime.string(from: displayedRange.start)) - \(Formatters.timeOnly.string(from: displayedRange.end))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if entry.note.isEmpty {
                    Label("Adaugă ce ai făcut", systemImage: "square.and.pencil")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(entry.note)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if allocatedPause > 0 {
                    Label("Pauză alocată: \(Formatters.durationShort(allocatedPause))", systemImage: "pause.circle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Text(Formatters.duration(worked))
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

