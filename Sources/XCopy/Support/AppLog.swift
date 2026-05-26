import Foundation
import OSLog

enum AppLog {
    private static var subsystem: String {
        Bundle.main.bundleIdentifier ?? "com.local.XCopy"
    }

    static let clipboard = Logger(subsystem: subsystem, category: "clipboard")
    static let shortcut = Logger(subsystem: subsystem, category: "shortcut")
    static let session = Logger(subsystem: subsystem, category: "session")
    static let shell = Logger(subsystem: subsystem, category: "shell-integration")
    static let transfer = Logger(subsystem: subsystem, category: "transfer")
}
