import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem

    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.title, systemImage: item.symbolName)
                .tag(item)
        }
        .listStyle(.sidebar)
        .navigationTitle("XCopy")
    }
}
