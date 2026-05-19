import SwiftUI

struct ContentView: View {
    var body: some View {
        HostDetailView()
    }
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case hosts
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hosts: "远端"
        case .history: "历史"
        }
    }

    var symbolName: String {
        switch self {
        case .hosts: "server.rack"
        case .history: "clock.arrow.circlepath"
        }
    }
}
