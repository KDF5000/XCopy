import SwiftUI

struct StatusView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        HStack(spacing: 8) {
            if store.isTransferring {
                ProgressView()
                    .controlSize(.small)
            }

            Text(store.statusMessage)
                .font(.caption)
                .foregroundColor(store.lastError == nil ? .secondary : .red)
                .lineLimit(1)
        }
    }
}
