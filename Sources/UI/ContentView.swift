import SwiftUI

/// Root view — three tabs, matching the original desktop application:
/// cracker, calculator, about.
struct ContentView: View {
    /// Debug only: `-tab2` / `-tab3` launch arguments select a tab (used by the
    /// simulator smoke test so every screen can be screenshotted).
    private static var initialTab: Int {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-tab2") { return 1 }
        if args.contains("-tab3") { return 2 }
        return 0
    }

    @State private var selection: Int = ContentView.initialTab

    var body: some View {
        TabView(selection: $selection) {
            CrackerView()
                .tabItem {
                    Label(L.tabCracker, systemImage: "hammer.fill")
                }
                .tag(0)

            CalculatorView()
                .tabItem {
                    Label(L.tabCalculator, systemImage: "wand.and.stars")
                }
                .tag(1)

            AboutView()
                .tabItem {
                    Label(L.tabAbout, systemImage: "info.circle.fill")
                }
                .tag(2)
        }
        .tint(Theme.accentGreen)
        .mcKeyboardToolbar()
    }
}
