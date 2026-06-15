import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PontajStore

    @State private var selectedProjectId: UUID?
    @State private var showProjects = false
    @State private var editingEntry: TimeEntry?
    @State private var showAddEntry = false
    @State private var shareItem: ShareItem?
    @State private var filter = EntryFilter()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    TimerCard(active: store.active)
                    controls
                    entriesSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Pontaj")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if let url = store.exportCSVFile(for: filteredEntries, clip: filter.dateInterval) {
                            shareItem = ShareItem(url: url)
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(filteredEntries.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProjects = true
                    } label: {
                        Label("Proiecte", systemImage: "folder")
                    }
                }
            }
            .sheet(isPresented: $showProjects) {
                ProjectsView()
                    .environmentObject(store)
            }
            .sheet(item: $editingEntry) { entry in
                EntryEditView(mode: .edit(entry))
                    .environmentObject(store)
            }
            .sheet(isPresented: $showAddEntry) {
                EntryEditView(mode: .create)
                    .environmentObject(store)
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url])
            }
            .onAppear(perform: syncSelection)
            .onChange(of: store.projects.map(\.id)) { _ in
                if selectedProjectId == nil || !store.projects.contains(where: { $0.id == selectedProjectId }) {
                    selectedProjectId = store.projects.first?.id
                }
            }
        }
    }

    // MARK: - Selectie proiect + buton Start/Stop

    private var controls: some View {
        VStack(spacing: 16) {
            if store.isRunning {
                stopButton
            } else if store.projects.isEmpty {
                emptyProjectsPrompt
            } else {
                projectPicker
                startButton
            }
        }
    }

    private var emptyProjectsPrompt: some View {
        VStack(spacing: 12) {
            Text("Adauga un proiect ca sa poti porni pontajul.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Button {
                showProjects = true
            } label: {
                Label("Adauga primul proiect", systemImage: "plus")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var projectPicker: some View {
        Menu {
            if store.projects.isEmpty {
                Text("Niciun proiect")
            } else {
                ForEach(store.projects) { project in
                    Button {
                        selectedProjectId = project.id
                    } label: {
                        if project.id == selectedProjectId {
                            Label(project.name, systemImage: "checkmark")
                        } else {
                            Text(project.name)
                        }
                    }
                }
            }
            Divider()
            Button {
                showProjects = true
            } label: {
                Label("Adauga / gestioneaza proiecte", systemImage: "plus")
            }
        } label: {
            HStack {
                Image(systemName: "folder")
                Text(selectedProjectName ?? "Alege un proiect")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private var startButton: some View {
        Button {
            // Daca nimic nu e selectat dar exista proiecte, foloseste primul.
            guard let project = selectedProject ?? store.projects.first else { return }
            selectedProjectId = project.id
            withAnimation { store.start(project: project) }
        } label: {
            Label("Start", systemImage: "play.fill")
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(store.projects.isEmpty)
    }

    private var stopButton: some View {
        Button {
            let saved = withAnimation { store.stop() }
            if let saved { editingEntry = saved }
        } label: {
            Label("Stop", systemImage: "stop.fill")
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
    }

    // MARK: - Lista de pontaje

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pontaje")
                    .font(.title3.bold())
                Spacer()
                if !filteredEntries.isEmpty {
                    Text(Formatters.durationShort(periodSummary.total))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !store.projects.isEmpty {
                    Button {
                        showAddEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }

            if !store.entries.isEmpty {
                FilterBar(filter: $filter)
            }

            if !filteredEntries.isEmpty {
                SummaryView(summary: periodSummary,
                            normalDaily: store.normalDailyDuration)
            }

            if store.sortedEntries.isEmpty {
                Text("Inca nu ai niciun pontaj. Alege un proiect si apasa Start.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else if filteredEntries.isEmpty {
                Text("Niciun pontaj pentru filtrul selectat.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(groupedEntries, id: \.day) { group in
                    dayGroup(group)
                }
            }
        }
    }

    /// Un grup de pontaje dintr-o zi, cu antet (data + subtotal).
    private func dayGroup(_ group: (day: Date, entries: [TimeEntry])) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Formatters.dayHeader.string(from: group.day))
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Formatters.durationShort(group.entries.reduce(0) { $0 + $1.duration }))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            ForEach(group.entries) { entry in
                Button {
                    editingEntry = entry
                } label: {
                    EntryRow(entry: entry)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        editingEntry = entry
                    } label: {
                        Label("Editeaza", systemImage: "square.and.pencil")
                    }
                    Button(role: .destructive) {
                        store.deleteEntry(entry)
                    } label: {
                        Label("Sterge", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var filteredEntries: [TimeEntry] {
        store.sortedEntries.filter { filter.matches($0) }
    }

    /// Pontajele filtrate, grupate pe zi (dupa ora de start), zilele recente primele.
    private var groupedEntries: [(day: Date, entries: [TimeEntry])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filteredEntries) { cal.startOfDay(for: $0.start) }
        return groups
            .map { (day: $0.key, entries: $0.value.sorted { $0.start > $1.start }) }
            .sorted { $0.day > $1.day }
    }

    /// Rezumatul perioadei, decupat la intervalul filtrului.
    private var periodSummary: PeriodSummary {
        store.summary(for: filteredEntries, clip: filter.dateInterval)
    }

    private var selectedProject: Project? {
        store.projects.first { $0.id == selectedProjectId }
    }

    private var selectedProjectName: String? { selectedProject?.name }

    /// Aliniaza selectia: daca exista o sesiune activa folosim proiectul ei,
    /// altfel alegem primul proiect daca nimic nu e selectat.
    private func syncSelection() {
        if let active = store.active {
            selectedProjectId = active.projectId
        } else if selectedProjectId == nil {
            selectedProjectId = store.projects.first?.id
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PontajStore())
}
