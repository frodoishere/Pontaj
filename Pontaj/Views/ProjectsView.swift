import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var store: PontajStore
    @Environment(\.dismiss) private var dismiss

    @State private var newProjectName = ""

    private var normalHours: Int { Int(store.normalDailyDuration) / 3600 }
    private var normalMinutes: Int { (Int(store.normalDailyDuration) % 3600) / 60 }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Stepper(value: hoursBinding, in: 0...24) {
                        HStack {
                            Text("Ore")
                            Spacer()
                            Text("\(normalHours) h").foregroundStyle(.secondary)
                        }
                    }
                    Stepper(value: minutesBinding, in: 0...59, step: 5) {
                        HStack {
                            Text("Minute")
                            Spacer()
                            Text("\(normalMinutes) min").foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Program normal pe zi")
                } footer: {
                    Text("Acum: \(Formatters.hoursMinutes(store.normalDailyDuration)) pe zi. Ce depaseste acest prag intr-o zi se considera ore suplimentare.")
                }

                Section("Proiect nou") {
                    HStack {
                        TextField("Numele proiectului", text: $newProjectName)
                            .submitLabel(.done)
                            .onSubmit(addProject)
                        Button(action: addProject) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(trimmedName.isEmpty)
                    }
                }

                Section("Proiectele tale") {
                    if store.projects.isEmpty {
                        Text("Niciun proiect adaugat")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.projects) { project in
                            HStack {
                                Text(project.name)
                                Spacer()
                                Text(Formatters.durationShort(store.totalDuration(forProjectId: project.id)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: store.deleteProjects)
                    }
                }
            }
            .navigationTitle("Proiecte")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Gata") { dismiss() }
                }
            }
        }
    }

    private var hoursBinding: Binding<Int> {
        Binding(
            get: { normalHours },
            set: { store.normalDailyDuration = TimeInterval($0 * 3600 + normalMinutes * 60) }
        )
    }

    private var minutesBinding: Binding<Int> {
        Binding(
            get: { normalMinutes },
            set: { store.normalDailyDuration = TimeInterval(normalHours * 3600 + $0 * 60) }
        )
    }

    private var trimmedName: String {
        newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addProject() {
        guard !trimmedName.isEmpty else { return }
        store.addProject(name: trimmedName)
        newProjectName = ""
    }
}

#Preview {
    ProjectsView()
        .environmentObject(PontajStore())
}
