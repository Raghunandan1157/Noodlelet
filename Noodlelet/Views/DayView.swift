import SwiftUI
import UIKit

struct DayView: View {
    @EnvironmentObject var store: LogStore

    // Group entries by hour
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
                ZStack(alignment: .leading) {
                    // Vertical Line
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .padding(.leading, 24) // Offset for timeline
                        .padding(.top, 20)

                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(sortedKeys, id: \.self) { hour in
                            VStack(alignment: .leading, spacing: 12) {
                                // Time Header
                                HStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 10, height: 10)
                                        .background(Circle().fill(Color(UIColor.systemBackground)).frame(width: 16, height: 16))
                                        .padding(.leading, 20)

                                    Text(hour, style: .time)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Spacer()
                                }

                                // Entries for this hour
                                if let entries = groupedEntries[hour] {
                                    ForEach(entries) { entry in
                                        HStack(alignment: .top) {
                                            Text(entry.timestamp, format: .dateTime.minute())
                                                .font(.caption2)
                                                .monospacedDigit()
                                                .foregroundColor(.secondary)
                                                .frame(width: 30, alignment: .trailing)
                                                .padding(.leading, 8)

                                            VStack(alignment: .leading) {
                                                Text(entry.snippet)
                                                    .font(.subheadline)
                                                    .padding(10)
                                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                                    .cornerRadius(8)
                                            }
                                        }
                                        .padding(.leading, 40) // Indent content
                                        .padding(.trailing, 16)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Timeline")
        }
    }
}
