import SwiftUI

struct DayView: View {
    @EnvironmentObject var store: LogStore

    // Group entries by hour for the timeline
    var groupedEntries: [Date: [LogEntry]] {
        Dictionary(grouping: store.entries) { entry in
            Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: entry.timestamp),
                                  minute: 0,
                                  second: 0,
                                  of: entry.timestamp) ?? entry.timestamp
        }
    }

    var sortedKeys: [Date] {
        groupedEntries.keys.sorted(by: >)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(sortedKeys, id: \.self) { hour in
                        VStack(alignment: .leading) {
                            Text(hour, style: .time)
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top)

                            Divider()
                                .padding(.leading)

                            if let entries = groupedEntries[hour] {
                                ForEach(entries) { entry in
                                    HStack(alignment: .top) {
                                        Text(entry.timestamp, format: .dateTime.minute())
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .frame(width: 30, alignment: .trailing)

                                        VStack(alignment: .leading) {
                                            Text(entry.snippet)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 2)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Timeline")
        }
    }
}
