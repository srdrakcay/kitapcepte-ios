import SwiftUI

extension View {
    /// Kök görünüme bir kez eklenir; `GuestGate` sheet'ini gösterir.
    func guestGateSheet(_ gate: GuestGate) -> some View {
        appSheet(isPresented: Binding(get: { gate.isSheetPresented }, set: { gate.isSheetPresented = $0 })) {
            LoginRequiredSheet(onSignUp: gate.proceedToSignUp, onCancel: gate.dismiss)
        }
    }
}
