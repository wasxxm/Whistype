import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \TranscriptionRecord.timestamp, order: .reverse)
    private var records: [TranscriptionRecord]

    @Environment(\.modelContext) private var modelContext
    @State private var showClearConfirmation = false

    var body: some View {
        Group {
            if records.isEmpty {
                emptyState
            } else {
                recordsList
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .confirmationDialog(
            "Delete all transcription history?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) { clearAll() }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No transcriptions yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Hold ⌥ Space to start recording")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var recordsList: some View {
        List {
            ForEach(records) { record in
                HistoryRow(record: record, onDelete: { deleteRecord(record) })
            }
            .onDelete(perform: deleteRecords)
        }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Clear All") {
                    showClearConfirmation = true
                }
                .disabled(records.isEmpty)
            }
        }
    }

    private func deleteRecord(_ record: TranscriptionRecord) {
        modelContext.delete(record)
    }

    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
    }

    private func clearAll() {
        for record in records {
            modelContext.delete(record)
        }
    }
}

private struct HistoryRow: View {
    let record: TranscriptionRecord
    let onDelete: () -> Void

    @State private var isHovering = false
    @State private var showCopied = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.text)
                    .font(.body)
                    .lineLimit(3)
                    .textSelection(.enabled)

                HStack(spacing: 4) {
                    Text(record.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    if record.durationSeconds > 0 {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(formatDuration(record.durationSeconds))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            if isHovering || showCopied {
                Button {
                    copyText()
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(showCopied ? .green : .secondary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }
        }
        .padding(.vertical, 4)
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button("Copy") { copyText() }
            Button("Delete", role: .destructive) { onDelete() }
        }
    }

    private func copyText() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(record.text, forType: .string)
        showCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            showCopied = false
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        }
        return "\(secs)s"
    }
}
