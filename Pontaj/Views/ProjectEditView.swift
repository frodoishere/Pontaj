import SwiftUI

/// Editare proiect: nume si tarif pe oră.
struct ProjectEditView: View {
    @EnvironmentObject private var store: PontajStore
    @Environment(\.dismiss) private var dismiss

    let project: Project

    @State private var name: String
    @State private var rateText: String

    init(project: Project) {
        self.project = project
        _name = State(initialValue: project.name)
        _rateText = State(initialValue: project.hourlyRate.map { String(format: "%.0f", $0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalii") {
                    TextField("Numele proiectului", text: $name)
                    TextField("Tarif pe oră (lei, opțional)", text: $rateText)
                        .keyboardType(.decimalPad)
                }
                Section {
                    HStack {
                        Text("Total pontat")
                        Spacer()
                        Text(Formatters.durationShort(store.totalDuration(forProjectId: project.id)))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Editează proiect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Închide") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvează", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        var updated = project
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.hourlyRate = Double(rateText.replacingOccurrences(of: ",", with: "."))
        store.updateProject(updated)
        dismiss()
    }
}
