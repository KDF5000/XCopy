# XCopy

XCopy is a macOS menu bar app for pasting local screenshots into remote terminal workflows.

It watches for a configurable global shortcut, uploads the image currently in the macOS clipboard to the matched SSH remote, then pastes the remote file path back into the focused input.

## Why

Remote terminal tools often cannot receive image paste events directly. XCopy turns this flow:

1. Take a screenshot on macOS.
2. Focus a remote terminal or coding agent session.
3. Press the XCopy shortcut.
4. Get a remote image path pasted into the prompt.

## Features

- Menu bar app with a compact native macOS UI.
- Default shortcut: `Command + Shift + V`.
- Configurable shortcut recording from the menu bar panel.
- Automatic SSH session detection through shell integration.
- Remote host configuration for user, host, port, upload directory, and transfer method.
- Built-in `scp` and `rsync` transfer modes.
- Custom command templates for advanced transfer workflows.
- DMG packaging script.

## Usage

1. Open `XCopy.app`.
2. Allow Accessibility permission when macOS asks.
3. Configure one or more remotes from the menu bar panel.
4. Open a new terminal after SSH integration is installed.
5. Connect normally:

   ```bash
   ssh my-host
   ```

6. Copy a screenshot to the macOS clipboard.
7. Press `Command + Shift + V` in the remote terminal.

XCopy uploads the clipboard image and pastes a path like:

```text
/data00/tmp/xcopy/xcopy-20260519-203303-134.png
```

## SSH Integration

On first launch, XCopy installs a shell integration into `~/.zshrc` and creates:

```text
~/.xcopy/bin/xcopy
```

The integration wraps interactive `ssh` calls so XCopy can map the focused terminal window to the correct remote host. Open a new terminal or run:

```bash
source ~/.zshrc
```

The wrapper still calls the system SSH binary at `/usr/bin/ssh`.

## Remote Configuration

Each remote includes:

- Name
- User
- Host
- Port
- Remote directory
- Transfer mode

The pasted path is the remote absolute file path.

## Custom Transfer Commands

Custom commands run locally. Exit code `0` means the transfer succeeded.

Available placeholders:

- `{local}`: local temporary image path
- `{remote}`: remote absolute path
- `{fileName}`: generated file name
- `{host}`: remote host
- `{user}`: remote user
- `{port}`: SSH port
- `{directory}`: remote directory
- `{connection}`: `user@host`

Example:

```bash
scp -P {port} {local} {connection}:{remote}
```

## Development

Build and run:

```bash
./script/build_and_run.sh
```

Verify launch:

```bash
./script/build_and_run.sh --verify
```

Watch app diagnostics while reproducing a failed paste:

```bash
./script/build_and_run.sh --logs
```

For a packaged app, stream logs with the bundle identifier used at build time:

```bash
/usr/bin/log stream --info --style compact --predicate 'subsystem == "com.local.XCopy"'
```

The SSH wrapper also writes session-detection breadcrumbs to:

```text
~/.xcopy/logs/ssh-wrapper.log
```

Package DMG:

```bash
./script/package_dmg.sh
```

The DMG is written to:

```text
dist/XCopy.dmg
```

For a GitHub release that opens without Gatekeeper warnings, build with a
Developer ID Application certificate and notarize the DMG:

```bash
XCOPY_BUNDLE_ID="com.your-team.XCopy" \
XCOPY_CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
XCOPY_NOTARY_KEYCHAIN_PROFILE="xcopy-notary" \
./script/package_dmg.sh
```

Create the keychain profile once with:

```bash
xcrun notarytool store-credentials xcopy-notary \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

You can also skip `XCOPY_NOTARY_KEYCHAIN_PROFILE` and pass
`XCOPY_NOTARY_APPLE_ID`, `XCOPY_NOTARY_TEAM_ID`, and
`XCOPY_NOTARY_PASSWORD` directly.

Validate the final artifact:

```bash
spctl -a -vvv -t open dist/dmg-root/XCopy.app
xcrun stapler validate dist/XCopy.dmg
```

## Requirements

- macOS 14+
- Xcode / Swift toolchain
- SSH access to configured remotes
- macOS Accessibility permission for global shortcut handling
