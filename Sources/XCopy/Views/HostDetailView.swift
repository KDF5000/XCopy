import SwiftUI

struct HostDetailView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editorMode: EditorMode?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("远端")
                    .font(.title2.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 8)

            if store.hosts.isEmpty {
                ContentUnavailableView("没有远端配置", systemImage: "server.rack", description: Text("添加一个远端后即可复制剪贴板图片。"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.hosts) { host in
                        HostRow(host: host, isSelected: store.selectedHostID == host.id)
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button("编辑") {
                                    editorMode = .edit(host)
                                }
                                Button("复制剪贴板图片") {
                                    store.selectedHostID = host.id
                                    Task { await store.copyClipboardImageToSelectedHost() }
                                }
                                Divider()
                                Button("删除", role: .destructive) {
                                    store.selectedHostID = host.id
                                    store.deleteSelectedHost()
                                }
                            }
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.14)) {
                                    store.selectedHostID = host.id
                                }
                            }
                            .onTapGesture(count: 2) {
                                withAnimation(.easeOut(duration: 0.14)) {
                                    store.selectedHostID = host.id
                                }
                                editorMode = .edit(host)
                            }
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            HStack {
                Spacer()

                Button {
                    if let host = store.selectedHost {
                        editorMode = .edit(host)
                    }
                } label: {
                    Label("编辑", systemImage: "slider.horizontal.3")
                }
                .disabled(store.selectedHost == nil)

                Button {
                    editorMode = .new(store.defaultHost())
                } label: {
                    Label("添加", systemImage: "plus")
                }

                Button {
                    store.deleteSelectedHost()
                } label: {
                    Label("删除", systemImage: "minus")
                }
                .disabled(store.selectedHost == nil)
            }
            .padding()
            .background(.bar)
        }
        .frame(minWidth: 620, minHeight: 460)
        .sheet(item: $editorMode) { mode in
            HostEditorSheet(mode: mode)
                .environmentObject(store)
        }
    }
}

private struct HostRow: View {
    let host: RemoteHost
    let isSelected: Bool
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "server.rack")
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(host.title)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(host.transport.label)  \(host.connectionLabel):\(host.normalizedDirectory)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(backgroundColor)
        )
        .animation(.easeOut(duration: 0.14), value: isSelected)
        .animation(.easeOut(duration: 0.10), value: isHovering)
        .onHover { isHovering = $0 }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.16)
        }
        if isHovering {
            return Color.primary.opacity(0.07)
        }
        return .clear
    }
}

enum EditorMode: Identifiable {
    case new(RemoteHost)
    case edit(RemoteHost)

    var id: UUID {
        switch self {
        case let .new(host), let .edit(host):
            host.id
        }
    }
}
