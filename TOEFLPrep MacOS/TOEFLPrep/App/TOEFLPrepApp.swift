import SwiftUI

@main
struct TOEFLPrepApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                #if os(macOS)
                .frame(minWidth: 1000, minHeight: 700)
                #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1240, height: 820)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) { }
        }
        #endif
    }
}
