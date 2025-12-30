import SwiftUI
import UIKit

struct LiveFeedView: View {
    @EnvironmentObject var store: LogStore

    // Group logs by Day
    var groupedEntries: [Date: [LogEntry]] {
        Dictionary(grouping: store.entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }
    }

    var sortedDates: [Date] {
        groupedEntries.keys.sorted(by: >)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if store.entries.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No logs yet")
                                .font(.title2)
                                .fontWeight(.medium)
                            Text("Start the Broadcast Extension from Control Center to begin logging.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(sortedDates, id: \.self) { date in
                            Section(header:
                                HStack {
                                    Text(date, style: .date)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                            ) {
                                ForEach(groupedEntries[date] ?? []) { entry in
                                    LogRowView(entry: entry)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemGroupedBackground)) // Light gray background
            .navigationTitle("Noodlelet")
            .refreshable {
                store.loadEntries()
            }
        }
    }
}
