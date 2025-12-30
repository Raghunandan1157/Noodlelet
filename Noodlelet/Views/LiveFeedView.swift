import SwiftUI

struct LiveFeedView: View {
    @EnvironmentObject var store: LogStore

    var body: some View {
        NavigationView {
            List {
                ForEach(store.entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let hint = entry.appHint {
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(hint)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }

                            Spacer()
                        }

                        Text(entry.snippet)
                            .font(.body)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        store.deleteEntry(at: index)
                    }
                }
            }
            .refreshable {
                store.loadEntries()
            }
            .navigationTitle("Live Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Placeholder for Start/Stop Broadcast
                    // Note: You cannot programmatically start broadcast from the main app without user interaction via RPSystemBroadcastPickerView
                    // We will add a picker view here later or assume user knows to use Control Center.
                    // For better UX, we can add a help button or status.
                    Text("Always-On")
                        .font(.caption)
                        .padding(4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
    }
}
