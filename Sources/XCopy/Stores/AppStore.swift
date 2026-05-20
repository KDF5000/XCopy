import AppKit
import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var hosts: [RemoteHost] = [] {
        didSet {
            saveHosts()
            pasteShortcutMonitor.updateHosts(hosts)
        }
    }

    @Published var history: [TransferRecord] = [] {
        didSet { saveHistory() }
    }

    @Published var selectedHostID: RemoteHost.ID? {
        didSet { saveSelectedHostID() }
    }

    @Published var autoUploadEnabled = false {
        didSet {
            guard !isLoading else { return }
            defaults.set(autoUploadEnabled, forKey: autoUploadEnabledKey)
            configurePasteShortcutMonitor(promptForPermission: true)
        }
    }

    @Published var isTransferring = false
    @Published var statusMessage = "准备就绪"
    @Published var lastError: String?
    @Published var needsAccessibilityPermission = false
    @Published var transientStatusMessage: String?
    @Published var pasteShortcut = PasteShortcut.defaultShortcut {
        didSet {
            guard !isLoading else { return }
            savePasteShortcut()
            pasteShortcutMonitor.updateShortcut(pasteShortcut)
        }
    }

    private let clipboardService = ClipboardImageService()
    private let remoteCopyService = RemoteCopyService()
    private let pasteShortcutMonitor = GlobalPasteShortcutMonitor()
    private let shellIntegrationInstaller = ShellIntegrationInstaller()
    private let defaults = UserDefaults.standard

    private let hostsKey = "hosts"
    private let historyKey = "history"
    private let selectedHostIDKey = "selectedHostID"
    private let autoUploadEnabledKey = "autoUploadEnabled"
    private let didRunFirstLaunchSetupKey = "didRunFirstLaunchSetup"
    private let shellIntegrationVersionKey = "shellIntegrationVersion"
    private let pasteShortcutKey = "pasteShortcut"
    private let currentShellIntegrationVersion = 2
    private var isLoading = false

    init() {
        load()
        runFirstLaunchSetupIfNeeded()
    }

    var selectedHost: RemoteHost? {
        guard let selectedHostID else { return hosts.first }
        return hosts.first { $0.id == selectedHostID } ?? hosts.first
    }

    var lastSuccessfulPath: String? {
        history.first { $0.status == .success }?.remotePath
    }

    func addHost() {
        addHost(defaultHost())
    }

    func addHost(_ host: RemoteHost) {
        hosts.insert(host, at: 0)
        selectedHostID = host.id
    }

    func defaultHost() -> RemoteHost {
        RemoteHost(
            name: "新的远端",
            user: NSUserName(),
            host: "example.com",
            directory: "/tmp"
        )
    }

    func deleteSelectedHost() {
        guard let selectedHostID else { return }
        hosts.removeAll { $0.id == selectedHostID }
        self.selectedHostID = hosts.first?.id
    }

    func updateHost(_ host: RemoteHost) {
        guard let index = hosts.firstIndex(where: { $0.id == host.id }) else { return }
        hosts[index] = host
    }

    func copyClipboardImageToSelectedHost() async -> Bool {
        guard let host = selectedHost else {
            lastError = "请先添加一个远端配置。"
            statusMessage = "缺少远端配置"
            return false
        }

        isTransferring = true
        lastError = nil
        statusMessage = "正在读取剪贴板图片..."

        do {
            let localImage = try clipboardService.writeClipboardImageToTemporaryFile()
            let remotePath = host.remotePath(fileName: localImage.fileName)
            statusMessage = "正在复制到 \(host.title)..."

            try await remoteCopyService.copy(localFileURL: localImage.url, fileName: localImage.fileName, remotePath: remotePath, host: host)

            clipboardService.copyString(remotePath)
            prependHistory(
                TransferRecord(
                    hostName: host.title,
                    fileName: localImage.fileName,
                    remotePath: remotePath,
                    status: .success,
                    message: "已复制路径到剪贴板"
                )
            )
            statusMessage = "已复制到远端，并将路径写入剪贴板"
            isTransferring = false
            return true
        } catch {
            let message = error.localizedDescription
            lastError = message
            statusMessage = "复制失败"
            prependHistory(
                TransferRecord(
                    hostName: host.title,
                    fileName: "clipboard-image",
                    remotePath: host.normalizedDirectory,
                    status: .failed,
                    message: message
                )
            )
        }

        isTransferring = false
        return false
    }

    func copyClipboardImage(to hostID: RemoteHost.ID) async -> Bool {
        guard hosts.contains(where: { $0.id == hostID }) else {
            statusMessage = "当前窗口没有匹配的远端"
            return false
        }

        selectedHostID = hostID
        return await copyClipboardImageToSelectedHost()
    }

    func clearHistory() {
        history.removeAll()
    }

    func copyRemoteDirectoryToClipboard(for host: RemoteHost) {
        clipboardService.copyString("\(host.connectionLabel):\(host.normalizedDirectory)")
        showTransientStatus("已复制远端路径")
        lastError = nil
    }

    func installShellIntegration() {
        installShellIntegration(updateStatus: true)
    }

    @discardableResult
    private func installShellIntegration(updateStatus: Bool) -> Bool {
        do {
            try shellIntegrationInstaller.install()
            defaults.set(currentShellIntegrationVersion, forKey: shellIntegrationVersionKey)
            if updateStatus {
                statusMessage = "SSH 集成已安装，重新打开终端后生效"
                lastError = nil
            }
            return true
        } catch {
            if updateStatus {
                statusMessage = "SSH 集成安装失败"
                lastError = error.localizedDescription
            }
            return false
        }
    }

    func refreshPasteTriggerStatus() {
        guard autoUploadEnabled else { return }
        configurePasteShortcutMonitor(promptForPermission: false)
    }

    func requestPasteTriggerPermissionIfNeeded() {
        guard autoUploadEnabled else { return }
        configurePasteShortcutMonitor(promptForPermission: true)
    }

    func updatePasteShortcut(_ shortcut: PasteShortcut) {
        pasteShortcut = shortcut
        showTransientStatus("已更新快捷键")
    }

    func rejectPasteShortcutRecording() {
        showTransientStatus("快捷键需包含 ⌘、⌃ 或 ⌥")
    }

    private func prependHistory(_ record: TransferRecord) {
        history.insert(record, at: 0)
        if history.count > 50 {
            history = Array(history.prefix(50))
        }
    }

    private func load() {
        isLoading = true
        hosts = decode([RemoteHost].self, forKey: hostsKey) ?? [
            RemoteHost(name: "示例服务器", user: NSUserName(), host: "example.com", directory: "/tmp")
        ]
        history = decode([TransferRecord].self, forKey: historyKey) ?? []

        if let selectedIDString = defaults.string(forKey: selectedHostIDKey),
           let selectedID = UUID(uuidString: selectedIDString),
           hosts.contains(where: { $0.id == selectedID }) {
            selectedHostID = selectedID
        } else {
            selectedHostID = hosts.first?.id
        }

        pasteShortcutMonitor.updateHosts(hosts)
        pasteShortcut = decode(PasteShortcut.self, forKey: pasteShortcutKey) ?? .defaultShortcut
        pasteShortcutMonitor.updateShortcut(pasteShortcut)
        if defaults.object(forKey: autoUploadEnabledKey) == nil {
            autoUploadEnabled = true
            defaults.set(true, forKey: autoUploadEnabledKey)
        } else {
            autoUploadEnabled = defaults.bool(forKey: autoUploadEnabledKey)
        }
        isLoading = false

        if autoUploadEnabled {
            configurePasteShortcutMonitor(promptForPermission: false)
        }
    }

    private func runFirstLaunchSetupIfNeeded() {
        let isFirstLaunch = !defaults.bool(forKey: didRunFirstLaunchSetupKey)

        if isFirstLaunch {
            defaults.set(true, forKey: didRunFirstLaunchSetupKey)
            defaults.set(true, forKey: autoUploadEnabledKey)
            autoUploadEnabled = true
        }

        if isFirstLaunch || defaults.integer(forKey: shellIntegrationVersionKey) < currentShellIntegrationVersion {
            let installed = installShellIntegration(updateStatus: false)
            if !installed {
                statusMessage = "SSH 集成安装失败"
                lastError = "无法自动安装 SSH 集成。"
            }
        }

        if isFirstLaunch {
            configurePasteShortcutMonitor(promptForPermission: true)
        }
    }

    private func configurePasteShortcutMonitor(promptForPermission: Bool) {
        if autoUploadEnabled {
            if !pasteShortcutMonitor.hasAccessibilityPermission, promptForPermission {
                _ = pasteShortcutMonitor.start(promptForPermission: true) { _ in }
            }

            pasteShortcutMonitor.updateHosts(hosts)
            let started = pasteShortcutMonitor.start(promptForPermission: false) { [weak self] hostID in
                Task { @MainActor [weak self] in
                    await self?.handlePasteShortcut(hostID: hostID)
                }
            }

            if started {
                needsAccessibilityPermission = false
                statusMessage = "准备就绪"
                lastError = nil
            } else {
                needsAccessibilityPermission = true
                statusMessage = "需要开启辅助功能权限"
                lastError = "请在系统设置中允许 XCopy 使用辅助功能/输入监听权限，然后重新开启粘贴触发。"
            }
        } else {
            pasteShortcutMonitor.stop()
            needsAccessibilityPermission = false
            statusMessage = "粘贴触发已关闭"
        }
    }

    private func handlePasteShortcut(hostID: RemoteHost.ID) async {
        guard autoUploadEnabled, !isTransferring, clipboardService.hasImage() else { return }
        let success = await copyClipboardImage(to: hostID)
        if success {
            pasteShortcutMonitor.pasteIntoFocusedApp()
        }
    }

    private func showTransientStatus(_ message: String) {
        transientStatusMessage = message
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            if self?.transientStatusMessage == message {
                self?.transientStatusMessage = nil
            }
        }
    }

    private func saveHosts() {
        encode(hosts, forKey: hostsKey)
    }

    private func saveHistory() {
        encode(history, forKey: historyKey)
    }

    private func saveSelectedHostID() {
        defaults.set(selectedHostID?.uuidString, forKey: selectedHostIDKey)
    }

    private func savePasteShortcut() {
        encode(pasteShortcut, forKey: pasteShortcutKey)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
