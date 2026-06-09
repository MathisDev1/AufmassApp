import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ScanView()
                    .navigationTitle("Scan")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Scan", systemImage: "camera.viewfinder")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Einstellungen", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    ContentView()
}
