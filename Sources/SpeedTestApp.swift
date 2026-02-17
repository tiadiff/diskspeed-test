import SwiftUI

@main
struct SpeedTestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor(red: 28/255, green: 28/255, blue: 28/255, alpha: 1.0)
            window.isMovableByWindowBackground = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
    }
}
