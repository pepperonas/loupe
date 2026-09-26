import Foundation

/// Texte der Begleit-App.
public extension L10n {
    private var isDE: Bool { lang == .de }

    var appSubtitle: String {
        isDE ? "Native Vorschau für JSON, Markdown, Logs, TSV und Code im Finder. Leertaste drücken."
             : "Native previews for JSON, Markdown, logs, TSV and code in Finder. Press Space."
    }
    func extensionStatus(_ status: String) -> String { (isDE ? "Erweiterung: " : "Extension: ") + status }
    var previewsEnabled: String { isDE ? "Loupe-Vorschauen aktiv" : "Loupe previews on" }
    var previewsOffHint: String {
        isDE ? "Ausgeschaltet zeigt Quick Look den Rohtext, wie ohne Loupe. Gilt beim nächsten Druck auf die Leertaste."
             : "When off, Quick Look shows the plain text, as without Loupe. Applies the next time you press Space."
    }
    var appearance: String { isDE ? "Erscheinungsbild" : "Appearance" }
    var textSize: String { isDE ? "Textgröße" : "Text size" }
    var markdownWidth: String { isDE ? "Markdown-Breite" : "Markdown width" }
    var language: String { isDE ? "Sprache" : "Language" }
    var setupGuide: String {
        isDE ? """
        Erscheint Rohtext statt der Loupe-Vorschau?
        1. Erweiterung einschalten – ab macOS 15: Systemeinstellungen → Allgemein →
           Anmeldeobjekte & Erweiterungen → Quick Look; macOS 14: Datenschutz &
           Sicherheit → Erweiterungen → Quick Look
        2. Oben prüfen, ob die Vorschauen und die Rubrik eingeschaltet sind
        3. Im Terminal: qlmanage -r && qlmanage -r cache && killall Finder
        """ : """
        Seeing plain text instead of the Loupe preview?
        1. Turn the extension on – macOS 15 and later: System Settings → General →
           Login Items & Extensions → Quick Look; macOS 14: Privacy & Security →
           Extensions → Quick Look
        2. Check above that previews and the category are switched on
        3. In Terminal: qlmanage -r && qlmanage -r cache && killall Finder
        """
    }
    func aboutHeading(version: String) -> String { (isDE ? "Über Loupe · Version " : "About Loupe · Version ") + version }
    func developedBy(_ author: String) -> String { (isDE ? "Entwickelt von " : "Made by ") + author + " ·" }
    var website: String { "Website" }
    var donate: String { isDE ? "Per PayPal spenden" : "Donate via PayPal" }
    var sourceOnGitHub: String { isDE ? "Quellcode auf GitHub" : "Source code on GitHub" }
    var donateHint: String { isDE ? "Eine kleine Spende an den Entwickler" : "A small donation to the developer" }
    var licensePrefix: String { isDE ? "Frei und quelloffen unter der" : "Free and open source under the" }
    var licenseName: String { isDE ? "MIT-Lizenz" : "MIT License" }

    // Menue
    func menuAbout(_ app: String) -> String { isDE ? "Über \(app)" : "About \(app)" }
    func menuHide(_ app: String) -> String { isDE ? "\(app) ausblenden" : "Hide \(app)" }
    var menuHideOthers: String { isDE ? "Andere ausblenden" : "Hide Others" }
    var menuShowAll: String { isDE ? "Alle einblenden" : "Show All" }
    func menuQuit(_ app: String) -> String { isDE ? "\(app) beenden" : "Quit \(app)" }
    var menuWindow: String { isDE ? "Fenster" : "Window" }
    var menuMinimize: String { isDE ? "Im Dock ablegen" : "Minimize" }
    var menuZoom: String { isDE ? "Zoomen" : "Zoom" }
}
