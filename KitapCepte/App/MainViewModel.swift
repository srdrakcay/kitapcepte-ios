import Observation

@MainActor @Observable
final class MainViewModel {
    private(set) var selectedTab: AppTab = .home
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
