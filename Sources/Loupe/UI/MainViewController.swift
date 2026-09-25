import AppKit
import LoupeCore

public final class MainViewController: NSViewController {
    private let statusLabel = NSTextField(labelWithString: "")
    private let appearancePopup = NSPopUpButton()
    private let textSizePopup = NSPopUpButton()
    private let contentWidthPopup = NSPopUpButton()
    private let masterSwitch = NSSwitch()
    private var categoryBoxes: [(PreviewCategory, NSButton)] = []

    public override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 640))
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
            "Native Vorschau für JSON, Markdown, Logs, TSV und Code im Finder. Leertaste drücken.")
        subtitle.textColor = .secondaryLabelColor
        stack.addArrangedSubview(subtitle)

        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(statusLabel)

        // Vorschauen an/aus: global und je Rubrik. Aus = Quick Look zeigt
        // wieder seine eigene Vorschau (Rohtext bzw. Symbol).
        masterSwitch.target = self
        masterSwitch.action = #selector(togglesChanged)
        let masterLabel = NSTextField(labelWithString: "Loupe-Vorschauen aktiv")
        masterLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        stack.addArrangedSubview(labelled(masterSwitch, masterLabel))

        let categories = NSStackView()
        categories.orientation = .vertical
        categories.alignment = .leading
        categories.spacing = 6
        categories.edgeInsets = NSEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        for category in PreviewCategory.allCases {
            let box = NSButton(checkboxWithTitle: category.displayName,
                               target: self, action: #selector(togglesChanged))
            categoryBoxes.append((category, box))
            categories.addArrangedSubview(box)
        }
        stack.addArrangedSubview(categories)

        let hint = NSTextField(wrappingLabelWithString:
            "Ausgeschaltet zeigt Quick Look wieder seine eigene Vorschau. Gilt beim nächsten Druck auf die Leertaste.")
        hint.textColor = .secondaryLabelColor
        hint.font = .systemFont(ofSize: 11)
        stack.addArrangedSubview(hint)

        stack.addArrangedSubview(separator())

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

        stack.addArrangedSubview(separator())
        let guide = NSTextField(wrappingLabelWithString: """
        Erscheint stattdessen die Standard-Vorschau von macOS?
        1. Erweiterung einschalten – ab macOS 15: Systemeinstellungen → Allgemein →
           Anmeldeobjekte & Erweiterungen → Quick Look; macOS 14: Datenschutz &
           Sicherheit → Erweiterungen → Quick Look
        2. Oben prüfen, ob die Vorschauen und die Rubrik eingeschaltet sind
        3. Im Terminal: qlmanage -r && qlmanage -r cache && killall Finder
        """)
        guide.textColor = .secondaryLabelColor
        stack.addArrangedSubview(guide)

        loadSettings()
        refreshStatus()
    }

    /// Eine nackte NSBox() zeichnet einen Rahmen mit der Beschriftung „Title“.
    private func separator() -> NSView {
        let line = NSBox()
        line.boxType = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        line.widthAnchor.constraint(equalToConstant: 512).isActive = true
        return line
    }

    private func labelled(_ lead: NSView, _ trail: NSView) -> NSStackView {
        let row = NSStackView(views: [lead, trail])
        row.orientation = .horizontal
        row.spacing = 10
        return row
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
        masterSwitch.state = s.previewsEnabled ? .on : .off
        for (category, box) in categoryBoxes {
            // Die Haken zeigen die Wahl JE RUBRIK -- auch wenn global aus ist.
            box.state = s.disabledCategories.contains(category) ? .off : .on
        }
        updateCategoryAvailability(globalOn: s.previewsEnabled)
    }

    private func updateCategoryAvailability(globalOn: Bool) {
        for (_, box) in categoryBoxes { box.isEnabled = globalOn }
    }

    @objc private func togglesChanged() {
        var s = LoupeSettings.load()
        s.previewsEnabled = masterSwitch.state == .on
        for (category, box) in categoryBoxes {
            s.setEnabled(box.state == .on, for: category)
        }
        s.save()
        updateCategoryAvailability(globalOn: s.previewsEnabled)
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
        switch status {
        case .active:       statusLabel.textColor = .systemGreen
        case .installed:    statusLabel.textColor = .systemOrange
        case .notInstalled: statusLabel.textColor = .systemRed
        case .unknown:      statusLabel.textColor = .secondaryLabelColor
        }
    }
}
