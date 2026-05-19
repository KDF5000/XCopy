import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Form {
            Section("快捷操作") {
                LabeledContent("粘贴触发上传", value: store.pasteShortcut.displayParts.joined(separator: " "))
            }

            Section("当前状态") {
                Text(store.statusMessage)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
    }
}
