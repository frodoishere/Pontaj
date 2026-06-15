import SwiftUI
import UIKit

/// Element identificabil folosit pentru a prezenta share sheet-ul.
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Adaptor peste UIActivityViewController pentru a partaja fisiere (ex: CSV).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
