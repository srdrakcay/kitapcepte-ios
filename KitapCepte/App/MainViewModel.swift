import Observation

@MainActor @Observable
final class MainViewModel {
    private(set) var selectedTab: AppTab = .home
    private(set) var path: [AppRoute] = []
    private let gate: GuestGate

    init(gate: GuestGate) {
        self.gate = gate
    }

    /// Home dışındaki sekmeler üyelere özeldir; misafir "üye ol" sheet'ini görür.
    func select(_ tab: AppTab) {
        if tab == .home {
            selectedTab = .home
        } else {
            gate.require { selectedTab = tab }
        }
    }
}

extension MainViewModel {
    /// Detay üyelere özeldir; misafir "üye ol" sheet'ini görür.
    func openDetail(_ book: Book) {
        gate.require { path.append(.detail(book)) }
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Sistem geri hareketi gibi NavigationStack kaynaklı değişiklikler için.
    func updatePath(_ newPath: [AppRoute]) {
        path = newPath
    }
}
