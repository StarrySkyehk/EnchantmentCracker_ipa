import SwiftUI

@main
struct EnchantmentCrackerApp: App {
    @StateObject private var model = CrackerModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
        }
    }
}
