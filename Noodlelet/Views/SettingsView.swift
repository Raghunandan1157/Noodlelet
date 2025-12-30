import SwiftUI
import UniformTypeIdentifiers

struct JSONFile: FileDocument {
    static var readableContentTypes = [UTType.json]
    var text = ""

    init(initialText: String = "") {
        text = initialText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: LogStore
    @State private var showingExporter = false
    @State private var jsonDocument: JSONFile?
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Data Management")) {
                    Button {
                        prepareExport()
                    } label: {
                        Label("Export Logs to JSON", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("Clear All Logs", systemImage: "trash")
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    Text("Noodlelet uses ReplayKit to capture text from your screen securely. All processing happens on-device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .fileExporter(isPresented: $showingExporter, document: jsonDocument, contentType: .json, defaultFilename: "noodlelet_logs.json") { result in
                switch result {
                case .success(let url):
                    print("Saved to \(url)")
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            .alert("Are you sure?", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    store.clearAll()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func prepareExport() {
        if let data = store.getJSONData(), let jsonString = String(data: data, encoding: .utf8) {
            jsonDocument = JSONFile(initialText: jsonString)
            showingExporter = true
        }
    }
}
