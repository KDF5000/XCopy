import Foundation

enum ShellIntegrationError: LocalizedError {
    case homeDirectoryUnavailable
    case cannotReadShellProfile

    var errorDescription: String? {
        switch self {
        case .homeDirectoryUnavailable:
            "无法找到用户主目录。"
        case .cannotReadShellProfile:
            "无法读取 shell 配置文件。"
        }
    }
}

struct ShellIntegrationInstaller {
    private let beginMarker = "# >>> xcopy ssh integration >>>"
    private let endMarker = "# <<< xcopy ssh integration <<<"

    func install() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        guard !home.path.isEmpty else {
            throw ShellIntegrationError.homeDirectoryUnavailable
        }

        let binDirectory = home.appendingPathComponent(".xcopy/bin", isDirectory: true)
        let sessionsDirectory = home.appendingPathComponent(".xcopy/sessions", isDirectory: true)
        let ttySessionsDirectory = sessionsDirectory.appendingPathComponent("by-tty", isDirectory: true)
        let cliURL = binDirectory.appendingPathComponent("xcopy")
        let zshrcURL = home.appendingPathComponent(".zshrc")

        try FileManager.default.createDirectory(at: binDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: ttySessionsDirectory, withIntermediateDirectories: true)
        try cliScript.write(to: cliURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: cliURL.path)

        let currentProfile: String
        if FileManager.default.fileExists(atPath: zshrcURL.path) {
            guard let content = try? String(contentsOf: zshrcURL, encoding: .utf8) else {
                throw ShellIntegrationError.cannotReadShellProfile
            }
            currentProfile = content
        } else {
            currentProfile = ""
        }

        let updatedProfile = replacingIntegrationBlock(in: currentProfile, with: zshIntegrationBlock)
        try updatedProfile.write(to: zshrcURL, atomically: true, encoding: .utf8)
    }

    private func replacingIntegrationBlock(in profile: String, with block: String) -> String {
        guard
            let beginRange = profile.range(of: beginMarker),
            let endRange = profile.range(of: endMarker, range: beginRange.upperBound..<profile.endIndex)
        else {
            let separator = profile.hasSuffix("\n") || profile.isEmpty ? "" : "\n"
            return profile + separator + block + "\n"
        }

        var updated = profile
        updated.replaceSubrange(beginRange.lowerBound..<endRange.upperBound, with: block.trimmingCharacters(in: .newlines))
        return updated
    }

    private var zshIntegrationBlock: String {
        """
        \(beginMarker)
        ssh() {
          "$HOME/.xcopy/bin/xcopy" ssh-wrapper "$@"
        }
        \(endMarker)
        """
    }

    private var cliScript: String {
        """
        #!/usr/bin/env bash
        set -u

        xcopy_extract_ssh_target() {
          local skip_next=0
          local arg

          for arg in "$@"; do
            if [ "$skip_next" = "1" ]; then
              skip_next=0
              continue
            fi

            case "$arg" in
              --)
                skip_next=0
                continue
                ;;
              -b|-c|-D|-E|-e|-F|-I|-i|-J|-L|-l|-m|-O|-o|-p|-Q|-R|-S|-W|-w)
                skip_next=1
                ;;
              -*)
                ;;
              *)
                printf '%s' "$arg"
                return 0
                ;;
            esac
          done

          return 1
        }

        xcopy_json_escape() {
          local value="$1"
          value="${value//\\\\/\\\\\\\\}"
          value="${value//\\"/\\\\\\"}"
          value="${value//$'\\n'/\\\\n}"
          value="${value//$'\\r'/\\\\r}"
          value="${value//$'\\t'/\\\\t}"
          printf '%s' "$value"
        }

        xcopy_ssh_wrapper() {
          local target
          target="$(xcopy_extract_ssh_target "$@" || true)"

          if [ -z "$target" ]; then
            exec /usr/bin/ssh "$@"
          fi

          local root="$HOME/.xcopy"
          local sessions="$root/sessions"
          local tty_sessions="$sessions/by-tty"
          local token
          token="$(uuidgen | tr '[:upper:]' '[:lower:]')"

          mkdir -p "$sessions" "$tty_sessions"
          printf '%s\\n' "$target" > "$sessions/$token"

          local tty_path
          tty_path="$(tty 2>/dev/null || true)"
          local tty_id=""
          local tty_session=""
          if [ -n "$tty_path" ] && [ "$tty_path" != "not a tty" ]; then
            tty_id="${tty_path#/dev/}"
            tty_session="$tty_sessions/$tty_id.json"
            printf '{\\n  "target": "%s",\\n  "tty": "%s",\\n  "pid": %s,\\n  "startedAt": %s\\n}\\n' \\
              "$(xcopy_json_escape "$target")" \\
              "$(xcopy_json_escape "$tty_path")" \\
              "$$" \\
              "$(date +%s)" > "$tty_session"
          fi

          local title="xcopy:$token $target"
          printf '\\033]0;%s\\007' "$title"

          /usr/bin/ssh "$@"
          local code=$?

          rm -f "$sessions/$token"
          if [ -n "$tty_session" ]; then
            rm -f "$tty_session"
          fi
          printf '\\033]0;%s\\007' "$target"

          return "$code"
        }

        case "${1:-}" in
          ssh-wrapper)
            shift
            xcopy_ssh_wrapper "$@"
            ;;
          *)
            echo "usage: xcopy ssh-wrapper <ssh-args>" >&2
            exit 2
            ;;
        esac
        """
    }
}
