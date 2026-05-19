import SwiftUI

struct HostEditorSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: RemoteHost
    private let mode: EditorMode

    private let labelWidth: CGFloat = 92

    init(mode: EditorMode) {
        self.mode = mode
        switch mode {
        case let .new(host), let .edit(host):
            _draft = State(initialValue: host)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.title2.bold())
                Spacer()
            }
            .padding([.horizontal, .top], 24)
            .padding(.bottom, 8)

            GeometryReader { proxy in
                let compact = proxy.size.width < 560

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        formContent(compact: compact)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("保存") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(.bar)
        }
        .frame(minWidth: 520, idealWidth: 720, minHeight: 520, idealHeight: 680)
    }

    private var title: String {
        switch mode {
        case .new:
            "添加远端"
        case .edit:
            "编辑远端"
        }
    }

    @ViewBuilder
    private func formContent(compact: Bool) -> some View {
        editorSection("连接") {
            adaptiveRow("名称", compact: compact) {
                TextField("示例服务器", text: $draft.name)
                    .textFieldStyle(.roundedBorder)
            }

            adaptiveRow("用户", compact: compact) {
                TextField("user", text: $draft.user)
                    .textFieldStyle(.roundedBorder)
            }

            adaptiveRow("Host", compact: compact) {
                TextField("example.com", text: $draft.host)
                    .textFieldStyle(.roundedBorder)
            }

            adaptiveRow("端口", compact: compact) {
                HStack {
                    TextField("22", value: $draft.port, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: compact ? nil : 110)
                    Stepper("端口", value: $draft.port, in: 1...65535)
                        .labelsHidden()
                }
            }

            adaptiveRow("远端目录", compact: compact) {
                TextField("/tmp", text: $draft.directory)
                    .textFieldStyle(.roundedBorder)
            }
        }

        editorSection("传输") {
            Picker("复制方式", selection: $draft.transport) {
                ForEach(RemoteHost.Transport.allCases) { transport in
                    Text(transport.label).tag(transport)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: compact ? .infinity : 360, alignment: .leading)

            if draft.transport == .custom {
                adaptiveRow("命令模板", compact: compact) {
                    TextField("命令模板", text: $draft.customCommand, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                customCommandHelp
            }
        }

        editorSection("输出") {
            adaptiveRow("远端路径预览", compact: compact) {
                Text(draft.remotePath(fileName: "xcopy-20260519-153000-000.png"))
                    .font(.body.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var customCommandHelp: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("自定义命令会在本机执行。命令退出码为 0 时视为复制成功。")
            Text("常用占位符：{local} 本地图片文件，{remote} 远端绝对路径，{connection} user@host，{port} SSH 端口。")

            VStack(alignment: .leading, spacing: 2) {
                Text("示例")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("scp -P {port} {local} {connection}:{remote}")
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() {
        switch mode {
        case .new:
            store.addHost(draft)
        case .edit:
            store.updateHost(draft)
        }
        dismiss()
    }

    @ViewBuilder
    private func editorSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func adaptiveRow<Content: View>(_ title: String, compact: Bool, @ViewBuilder content: () -> Content) -> some View {
        if compact {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.callout.weight(.semibold))
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .frame(width: labelWidth, alignment: .leading)
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
