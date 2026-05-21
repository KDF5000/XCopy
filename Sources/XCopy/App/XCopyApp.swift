import SwiftUI
import AppKit

@main
struct XCopyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanelView()
                .environmentObject(store)
        } label: {
            MenuBarIconView(pointSize: 16)
        }
        .menuBarExtraStyle(.window)

        Window("远端配置", id: "hosts") {
            HostDetailView()
                .environmentObject(store)
                .background {
                    HostConfigurationWindowObserver()
                }
        }
        .defaultSize(width: 720, height: 520)
        .commands {
            CommandMenu("XCopy") {
                Button("打开远端配置") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

private struct HostConfigurationWindowObserver: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = HostConfigurationWindowProbeView(frame: .zero)
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? HostConfigurationWindowProbeView else { return }
        view.coordinator = context.coordinator
        context.coordinator.observeWindow(view.window)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator: NSObject {
        private weak var observedWindow: NSWindow?

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func observeWindow(_ window: NSWindow?) {
            guard let window, window !== observedWindow else { return }

            if let observedWindow {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSWindow.willCloseNotification,
                    object: observedWindow
                )
            }

            observedWindow = window
            NSApp.setActivationPolicy(.regular)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowWillClose),
                name: NSWindow.willCloseNotification,
                object: window,
            )
        }

        @objc private func windowWillClose() {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

private final class HostConfigurationWindowProbeView: NSView {
    weak var coordinator: HostConfigurationWindowObserver.Coordinator?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        coordinator?.observeWindow(window)
    }
}
