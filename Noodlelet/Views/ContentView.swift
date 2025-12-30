import SwiftUI
import ReplayKit

struct ContentView: View {
    @StateObject private var store = LogStore()

    var body: some View {
        TabView {
            LiveFeedView()
                .tabItem {
                    Label("Live", systemImage: "recordingtape")
                }

            DayView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar.day.timeline.left")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .environmentObject(store)
        .onAppear {
            // Refresh logs when app becomes active
            NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
                store.loadEntries()
            }
        }
    }
}
