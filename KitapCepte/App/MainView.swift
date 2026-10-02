import SwiftUI

/// Tab bar + sekme içerikleri. Sekmeler canlı tutulur (kaydırma/yüklenmiş veri korunur).
struct MainView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(FavoritesStore.self) private var favorites
    @Environment(CartStore.self) private var cart
    @State private var viewModel: MainViewModel
    @State private var homeViewModel: HomeViewModel
    @State private var profileViewModel: ProfileViewModel // MARK: Faz 8a
    private let makeDetailViewModel: (Book) -> DetailViewModel

    init(
        viewModel: MainViewModel,
        homeViewModel: HomeViewModel,
        makeDetailViewModel: @escaping (Book) -> DetailViewModel,
        profileViewModel: ProfileViewModel // MARK: Faz 8a
    ) {
        _profileViewModel = State(initialValue: profileViewModel) // MARK: Faz 8a
        _viewModel = State(initialValue: viewModel)
        _homeViewModel = State(initialValue: homeViewModel)
        self.makeDetailViewModel = makeDetailViewModel
    }

    var body: some View {
        // Tek NavigationStack: push edilen Detay tab bar'ın üstünü tamamen kaplar.
        NavigationStack(path: Binding(get: { viewModel.path }, set: { viewModel.updatePath($0) })) {
            scaffold
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self, destination: destination)
        }
        .task(id: sessionManager.currentUser?.id) {
            await favorites.reload()
            await cart.reload()
        }
    }

    private var scaffold: some View {
        AppScaffold {
            ZStack {
                tab(.home) {
                    HomeView(
                        viewModel: homeViewModel,
                        onProfile: { viewModel.select(.profile) },
                        onSelectBook: viewModel.openDetail
                    )
                }
                tab(.favorites) { ComingSoonView() }
                tab(.cart) { ComingSoonView() }
                tab(.profile) { ProfileView(viewModel: profileViewModel) } // MARK: Faz 8a
            }
        }
        // Tab bar listenin üstünde yüzer; liste bar'ın arkasından kayar (çevresi şeffaf).
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppTabBar(selection: viewModel.selectedTab, cartCount: cart.count, onSelect: viewModel.select)
        }
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .detail(let book):
            DetailView(
                viewModel: makeDetailViewModel(book),
                onBack: viewModel.pop,
                onSelectBook: viewModel.openDetail
            )
        }
    }

    private func tab<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return content()
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
            .accessibilityHidden(!isSelected)
    }
}

/// Henüz yapılmamış sekmeler için geçici ekran.
private struct ComingSoonView: View {
    var body: some View {
        EmptyStateView(title: Strings.Placeholder.title, message: Strings.Placeholder.message, systemImage: "hammer")
    }
}
