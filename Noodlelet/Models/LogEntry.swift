import Foundation

struct LogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let snippet: String
    let appHint: String?
    let source: String
    let confidence: Double?
    let tags: [String]?

    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         snippet: String,
         appHint: String? = nil,
         source: String = "broadcast",
         confidence: Double? = nil,
         tags: [String]? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.snippet = String(snippet.prefix(200)) // Max 200 chars
        self.appHint = appHint
        self.source = source
        self.confidence = confidence
        self.tags = tags
    }
}
