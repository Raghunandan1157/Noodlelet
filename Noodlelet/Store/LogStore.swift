import Foundation
import Combine

@MainActor
class LogStore: ObservableObject {
    @Published var entries: [LogEntry] = []

    // App Group ID - Replace with your actual App Group ID
    private let appGroupId = "group.noodlelet"
    private let fileName = "logs.jsonl"

    init() {
        loadEntries()
    }

    private var fileURL: URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("Error: Could not access App Group container. Make sure App Groups are enabled and the ID is correct.")
            // Fallback for simulator/testing without App Group entitlement
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
        }
        return containerURL.appendingPathComponent(fileName)
    }

    func loadEntries() {
        guard let url = fileURL else { return }

        do {
            if FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                let content = String(data: data, encoding: .utf8) ?? ""
                let lines = content.components(separatedBy: .newlines)

                var loadedEntries: [LogEntry] = []
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                for line in lines where !line.isEmpty {
                    if let lineData = line.data(using: .utf8),
                       let entry = try? decoder.decode(LogEntry.self, from: lineData) {
                        loadedEntries.append(entry)
                    }
                }

                // Sort by timestamp descending (newest first)
                self.entries = loadedEntries.sorted(by: { $0.timestamp > $1.timestamp })
            }
        } catch {
            print("Failed to load logs: \(error)")
        }
    }

    func addEntry(_ entry: LogEntry) {
        entries.insert(entry, at: 0)
        appendEntryToFile(entry)
    }

    func deleteEntry(at index: Int) {
        let entry = entries[index]
        entries.remove(at: index)
        saveAllEntries() // Re-write file since we can't easily remove one line from middle
    }

    func clearAll() {
        entries.removeAll()
        saveAllEntries()
    }

    func getJSONData() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(entries)
    }

    private func appendEntryToFile(_ entry: LogEntry) {
        guard let url = fileURL else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entry)
            if let string = String(data: data, encoding: .utf8) {
                let line = string + "\n"
                if !FileManager.default.fileExists(atPath: url.path) {
                    try line.write(to: url, atomically: true, encoding: .utf8)
                } else {
                    if let fileHandle = try? FileHandle(forWritingTo: url) {
                        fileHandle.seekToEndOfFile()
                        if let lineData = line.data(using: .utf8) {
                            fileHandle.write(lineData)
                        }
                        fileHandle.closeFile()
                    }
                }
            }
        } catch {
            print("Failed to append entry: \(error)")
        }
    }

    private func saveAllEntries() {
        guard let url = fileURL else { return }

        // Re-write the entire file (e.g., after deletion)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            var content = ""
            // Save in chronological order (oldest first) or reverse?
            // Usually logs are appended, so oldest at top.
            // But our `entries` array is newest first.
            // Let's write them so that appending still makes sense (oldest first in file).

            for entry in entries.reversed() {
                let data = try encoder.encode(entry)
                if let string = String(data: data, encoding: .utf8) {
                    content += string + "\n"
                }
            }

            try content.write(to: url, atomically: true, encoding: .utf8)

        } catch {
            print("Failed to save all entries: \(error)")
        }
    }
}
