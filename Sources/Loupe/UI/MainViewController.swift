import AppKit
import LoupeCore

public final class MainViewController: NSViewController {
    private let statusLabel = NSTextField(labelWithString: "")
    private let appearancePopup = NSPopUpButton()
    private let textSizePopup = NSPopUpButton()
    private let contentWidthPopup = NSPopUpButton()

    public override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 460))
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor)
        ])

        let title = NSTextField(labelWithString: "Loupe")
        title.font = .systemFont(ofSize: 24, weight: .bold)
        stack.addArrangedSubview(title)

        let subtitle = NSTextField(labelWithString:
            "Native Vorschau für JSON und Markdown im macOS Finder. Leertaste drücken.")
        subtitle.textColor = .secondaryLabelColor
        stack.addArrangedSubview(subtitle)

        stack.addArrangedSubview(NSBox())
        stack.addArrangedSubview(statusLabel)

        for size in LoupeTextSize.allCases { textSizePopup.addItem(withTitle: size.displayName) }
        for look in LoupeAppearance.allCases { appearancePopup.addItem(withTitle: look.displayName) }
        for width in LoupeContentWidth.allCases { contentWidthPopup.addItem(withTitle: width.displayName) }

        appearancePopup.target = self
        appearancePopup.action = #selector(settingsChanged)
        textSizePopup.target = self
        textSizePopup.action = #selector(settingsChanged)
        contentWidthPopup.target = self
        contentWidthPopup.action = #selector(settingsChanged)

        stack.addArrangedSubview(labelled("Erscheinungsbild", appearancePopup))
        stack.addArrangedSubview(labelled("Textgröße", textSizePopup))
        stack.addArrangedSubview(labelled("Markdown-Breite", contentWidthPopup))

        stack.addArrangedSubview(NSBox())
        let guide = NSTextField(wrappingLabelWithString: """
        Erscheint stattdessen roher Text?
        1. Systemeinstellungen → Datenschutz & Sicherheit → Erweiterungen → Quick Look
        2. „Loupe QuickLook Preview“ einschalten
        3. Im Terminal: qlmanage -r && qlmanage -r cache && killall Finder
        """)
        guide.textColor = .secondaryLabelColor
        stack.addArrangedSubview(guide)

        loadSettings()
        refreshStatus()
    }

    private func labelled(_ text: String, _ control: NSView) -> NSStackView {
        let row = NSStackView(views: [NSTextField(labelWithString: text), control])
        row.orientation = .horizontal
        row.spacing = 12
        return row
    }

    private func loadSettings() {
        let s = LoupeSettings.load()
        appearancePopup.selectItem(at: LoupeAppearance.allCases.firstIndex(of: s.appearance) ?? 0)
        textSizePopup.selectItem(at: LoupeTextSize.allCases.firstIndex(of: s.textSize) ?? 1)
        contentWidthPopup.selectItem(at: LoupeContentWidth.allCases.firstIndex(of: s.contentWidth) ?? 1)
    }

    @objc private func settingsChanged() {
        var s = LoupeSettings.load()
        s.appearance = LoupeAppearance.allCases[appearancePopup.indexOfSelectedItem]
        s.textSize = LoupeTextSize.allCases[textSizePopup.indexOfSelectedItem]
        s.contentWidth = LoupeContentWidth.allCases[contentWidthPopup.indexOfSelectedItem]
        s.save()
    }

    private func refreshStatus() {
        let status = ExtensionStatusChecker.checkStatus()
        statusLabel.stringValue = "Erweiterung: \(status.title)"
        statusLabel.textColor = status.isOperational ? .systemGreen : .systemRed
    }
}
