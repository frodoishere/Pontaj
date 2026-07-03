import SwiftUI

@main
struct PontajApp: App {
    @StateObject private var store = PontajStore()

    init() {
        NotificationManager.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
