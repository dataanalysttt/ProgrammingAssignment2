import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportImportView: View {
    @Environment(\.modelContext) private var context

    @State private var jsonExportURL: URL?
    @State private var csvExportURL: URL?
    @State private var showingImporter = false
    @State private var statusMessage: String?
    @State private var statusIsError = false

    var body: some View {
        List {
            Section {
                Text("Everything Life Tracker stores lives only on this phone. Export it any time to back it up or move it — import reads that same file back in and merges by id, so importing twice is safe.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.ColorToken.secondaryText)
            }

            Section("Export") {
                Button("Export as JSON (full backup)") { export(asCSV: false) }
                if let jsonExportURL {
                    ShareLink(item: jsonExportURL) {
                        Label("Share JSON File", systemImage: "square.and.arrow.up")
                    }
                }
                Button("Export as CSV (for spreadsheets)") { export(asCSV: true) }
                if let csvExportURL {
                    ShareLink(item: csvExportURL) {
                        Label("Share CSV File", systemImage: "square.and.arrow.up")
                    }
                }
            }

            Section("Import") {
                Button("Import from JSON Backup") { showingImporter = true }
            } footer: {
                Text("Only Life Tracker's own JSON export format can be imported.")
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(statusIsError ? Theme.ColorToken.negative : Theme.ColorToken.positive)
                }
            }
        }
        .navigationTitle("Export & Import")
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                importJSON(from: url)
            case .failure(let error):
                statusMessage = error.localizedDescription
                statusIsError = true
            }
        }
    }

    private func export(asCSV: Bool) {
        do {
            if asCSV {
                csvExportURL = try DataExportImportService.exportCSV(context: context)
            } else {
                jsonExportURL = try DataExportImportService.exportJSON(context: context)
            }
            statusMessage = nil
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
            statusIsError = true
        }
    }

    private func importJSON(from url: URL) {
        do {
            try DataExportImportService.importJSON(from: url, context: context)
            statusMessage = "Import complete."
            statusIsError = false
        } catch {
            statusMessage = "Import failed: \(error.localizedDescription)"
            statusIsError = true
        }
    }
}
