import SwiftUI
import UniformTypeIdentifiers

struct ProjectsView: View {
    @EnvironmentObject private var store: PontajStore
    @Environment(\.dismiss) private var dismiss

    @State private var newProjectName = ""
    @State private var editingProject: Project?
    @State private var shareItem: ShareItem?
    @State private var showImportPicker = false
    @State private var importError = false

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
                    Text("Acum: \(Formatters.hoursMinutes(store.normalDailyDuration)) pe zi. Ce depășește acest prag într-o zi se consideră ore suplimentare.")
                }

                Section("Proiect nou") {
                    HStack {
                        TextField("Numele proiectului", text: $newProjectName)
                            .submitLabel(.done)
                            .onSubmit(addProject)
                        Button(action: addProject) {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
                        .disabled(trimmedName.isEmpty)
                    }
                }

                Section("Proiectele tale") {
                    if store.projects.isEmpty {
                        Text("Niciun proiect adăugat")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.projects) { project in
                            Button { editingProject = project } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(project.name)
                                        if let rate = project.hourlyRate, rate > 0 {
                                            Text("\(Formatters.money(rate)) / oră")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(Formatters.durationShort(store.totalDuration(forProjectId: project.id)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                        .onDelete(perform: store.deleteProjects)
                    }
                }

                Section("Backup") {
                    Button {
                        if let url = store.exportBackupFile() {
                            shareItem = ShareItem(url: url)
                        }
                    } label: {
                        Label("Exportă backup", systemImage: "square.and.arrow.up")
                    }
                    Button { showImportPicker = true } label: {
                        Label("Restaurează din backup", systemImage: "square.and.arrow.down")
                    }
                } footer: {
                    Text("Backup-ul conține toate proiectele, pontajele și setările.")
                }
            }
            .navigationTitle("Proiecte")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Gata") { dismiss() }
                }
            }
            .sheet(item: $editingProject) { project in
                ProjectEditView(project: project).environmentObject(store)
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url])
            }
            .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if !store.importBackup(from: url) { importError = true }
                case .failure:
                    importError = true
                }
            }
            .alert("Backup invalid", isPresented: $importError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Fișierul selectat nu poate fi restaurat.")
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
