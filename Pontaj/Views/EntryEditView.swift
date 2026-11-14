import SwiftUI

struct EntryEditView: View {
    enum Mode {
        case edit(TimeEntry)
        case create
    }

    private static let quickTags = ["Birou", "Teren", "Deplasare", "Ședință", "Montaj"]

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
                        Text("Durata lucrată")
                        Spacer()
                        Text(isValidInterval ? Formatters.duration(end.timeIntervalSince(start) - recordedPause)
                                             : intervalError)
                            .foregroundStyle(isValidInterval ? Color.secondary : Color.red)
                    }
                    .font(.subheadline)
                    if recordedPause > 0 {
                        Text("Pauză păstrată: \(Formatters.durationShort(recordedPause))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Ce am făcut") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Self.quickTags, id: \.self) { tag in
                                Button {
                                    appendTag(tag)
                                } label: {
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color(.tertiarySystemFill)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    TextField("Descrie pe scurt ce ai lucrat...", text: $note, axis: .vertical)
                        .lineLimit(3...8)
                }

                if case .edit(let entry) = mode {
                    Section {
                        Button(role: .destructive) {
                            store.deleteEntry(entry)
                            dismiss()
                        } label: {
                            Label("Șterge pontajul", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isCreate ? "Pontaj nou" : "Editează pontajul")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Închide") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvează", action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var isCreate: Bool {
        if case .create = mode { return true }
        return false
    }

    private var recordedPause: TimeInterval {
        if case .edit(let entry) = mode { return max(0, entry.pausedDuration) }
        return 0
    }

    private var isValidInterval: Bool {
        end > start && end.timeIntervalSince(start) >= recordedPause
    }

    private var intervalError: String {
        end <= start ? "Stop trebuie după Start" : "Intervalul este mai scurt decât pauza păstrată"
    }
    private var canSave: Bool { projectId != nil && isValidInterval }

    private func appendTag(_ tag: String) {
        if note.isEmpty {
            note = tag
        } else if !note.contains(tag) {
            note += note.hasSuffix(".") || note.hasSuffix(",") ? " \(tag)" : ", \(tag)"
        }
    }

    private func save() {
        guard canSave, let projectId,
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

