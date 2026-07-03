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
            List {
                Section {
                    VStack(spacing: 24) {
                        TimerCard(active: store.active)
                        controls
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if !store.entries.isEmpty {
                    Section {
                        FilterBar(filter: $filter)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }

                if !filteredEntries.isEmpty {
                    Section {
                        SummaryView(
                            summary: periodSummary,
                            normalDaily: store.normalDailyDuration,
                            billingTotal: store.billingTotal(for: filteredEntries)
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if store.sortedEntries.isEmpty {
                    Section {
                        Text("Încă nu ai niciun pontaj. Alege un proiect și apasă Start.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if filteredEntries.isEmpty {
                    Section {
                        Text("Niciun pontaj pentru filtrul selectat.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(groupedEntries, id: \.day) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                Button { editingEntry = entry } label: {
                                    EntryRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Haptics.warning()
                                        store.deleteEntry(entry)
                                    } label: {
                                        Label("Șterge", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text(Formatters.dayHeader.string(from: group.day))
                                Spacer()
                                Text(Formatters.durationShort(group.entries.reduce(0) { $0 + $1.duration }))
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
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
                    HStack(spacing: 16) {
                        if !store.projects.isEmpty {
                            Button { showAddEntry = true } label: {
                                Image(systemName: "plus.circle")
                            }
                        }
                        Button { showProjects = true } label: {
                            Label("Proiecte", systemImage: "folder")
                        }
                    }
                }
            }
            .sheet(isPresented: $showProjects) {
                ProjectsView().environmentObject(store)
            }
            .sheet(item: $editingEntry) { entry in
                EntryEditView(mode: .edit(entry)).environmentObject(store)
            }
            .sheet(isPresented: $showAddEntry) {
                EntryEditView(mode: .create).environmentObject(store)
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

    // MARK: - Controale

    private var controls: some View {
        VStack(spacing: 16) {
            if store.isRunning {
                HStack(spacing: 12) {
                    if store.active?.isPaused == true { resumeButton } else { pauseButton }
                    stopButton
                }
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
            Text("Adaugă un proiect ca să poți porni pontajul.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button { showProjects = true } label: {
                Label("Adaugă primul proiect", systemImage: "plus")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var projectPicker: some View {
        Menu {
            ForEach(store.projects) { project in
                Button { selectedProjectId = project.id } label: {
                    if project.id == selectedProjectId {
                        Label(project.name, systemImage: "checkmark")
                    } else {
                        Text(project.name)
                    }
                }
            }
            Divider()
            Button { showProjects = true } label: {
                Label("Adaugă / gestionează proiecte", systemImage: "plus")
            }
        } label: {
            HStack {
                Image(systemName: "folder")
                Text(selectedProjectName ?? "Alege un proiect").fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    private var startButton: some View {
        Button {
            guard let project = selectedProject ?? store.projects.first else { return }
            selectedProjectId = project.id
            Haptics.medium()
            withAnimation { store.start(project: project) }
        } label: {
            Label("Start", systemImage: "play.fill")
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }

    private var pauseButton: some View {
        Button {
            Haptics.light()
            withAnimation { store.pause() }
        } label: {
            Label("Pauză", systemImage: "pause.fill")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
    }

    private var resumeButton: some View {
        Button {
            Haptics.light()
            withAnimation { store.resume() }
        } label: {
            Label("Reluare", systemImage: "play.fill")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }

    private var stopButton: some View {
        Button {
            Haptics.success()
            let saved = withAnimation { store.stop() }
            if let saved { editingEntry = saved }
        } label: {
            Label("Stop", systemImage: "stop.fill")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
    }

    // MARK: - Helpers

    private var filteredEntries: [TimeEntry] {
        store.sortedEntries.filter { filter.matches($0) }
    }

    private var groupedEntries: [(day: Date, entries: [TimeEntry])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filteredEntries) { cal.startOfDay(for: $0.start) }
        return groups
            .map { (day: $0.key, entries: $0.value.sorted { $0.start > $1.start }) }
            .sorted { $0.day > $1.day }
    }

    private var periodSummary: PeriodSummary {
        store.summary(for: filteredEntries, clip: filter.dateInterval)
    }

    private var selectedProject: Project? {
        store.projects.first { $0.id == selectedProjectId }
    }

    private var selectedProjectName: String? { selectedProject?.name }

    private func syncSelection() {
        if let active = store.active {
            selectedProjectId = active.projectId
        } else if selectedProjectId == nil {
            selectedProjectId = store.projects.first?.id
        }
    }
}

#Preview {
    ContentView().environmentObject(PontajStore())
}
