import SwiftUI

struct SearchView: View {
    @EnvironmentObject var store: LogStore
    @State private var searchText = ""

    var filteredEntries: [LogEntry] {
        if searchText.isEmpty {
            return store.entries
        } else {
            return store.entries.filter { entry in
                entry.snippet.localizedCaseInsensitiveContains(searchText) ||
                (entry.appHint?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        NavigationView {
            List(filteredEntries) { entry in
                VStack(alignment: .leading) {
                    Text(entry.snippet)
                    HStack {
                        Text(entry.timestamp, style: .date)
                        Text(entry.timestamp, style: .time)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .searchable(text: $searchText, prompt: "Search memories...")
            .navigationTitle("Search")
        }
    }
}
