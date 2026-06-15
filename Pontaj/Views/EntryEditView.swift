import SwiftUI

/// Ecran pentru a edita un pontaj existent sau a adauga manual unul (pe trecut).
struct EntryEditView: View {
    enum Mode {
        case edit(TimeEntry)
        case create
    }

    @EnvironmentObject private var store: PontajStore
    @Environment(\.dismiss) private var dismiss

    let mode: Mode

    @State private var projectId: UUID?
    @State private var start: Date
    @State private var end: Date
    @State private var note: String

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .edit(let entry):
            _projectId = State(initialValue: entry.projectId)
            _start = State(initialValue: entry.start)
            _end = State(initialValue: entry.end)
            _note = State(initialValue: entry.note)
        case .create:
            let now = Date()
            _projectId = State(initialValue: nil)
            _start = State(initialValue: now.addingTimeInterval(-3600))
            _end = State(initialValue: now)
            _note = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Proiect") {
                    Picker("Proiect", selection: $projectId) {
                        Text("Alege un proiect").tag(UUID?.none)
                        ForEach(store.projects) { project in
                            Text(project.name).tag(UUID?.some(project.id))
                        }
                    }
                }

                Section("Interval") {
                    DatePicker("Start", selection: $start)
                    DatePicker("Stop", selection: $end)
                    HStack {
                        Text("Durata")
                        Spacer()
                        Text(isValidInterval ? Formatters.duration(end.timeIntervalSince(start))
                                             : "Stop trebuie dupa Start")
                            .foregroundStyle(isValidInterval ? Color.secondary : Color.red)
                    }
                    .font(.subheadline)
                }

                Section("Ce am facut") {
                    TextField("Descrie pe scurt ce ai lucrat...", text: $note, axis: .vertical)
                        .lineLimit(3...8)
                }

                if case .edit(let entry) = mode {
                    Section {
                        Button(role: .destructive) {
                            store.deleteEntry(entry)
                            dismiss()
                        } label: {
                            Label("Sterge pontajul", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isCreate ? "Pontaj nou" : "Editeaza pontajul")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Inchide") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salveaza", action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var isCreate: Bool {
        if case .create = mode { return true }
        return false
    }

    private var isValidInterval: Bool { end > start }

    private var canSave: Bool { projectId != nil && isValidInterval }

    private func save() {
        guard let projectId,
              let project = store.projects.first(where: { $0.id == projectId }) else { return }

        switch mode {
        case .edit(let entry):
            var updated = entry
            updated.projectId = project.id
            updated.projectName = project.name
            updated.start = start
            updated.end = end
            updated.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            store.updateEntry(updated)
        case .create:
            store.addEntry(projectId: project.id, projectName: project.name, start: start, end: end, note: note)
        }
        dismiss()
    }
}

#Preview {
    EntryEditView(mode: .create)
        .environmentObject(PontajStore())
}
