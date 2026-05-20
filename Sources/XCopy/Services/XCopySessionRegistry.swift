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
        guard !normalizedTTY.isEmpty else { return nil }

        let url = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".xcopy/sessions/by-tty", isDirectory: true)
            .appendingPathComponent("\(normalizedTTY).json")

        guard let data = try? Data(contentsOf: url),
              let session = try? JSONDecoder().decode(TTYSession.self, from: data) else {
            return nil
        }

        let trimmed = session.target.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
