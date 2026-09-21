import AppKit

let app = NSApplication.shared
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 520, height: 260),
    styleMask: [.titled, .closable, .miniaturizable],
    backing: .buffered, defer: false
)
window.title = "Loupe"
let label = NSTextField(labelWithString: "Loupe — Quick-Look-Vorschau\nOberfläche folgt in Task 12.")
label.alignment = .center
label.frame = NSRect(x: 20, y: 100, width: 480, height: 60)
window.contentView?.addSubview(label)
window.center()
window.makeKeyAndOrderFront(nil)
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
