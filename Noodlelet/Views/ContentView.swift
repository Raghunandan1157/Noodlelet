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
                    Label("Day", systemImage: "calendar")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
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
