import Foundation

struct XCopySessionRegistry {
    private struct TTYSession: Decodable {
        let target: String
        let tty: String
        let pid: Int
        let startedAt: Int
    }

    func target(forTTY tty: String) -> String? {
        let normalizedTTY = tty
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/dev/", with: "")
        guard !normalizedTTY.isEmpty else {
            AppLog.session.error("empty tty passed to session registry")
            return nil
        }

        let url = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".xcopy/sessions/by-tty", isDirectory: true)
            .appendingPathComponent("\(normalizedTTY).json")

        guard FileManager.default.fileExists(atPath: url.path) else {
            AppLog.session.error("session registry file missing path=\(url.path, privacy: .public)")
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            AppLog.session.error("could not read session registry file path=\(url.path, privacy: .public)")
            return nil
        }

        guard let session = try? JSONDecoder().decode(TTYSession.self, from: data) else {
            AppLog.session.error("could not decode session registry file path=\(url.path, privacy: .public)")
            return nil
        }

        let trimmed = session.target.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            AppLog.session.error("session registry target is empty path=\(url.path, privacy: .public)")
            return nil
        }

        return trimmed
    }
}
