import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            if store.history.isEmpty {
                ContentUnavailableView("还没有历史记录", systemImage: "clock.arrow.circlepath", description: Text("复制成功后，远端绝对路径会保存在这里。"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.history) { record in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Image(systemName: record.status == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(record.status == .success ? .green : .red)
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(record.remotePath)
                                        .font(.body.monospaced())
                                        .lineLimit(1)
                                        .textSelection(.enabled)
                                    Spacer()
                                    Text(Formatters.recordDate.string(from: record.date))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text("\(record.hostName)  \(record.message)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Button {
                                ClipboardImageService().copyString(record.remotePath)
                                store.statusMessage = "已复制历史路径"
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                            .help("复制路径")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Divider()

            HStack {
                StatusView()
                Spacer()
                Button("清空历史") {
                    store.clearHistory()
                }
                .disabled(store.history.isEmpty)
            }
            .padding()
            .background(.bar)
        }
        .navigationTitle("历史")
    }
}
