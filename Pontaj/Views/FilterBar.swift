import SwiftUI

/// Filtru aplicat listei de pontaje: dupa proiect si dupa perioada.
struct EntryFilter: Equatable {
    /// nil = toate proiectele.
    var projectId: UUID?
    var period: Period = .all
    var customStart: Date = Calendar.current.startOfDay(for: Date())
    var customEnd: Date = Date()

    enum Period: String, CaseIterable, Identifiable {
        case all = "Toate"
        case today = "Azi"
        case week = "Saptamana"
        case month = "Luna"
        case custom = "Interval"
        var id: String { rawValue }
    }

    /// Intervalul de timp al perioadei selectate (nil = toate).
    var dateInterval: DateInterval? {
        let cal = Calendar.current
        let now = Date()
        switch period {
        case .all:
            return nil
        case .today:
            let start = cal.startOfDay(for: now)
            let end = cal.date(byAdding: .day, value: 1, to: start) ?? now
            return DateInterval(start: start, end: end)
        case .week:
            return cal.dateInterval(of: .weekOfYear, for: now)
        case .month:
            return cal.dateInterval(of: .month, for: now)
        case .custom:
            let start = cal.startOfDay(for: customStart)
            let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: customEnd)) ?? customStart
            return DateInterval(start: start, end: max(start, end))
        }
    }

    func matches(_ entry: TimeEntry) -> Bool {
        if let projectId, entry.projectId != projectId { return false }
        guard let interval = dateInterval else { return true }
        // Pontajul se intersecteaza cu perioada (inclusiv daca trece peste noapte).
        return entry.start < interval.end && entry.end > interval.start
    }

    var isActive: Bool {
        projectId != nil || period != .all
    }
}

/// Bara de filtrare afisata deasupra listei de pontaje.
struct FilterBar: View {
    @EnvironmentObject private var store: PontajStore
    @Binding var filter: EntryFilter

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                projectMenu
                periodMenu
            }

            if filter.period == .custom {
                HStack(spacing: 10) {
                    DatePicker("De la", selection: $filter.customStart, displayedComponents: .date)
                    DatePicker("Pana la", selection: $filter.customEnd, displayedComponents: .date)
                }
                .font(.caption)
                .datePickerStyle(.compact)
            }

            if filter.isActive {
                Button {
                    filter = EntryFilter()
                } label: {
                    Label("Sterge filtrele", systemImage: "xmark.circle")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var projectMenu: some View {
        Menu {
            Button {
                filter.projectId = nil
            } label: {
                pickLabel("Toate proiectele", selected: filter.projectId == nil)
            }
            ForEach(store.projects) { project in
                Button {
                    filter.projectId = project.id
                } label: {
                    pickLabel(project.name, selected: filter.projectId == project.id)
                }
            }
        } label: {
            chip(icon: "folder", text: selectedProjectName)
        }
    }

    private var periodMenu: some View {
        Menu {
            ForEach(EntryFilter.Period.allCases) { period in
                Button {
                    filter.period = period
                } label: {
                    pickLabel(period.rawValue, selected: filter.period == period)
                }
            }
        } label: {
            chip(icon: "calendar", text: filter.period.rawValue)
        }
    }

    private var selectedProjectName: String {
        guard let id = filter.projectId else { return "Toate" }
        return store.projects.first { $0.id == id }?.name ?? "Toate"
    }

    private func pickLabel(_ text: String, selected: Bool) -> some View {
        Group {
            if selected {
                Label(text, systemImage: "checkmark")
            } else {
                Text(text)
            }
        }
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
