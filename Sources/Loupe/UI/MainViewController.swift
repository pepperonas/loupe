import AppKit
import LoupeCore

public final class MainViewController: NSViewController {
    /// Wird nach einem Sprachwechsel aufgerufen (die App baut dann das Menue neu).
    var onLanguageChange: (() -> Void)?

    private let statusLabel = NSTextField(labelWithString: "")
    private let appearancePopup = NSPopUpButton()
    private let textSizePopup = NSPopUpButton()
    private let contentWidthPopup = NSPopUpButton()
    private let languagePopup = NSPopUpButton()
    private let masterSwitch = NSSwitch()
    private var categoryBoxes: [(PreviewCategory, NSButton)] = []
    private var stack: NSStackView?

    public override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 760))
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        for popup in [appearancePopup, textSizePopup, contentWidthPopup, languagePopup] {
            popup.target = self
            popup.action = #selector(settingsChanged)
        }
        masterSwitch.target = self
        masterSwitch.action = #selector(togglesChanged)
        build()
    }

    /// Baut die ganze Oberflaeche in der aktuellen Sprache (auch nach einem Wechsel).
    private func build() {
        stack?.removeFromSuperview()
        categoryBoxes.removeAll()
        let settings = LoupeSettings.load()
        let t = settings.l10n

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
        self.stack = stack

        let title = NSTextField(labelWithString: "Loupe")
        title.font = .systemFont(ofSize: 24, weight: .bold)
        stack.addArrangedSubview(title)

        let subtitle = NSTextField(labelWithString: t.appSubtitle)
        subtitle.textColor = .secondaryLabelColor
        stack.addArrangedSubview(subtitle)

        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(statusLabel)

        // Vorschauen an/aus: global und je Rubrik. Aus = Quick Look zeigt den Rohtext.
        let masterLabel = NSTextField(labelWithString: t.previewsEnabled)
        masterLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        stack.addArrangedSubview(row(masterSwitch, masterLabel, spacing: 10))

        let categories = NSStackView()
        categories.orientation = .vertical
        categories.alignment = .leading
        categories.spacing = 6
        categories.edgeInsets = NSEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        for category in PreviewCategory.allCases {
            let box = NSButton(checkboxWithTitle: category.displayName(t.lang),
                               target: self, action: #selector(togglesChanged))
            categoryBoxes.append((category, box))
            categories.addArrangedSubview(box)
        }
        stack.addArrangedSubview(categories)

        let hint = NSTextField(wrappingLabelWithString: t.previewsOffHint)
        hint.textColor = .secondaryLabelColor
        hint.font = .systemFont(ofSize: 11)
        stack.addArrangedSubview(hint)

        stack.addArrangedSubview(separator())

        fill(appearancePopup, LoupeAppearance.allCases.map { $0.displayName(t.lang) })
        fill(textSizePopup, LoupeTextSize.allCases.map { $0.displayName(t.lang) })
        fill(contentWidthPopup, LoupeContentWidth.allCases.map { $0.displayName(t.lang) })
        fill(languagePopup, LoupeLanguageSetting.allCases.map { $0.displayName(t.lang) })
        stack.addArrangedSubview(labelled(t.language, languagePopup))
        stack.addArrangedSubview(labelled(t.appearance, appearancePopup))
        stack.addArrangedSubview(labelled(t.textSize, textSizePopup))
        stack.addArrangedSubview(labelled(t.markdownWidth, contentWidthPopup))

        stack.addArrangedSubview(separator())
        let guide = NSTextField(wrappingLabelWithString: t.setupGuide)
        guide.textColor = .secondaryLabelColor
        stack.addArrangedSubview(guide)

        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(aboutSection(t))

        loadSettings(settings)
        refreshStatus(t)
    }

    // MARK: - Über Loupe

    private func aboutSection(_ t: L10n) -> NSView {
        let heading = NSTextField(labelWithString: t.aboutHeading(version: AboutLinks.version()))
        heading.font = .systemFont(ofSize: 13, weight: .semibold)

        let by = row(NSTextField(labelWithString: t.developedBy(AboutLinks.author)),
                     linkButton("celox.io", url: AboutLinks.websiteURL), spacing: 4)

        let buttons = NSStackView(views: [
            actionButton("GitHub", image: GitHubMark.image(), url: AboutLinks.repoURL, help: t.sourceOnGitHub),
            actionButton(t.website, image: symbol("globe"), url: AboutLinks.productURL, help: "loupe.celox.io"),
            actionButton(t.donate, image: symbol("heart.fill"), url: AboutLinks.donateURL(), help: t.donateHint)
        ])
        buttons.spacing = 8

        let licenseLabel = NSTextField(labelWithString: t.licensePrefix)
        licenseLabel.textColor = .secondaryLabelColor
        let license = row(licenseLabel, linkButton(t.licenseName, url: AboutLinks.licenseURL), spacing: 4)

        let about = NSStackView(views: [heading, by, buttons, license])
        about.orientation = .vertical
        about.alignment = .leading
        about.spacing = 8
        return about
    }

    // MARK: - Bausteine

    private func fill(_ popup: NSPopUpButton, _ titles: [String]) {
        popup.removeAllItems()
        popup.addItems(withTitles: titles)
    }

    private func symbol(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }

    private func actionButton(_ title: String, image: NSImage?, url: URL, help: String) -> NSButton {
        let b = NSButton(title: title, target: self, action: #selector(openLink(_:)))
        b.bezelStyle = .rounded
        if let image {
            b.image = image
            b.imagePosition = .imageLeading
        }
        b.toolTip = help
        b.identifier = NSUserInterfaceItemIdentifier(url.absoluteString)
        return b
    }

    private func linkButton(_ title: String, url: URL) -> NSButton {
        let b = NSButton(title: title, target: self, action: #selector(openLink(_:)))
        b.isBordered = false
        b.attributedTitle = NSAttributedString(string: title, attributes: [
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
        ])
        b.toolTip = url.absoluteString
        b.identifier = NSUserInterfaceItemIdentifier(url.absoluteString)
        return b
    }

    @objc private func openLink(_ sender: NSButton) {
        guard let raw = sender.identifier?.rawValue, let url = URL(string: raw) else { return }
        NSWorkspace.shared.open(url)
    }

    /// Eine nackte NSBox() zeichnet einen Rahmen mit der Beschriftung „Title“.
    private func separator() -> NSView {
        let line = NSBox()
        line.boxType = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        line.widthAnchor.constraint(equalToConstant: 512).isActive = true
        return line
    }

    private func row(_ lead: NSView, _ trail: NSView, spacing: CGFloat) -> NSStackView {
        let row = NSStackView(views: [lead, trail])
        row.orientation = .horizontal
        row.spacing = spacing
        return row
    }

    private func labelled(_ text: String, _ control: NSView) -> NSStackView {
        row(NSTextField(labelWithString: text), control, spacing: 12)
    }

    // MARK: - Einstellungen

    private func loadSettings(_ s: LoupeSettings) {
        appearancePopup.selectItem(at: LoupeAppearance.allCases.firstIndex(of: s.appearance) ?? 0)
        textSizePopup.selectItem(at: LoupeTextSize.allCases.firstIndex(of: s.textSize) ?? 1)
        contentWidthPopup.selectItem(at: LoupeContentWidth.allCases.firstIndex(of: s.contentWidth) ?? 1)
        languagePopup.selectItem(at: LoupeLanguageSetting.allCases.firstIndex(of: s.language) ?? 0)
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
        let oldLanguage = s.language
        s.appearance = LoupeAppearance.allCases[appearancePopup.indexOfSelectedItem]
        s.textSize = LoupeTextSize.allCases[textSizePopup.indexOfSelectedItem]
        s.contentWidth = LoupeContentWidth.allCases[contentWidthPopup.indexOfSelectedItem]
        s.language = LoupeLanguageSetting.allCases[languagePopup.indexOfSelectedItem]
        s.save()
        if s.language != oldLanguage {
            build()
            onLanguageChange?()
        }
    }

    private func refreshStatus(_ t: L10n) {
        let status = ExtensionStatusChecker.checkStatus()
        statusLabel.stringValue = t.extensionStatus(status.title(t.lang))
        switch status {
        case .active:       statusLabel.textColor = .systemGreen
        case .installed:    statusLabel.textColor = .systemOrange
        case .notInstalled: statusLabel.textColor = .systemRed
        case .unknown:      statusLabel.textColor = .secondaryLabelColor
        }
    }
}
