import SwiftUI

@main
struct PontajApp: App {
    @StateObject private var store = PontajStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
