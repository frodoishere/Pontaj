import SwiftUI

struct SummaryView: View {
    let summary: PeriodSummary
    let normalDaily: TimeInterval
    var billingTotal: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Rezumat", systemImage: "chart.bar.fill")
                    .font(.headline)
                Spacer()
                Text("\(summary.dayCount) \(summary.dayCount == 1 ? "zi" : "zile")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                metric(title: "Normal",
                       value: Formatters.durationShort(summary.normal),
                       color: .green,
                       icon: "checkmark.circle.fill")
                metric(title: "Suplimentar",
                       value: Formatters.durationShort(summary.overtime),
                       color: .orange,
                       icon: "plus.circle.fill")
            }

            HStack {
                Text("Total")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Formatters.durationShort(summary.total))
                    .fontWeight(.semibold)
            }
            .font(.subheadline)

            if billingTotal > 0 {
                HStack {
                    Label("Facturabil", systemImage: "banknote")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Formatters.money(billingTotal))
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                .font(.subheadline)
            }

            Text("Prag program normal: \(Formatters.hoursMinutes(normalDaily)) / zi")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if summary.perProject.count > 1 {
                Divider()
                VStack(spacing: 8) {
                    ForEach(summary.perProject) { item in
                        HStack {
                            Text(item.name).lineLimit(1)
                            Spacer()
                            Text(Formatters.durationShort(item.total))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func metric(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.12))
        )
    }
}
