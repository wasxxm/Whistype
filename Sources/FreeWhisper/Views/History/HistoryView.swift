import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \TranscriptionRecord.timestamp, order: .reverse)
    private var records: [TranscriptionRecord]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if records.isEmpty {
                emptyState
            } else {
                recordsList
            }
        }
        .frame(minWidth: 400, minHeight: 300)
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
            Text("Press ⌥ Space to start recording")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var recordsList: some View {
        List {
            ForEach(records) { record in
                HistoryRow(record: record)
            }
            .onDelete(perform: deleteRecords)
        }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Clear All") {
                    clearAll()
                }
                .disabled(records.isEmpty)
            }
        }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.text)
                .font(.body)
                .lineLimit(3)

            HStack {
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
        .padding(.vertical, 4)
        .contextMenu {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(record.text, forType: .string)
            }
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
