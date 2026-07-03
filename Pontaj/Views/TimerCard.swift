import SwiftUI

/// Cardul cu cronometrul / ora curenta. Are propriul timer izolat.
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

                Text(Formatters.duration(active.elapsed(at: now)))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(active.isPaused ? .orange : .primary)

                if active.isPaused {
                    Label("În pauză", systemImage: "pause.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else {
                    Label("Pornit la \(Formatters.timeOnly.string(from: active.start))",
                          systemImage: "play.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
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
        .overlay {
            if active?.isPaused == true {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.orange.opacity(0.4), lineWidth: 2)
            }
        }
        .onReceive(ticker) { now = $0 }
    }
}
