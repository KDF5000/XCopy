import Foundation

struct RemoteHost: Identifiable, Codable, Equatable {
    enum Transport: String, Codable, CaseIterable, Identifiable {
        case scp
        case rsync
        case custom

        var id: String { rawValue }

        var label: String {
            switch self {
            case .scp: "scp"
            case .rsync: "rsync"
            case .custom: "自定义"
            }
        }
    }

    var id: UUID
    var name: String
    var user: String
    var host: String
    var port: Int
    var directory: String
    var transport: Transport
    var customCommand: String

    init(
        id: UUID = UUID(),
        name: String,
        user: String,
        host: String,
        port: Int = 22,
        directory: String,
        transport: Transport = .scp,
        customCommand: String = ""
    ) {
        self.id = id
        self.name = name
        self.user = user
        self.host = host
        self.port = port
        self.directory = directory
        self.transport = transport
        self.customCommand = customCommand
    }

    var title: String {
        name.isEmpty ? host : name
    }

    var connectionLabel: String {
        if user.isEmpty {
            return host
        }
        return "\(user)@\(host)"
    }

    var matchTokens: [String] {
        strictMatchTokens + looseMatchTokens
    }

    var strictMatchTokens: [String] {
        [
            host,
            connectionLabel
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        .filter { !$0.isEmpty }
    }

    var looseMatchTokens: [String] {
        var tokens = [
            name
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        .filter { !$0.isEmpty }

        if host.contains("."), !host.isIPAddress {
            tokens.append(host.components(separatedBy: ".").first ?? "")
        }

        return Array(Set(tokens.filter { !$0.isEmpty }))
    }

    var normalizedDirectory: String {
        let trimmed = directory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "." }
        return trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
    }

    func remotePath(fileName: String) -> String {
        "\(normalizedDirectory)/\(fileName)"
    }
}

private extension String {
    var isIPAddress: Bool {
        let parts = split(separator: ".")
        guard parts.count == 4 else { return false }

        return parts.allSatisfy { part in
            guard let value = Int(part), value >= 0, value <= 255 else {
                return false
            }
            return String(part) == String(value)
        }
    }
}
