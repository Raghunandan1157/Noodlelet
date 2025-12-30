import Foundation

// Helper for the Extension to write logs without the full ObservableObject overhead
struct LogWriter {
    private let appGroupId = "group.noodlelet"
    private let fileName = "logs.jsonl"

    func append(_ entry: LogEntry) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("Extension Error: Could not access App Group container.")
            return
        }

        let url = containerURL.appendingPathComponent(fileName)

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
            print("Extension Failed to write entry: \(error)")
        }
    }
}
