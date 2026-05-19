import Foundation

struct XCopySessionRegistry {
    func target(for token: String) -> String? {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedToken.isEmpty else { return nil }

        let url = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".xcopy/sessions", isDirectory: true)
            .appendingPathComponent(normalizedToken)

        guard let target = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let trimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
