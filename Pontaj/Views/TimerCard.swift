import SwiftUI

/// Cardul cu cronometrul / ora curenta. Are propriul timer, ca sa se actualizeze
/// doar acest card in fiecare secunda, nu tot ecranul (mai putin consum).
struct TimerCard: View {
    let active: PontajStore.ActiveSessionState?

    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            if let active {
                Text(active.projectName)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(Formatters.duration(now.timeIntervalSince(active.start)))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Label("Pornit la \(Formatters.timeOnly.string(from: active.start))",
                      systemImage: "play.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Niciun pontaj activ")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(Formatters.timeOnly.string(from: now))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(Formatters.dayHeader.string(from: now))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .onReceive(ticker) { now = $0 }
    }
}
