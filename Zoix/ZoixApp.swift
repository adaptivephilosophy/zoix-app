import SwiftUI

@main
struct ZoixApp: App {
    init() {
        ZoixColor.applyChrome()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
