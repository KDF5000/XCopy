import Foundation

enum RemoteCopyError: LocalizedError {
    case invalidHost
    case invalidCustomCommand
    case processFailed(command: String, output: String)

    var errorDescription: String? {
        switch self {
        case .invalidHost:
            "远端 host 不能为空。"
        case .invalidCustomCommand:
            "自定义命令不能为空。可用占位符：{local}、{remote}、{fileName}、{host}、{user}、{port}、{directory}。"
        case let .processFailed(command, output):
            "命令执行失败：\(command)\n\(output)"
        }
    }
}

struct RemoteCopyService {
    func copy(localFileURL: URL, fileName: String, remotePath: String, host: RemoteHost) async throws {
        guard !host.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RemoteCopyError.invalidHost
        }

        let command = try commandLine(localFileURL: localFileURL, fileName: fileName, remotePath: remotePath, host: host)
        AppLog.transfer.info("remote copy command prepared transport=\(host.transport.rawValue, privacy: .public) command=\(command, privacy: .public)")
        try await run(command)
    }

    private func commandLine(localFileURL: URL, fileName: String, remotePath: String, host: RemoteHost) throws -> String {
        switch host.transport {
        case .scp:
            return scpCommand(localFileURL: localFileURL, remotePath: remotePath, host: host)
        case .rsync:
            return rsyncCommand(localFileURL: localFileURL, remotePath: remotePath, host: host)
        case .custom:
            return try customCommand(localFileURL: localFileURL, fileName: fileName, remotePath: remotePath, host: host)
        }
    }

    private func scpCommand(localFileURL: URL, remotePath: String, host: RemoteHost) -> String {
        let target = "\(host.connectionLabel):\(remotePath)"
        return [
            "scp",
            "-P", shellQuote(String(host.port)),
            shellQuote(localFileURL.path),
            shellQuote(target)
        ].joined(separator: " ")
    }

    private func rsyncCommand(localFileURL: URL, remotePath: String, host: RemoteHost) -> String {
        let target = "\(host.connectionLabel):\(remotePath)"
        let ssh = "ssh -p \(host.port)"
        return [
            "rsync",
            "-av",
            "-e", shellQuote(ssh),
            shellQuote(localFileURL.path),
            shellQuote(target)
        ].joined(separator: " ")
    }

    private func customCommand(localFileURL: URL, fileName: String, remotePath: String, host: RemoteHost) throws -> String {
        let template = host.customCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !template.isEmpty else {
            throw RemoteCopyError.invalidCustomCommand
        }

        let values = [
            "{local}": shellQuote(localFileURL.path),
            "{remote}": shellQuote(remotePath),
            "{fileName}": shellQuote(fileName),
            "{host}": shellQuote(host.host),
            "{user}": shellQuote(host.user),
            "{port}": shellQuote(String(host.port)),
            "{directory}": shellQuote(host.normalizedDirectory),
            "{connection}": shellQuote(host.connectionLabel)
        ]

        return values.reduce(template) { result, pair in
            result.replacingOccurrences(of: pair.key, with: pair.value)
        }
    }

    private func run(_ command: String) async throws {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", command]
            process.standardOutput = pipe
            process.standardError = pipe

            AppLog.transfer.info("remote copy process starting")
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)

            guard process.terminationStatus == 0 else {
                AppLog.transfer.error("remote copy process failed status=\(process.terminationStatus, privacy: .public) output=\(trimmedOutput, privacy: .public)")
                throw RemoteCopyError.processFailed(command: command, output: output)
            }

            AppLog.transfer.info("remote copy process finished status=0 output=\(trimmedOutput, privacy: .public)")
        }.value
    }

    private func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
