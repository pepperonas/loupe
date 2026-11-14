import AppKit
import LoupeCore
import UniformTypeIdentifiers

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: NSWindowController?
    private var documents: [DocumentWindowController] = []
    /// Wird die App mit Dateien gestartet (Doppelklick im Finder), kommt application(_:open:) vor
    /// applicationDidFinishLaunching. Dann nur die Dateien zeigen, nicht zusaetzlich die Einstellungen.
    private var openedDocumentsAtLaunch = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Einstellungen aus <= 0.4.0 lagen in einer Suite, die nur die App sah.
        LoupeSettings.migrateLegacy(from: UserDefaults(suiteName: LoupeSettings.legacySuiteName))
        setupMainMenu()
        if !openedDocumentsAtLaunch {
            showSettings(nil)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        openedDocumentsAtLaunch = true
        urls.forEach(openDocument)
    }

    /// Klick aufs Dock-Symbol ohne offenes Fenster: Einstellungen zeigen, wie bisher beim Start.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showSettings(nil) }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // MARK: - Fenster

    @objc func showSettings(_ sender: Any?) {
        if windowController == nil {
            let viewController = MainViewController()
            viewController.onLanguageChange = { [weak self] in self?.setupMainMenu() }
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 760),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Loupe"
            window.contentViewController = viewController
            window.isReleasedWhenClosed = false
            window.center()
            windowController = NSWindowController(window: window)
        }
        windowController?.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openDocument(_ url: URL) {
        // Dieselbe Datei nicht doppelt oeffnen, sondern ihr Fenster nach vorn holen
        if let offen = documents.first(where: { $0.url.standardizedFileURL == url.standardizedFileURL }) {
            offen.reload()
            offen.showWindow(self)
            return
        }
        let doc = DocumentWindowController(url: url)
        doc.onClose = { [weak self] closed in self?.documents.removeAll { $0 === closed } }
        documents.append(doc)
        doc.showWindow(self)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openDocumentPanel(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.begin { [weak self] response in
            guard response == .OK else { return }
            MainActor.assumeIsolated { panel.urls.forEach { self?.openDocument($0) } }
        }
    }

    // MARK: - Menue

    private func setupMainMenu() {
        let t = LoupeSettings.load().l10n
        let mainMenu = NSMenu()

        // App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: t.menuAbout("Loupe"), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: t.menuSettings, action: #selector(showSettings(_:)), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: t.menuHide("Loupe"), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: t.menuHideOthers, action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(withTitle: t.menuShowAll, action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: t.menuQuit("Loupe"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File Menu: Oeffnen, Neu laden (das Dokumentfenster reagiert per Responder-Kette), Schliessen
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: t.menuFile)
        fileMenu.addItem(withTitle: t.menuOpen, action: #selector(openDocumentPanel(_:)), keyEquivalent: "o")
        fileMenu.addItem(withTitle: t.menuReload, action: #selector(DocumentWindowController.reloadDocument(_:)), keyEquivalent: "r")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: t.menuClose, action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Edit Menu: Text in der Vorschau kopieren
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: t.menuEdit)
        editMenu.addItem(withTitle: t.menuCopy, action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: t.menuSelectAll, action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: t.menuWindow)
        windowMenu.addItem(withTitle: t.menuMinimize, action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: t.menuZoom, action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
    }
}
