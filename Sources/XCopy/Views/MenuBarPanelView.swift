import AppKit
import SwiftUI

struct MenuBarPanelView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    @State private var isRecordingShortcut = false
    @State private var shortcutMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Divider()

            statusSection

            Divider()

            remoteSection

            Divider()

            quitAction
        }
        .padding(14)
        .frame(width: 330)
        .overlay(alignment: .bottom) {
            if let message = store.transientStatusMessage {
                toast(message)
                    .padding(.bottom, 56)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeOut(duration: 0.16), value: store.transientStatusMessage)
        .onAppear {
            store.refreshPasteTriggerStatus()
        }
        .onDisappear {
            stopShortcutRecording()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            AppIconView(pointSize: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text("XCopy")
                    .font(.headline)
                Text("远端图片路径粘贴")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: shouldShowStatusLine ? 4 : 0) {
            Button {
                startShortcutRecording()
            } label: {
                HStack {
                    Label("快捷键", systemImage: "keyboard")
                        .font(.body)
                    Spacer()
                    if isRecordingShortcut {
                        Text("按下快捷键")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ShortcutDisplay(shortcut: store.pasteShortcut)
                    }
                }
            }
            .buttonStyle(HoverButtonStyle())
            .help("点击修改快捷键")

            if shouldShowStatusLine {
                statusLine
            }
        }
    }

    private var shouldShowStatusLine: Bool {
        store.isTransferring || store.lastError != nil || store.needsAccessibilityPermission
    }

    private var statusLine: some View {
        HStack(spacing: 8) {
            if store.isTransferring {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Text(statusText)
                .font(.caption)
                .foregroundColor(store.lastError == nil && !store.needsAccessibilityPermission ? .secondary : .orange)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if store.needsAccessibilityPermission {
                Spacer()
                Button {
                    store.requestPasteTriggerPermissionIfNeeded()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .regular))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(HoverButtonStyle(cornerRadius: 5, horizontalPadding: 3, verticalPadding: 3))
                .help("重新检查权限")
            }
        }
        .padding(.top, 1)
        .padding(.leading, 26)
    }

    private var statusText: String {
        if store.isTransferring {
            store.statusMessage
        } else if store.needsAccessibilityPermission {
            "需要开启辅助功能权限"
        } else if store.lastError != nil {
            "复制失败"
        } else {
            ""
        }
    }

    private func toast(_ message: String) -> some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }

    private var remoteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text("远端")
                    .font(.body)
                Spacer()
                Button {
                    openConfigurationWindow()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .regular))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(HoverButtonStyle(cornerRadius: 6))
                .help("远端设置")
            }

            if store.hosts.isEmpty {
                Button {
                    openConfigurationWindow()
                } label: {
                    Label("添加远端...", systemImage: "plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(HoverButtonStyle())
            } else {
                ForEach(store.hosts) { host in
                    RemoteMenuRow(host: host) {
                        store.copyRemoteDirectoryToClipboard(for: host)
                    }
                }
            }
        }
    }

    private var quitAction: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("退出", systemImage: "power")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(HoverButtonStyle())
        .foregroundStyle(.secondary)
    }

    private func openConfigurationWindow() {
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "hosts")
        NSApp.activate(ignoringOtherApps: true)
        dismiss()
    }

    private func startShortcutRecording() {
        guard !isRecordingShortcut else { return }
        isRecordingShortcut = true

        shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                stopShortcutRecording()
                return nil
            }

            if let shortcut = PasteShortcut.from(event: event) {
                store.updatePasteShortcut(shortcut)
            } else {
                store.rejectPasteShortcutRecording()
            }

            stopShortcutRecording()
            return nil
        }
    }

    private func stopShortcutRecording() {
        if let shortcutMonitor {
            NSEvent.removeMonitor(shortcutMonitor)
        }
        shortcutMonitor = nil
        isRecordingShortcut = false
    }
}

private struct ShortcutDisplay: View {
    let shortcut: PasteShortcut

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(shortcut.displayParts.enumerated()), id: \.offset) { _, part in
                Text(part)
            }
        }
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
    }
}

private struct HoverButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 7
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        HoverButton(
            configuration: configuration,
            cornerRadius: cornerRadius,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding
        )
    }

    private struct HoverButton: View {
        let configuration: ButtonStyle.Configuration
        let cornerRadius: CGFloat
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        @State private var isHovering = false

        var body: some View {
            configuration.label
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(background)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .onHover { isHovering = $0 }
        }

        private var background: some View {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(isHovering || configuration.isPressed ? Color.primary.opacity(0.08) : Color.clear)
        }
    }
}

private struct RemoteMenuRow: View {
    let host: RemoteHost
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.16))
                    Image(systemName: "server.rack")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(host.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\(host.connectionLabel):\(host.normalizedDirectory)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(HoverButtonStyle())
        .help("复制远端路径")
    }
}
