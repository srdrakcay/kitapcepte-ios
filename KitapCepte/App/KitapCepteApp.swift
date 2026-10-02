import SwiftUI

@main
struct KitapCepteApp: App {
    private let container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .environment(\.appTheme, container.theme)
        }
    }
}
