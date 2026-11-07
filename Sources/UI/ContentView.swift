import SwiftUI

/// Root view — three tabs, matching the original desktop application:
/// cracker, calculator, about.
struct ContentView: View {
    @State private var selection: Int = 0

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
