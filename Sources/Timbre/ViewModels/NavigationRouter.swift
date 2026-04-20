import Foundation
import SwiftData

@MainActor @Observable
final class NavigationRouter {
    var activeRoute: Route = .home

    enum Route: Equatable {
        case home
        case analyze    // sidebar + library (existing ContentView layout)
        case record
        case scan
        case threads
        case me
        case memo(Memo)

        static func == (lhs: Route, rhs: Route) -> Bool {
            switch (lhs, rhs) {
            case (.home, .home),
                 (.analyze, .analyze),
                 (.record, .record),
                 (.scan, .scan),
                 (.threads, .threads),
                 (.me, .me):
                return true
            case let (.memo(a), .memo(b)):
                return a.id == b.id
            default:
                return false
            }
        }
    }

    /// Whether the current route shows the sidebar
    var showsSidebar: Bool {
        switch activeRoute {
        case .analyze, .memo: return true
        default: return false
        }
    }

    func navigate(to route: Route) {
        activeRoute = route
    }

    func goHome() {
        activeRoute = .home
    }
}
