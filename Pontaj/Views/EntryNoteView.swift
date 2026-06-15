import SwiftUI

/// Ecran pentru a scrie / edita "ce am facut" intr-un pontaj.
struct EntryNoteView: View {
    @EnvironmentObject private var store: PontajStore
    @Environment(\.dismiss) private var dismiss

    let entry: TimeEntry
    @State private var text: String
    @FocusState private var focused: Bool

    init(entry: TimeEntry) {
        self.entry = entry
        _text = State(initialValue: entry.note)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(entry.projectName)
                            .font(.headline)
                        Spacer()
                        Text(Formatters.duration(entry.duration))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text("\(Formatters.dateTime.string(from: entry.start)) - \(Formatters.timeOnly.string(from: entry.end))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Ce am facut") {
                    TextField("Descrie pe scurt ce ai lucrat...", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                        .focused($focused)
                }
            }
            .navigationTitle("Detalii pontaj")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Inchide") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salveaza") {
                        store.updateNote(for: entry.id, note: text)
                        dismiss()
                    }
                }
            }
            .onAppear { focused = true }
        }
    }
}

#Preview {
    EntryNoteView(
        entry: TimeEntry(
            projectId: UUID(),
            projectName: "Proiect demo",
            start: Date().addingTimeInterval(-3600),
            end: Date()
        )
    )
    .environmentObject(PontajStore())
}
