import Foundation
import Markdown

public final class MarkdownRenderer: @unchecked Sendable {
    public let settings: LoupeSettings
    public let documentURL: URL?
    
    public init(settings: LoupeSettings = LoupeSettings.load(), documentURL: URL? = nil) {
        self.settings = settings
        self.documentURL = documentURL
    }
    
    public func renderHTML(markdown: String, documentTitle: String? = nil) -> String {
        var content = markdown
        var warningBannerHTML = ""
        
        // Check for large file degradation
        let utf8Count = markdown.utf8.count
        if utf8Count > settings.maxFileSizeBytes {
            let maxMB = settings.maxFileSizeBytes / (1024 * 1024)
            warningBannerHTML = """
            <div class="loupe-warning-banner">
                <strong>Large document truncated:</strong> Showing the first \(maxMB) MB of content for Quick Look performance.
            </div>
            """
            // Truncate cleanly at a character boundary
            let endIndex = markdown.index(markdown.startIndex, offsetBy: min(settings.maxFileSizeBytes, markdown.count))
            content = String(markdown[..<endIndex])
        }
        
        let document = Document(parsing: content, options: [.parseBlockDirectives, .parseSymbolLinks])
        var visitor = HTMLVisitor(settings: settings, documentURL: documentURL)
        let bodyHTML = visitor.visit(document)
        
        let pageTitle = documentTitle ?? visitor.extractedTitle ?? "Loupe Preview"
        let css = CSSGenerator.generateMarkdownCSS(settings: settings)
        let csp = HTMLDocument.markdownCSP(allowRemoteImages: settings.allowRemoteImages)
        
        let body = """
        <div class="loupe-markdown-container">
            \(warningBannerHTML)
            \(bodyHTML)
        </div>
        """
        
        return HTMLDocument.wrap(body: body, title: pageTitle, css: css, csp: csp)
    }
}

private struct HTMLVisitor: MarkupVisitor {
    typealias Result = String
    
    let settings: LoupeSettings
    let documentURL: URL?
    var extractedTitle: String?
    
    init(settings: LoupeSettings, documentURL: URL?) {
        self.settings = settings
        self.documentURL = documentURL
    }
    
    mutating func defaultVisit(_ markup: Markup) -> String {
        var result = ""
        for child in markup.children {
            result += visit(child)
        }
        return result
    }
    
    mutating func visitDocument(_ document: Document) -> String {
        var result = ""
        for child in document.children {
            result += visit(child)
        }
        return result
    }
    
    mutating func visitHeading(_ heading: Heading) -> String {
        let level = min(max(heading.level, 1), 6)
        var textContent = ""
        for child in heading.children {
            textContent += visit(child)
        }
        
        if extractedTitle == nil && level == 1 {
            extractedTitle = heading.plainText
        }
        
        let anchor = heading.plainText
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        
        if !anchor.isEmpty {
            return "<h\(level) id=\"\(anchor)\">\(textContent)</h\(level)>\n"
        }
        return "<h\(level)>\(textContent)</h\(level)>\n"
    }
    
    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        var content = ""
        for child in paragraph.children {
            content += visit(child)
        }
        return "<p>\(content)</p>\n"
    }
    
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        var content = ""
        for child in blockQuote.children {
            content += visit(child)
        }
        return "<blockquote>\n\(content)</blockquote>\n"
    }
    
    mutating func visitOrderedList(_ orderedList: OrderedList) -> String {
        var content = ""
        for child in orderedList.children {
            content += visit(child)
        }
        let startAttr = orderedList.startIndex != 1 ? " start=\"\(orderedList.startIndex)\"" : ""
        return "<ol\(startAttr)>\n\(content)</ol>\n"
    }
    
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        // Check if task list
        let isTaskList = unorderedList.children.contains { child in
            if let item = child as? ListItem, item.checkbox != nil {
                return true
            }
            return false
        }
        
        var content = ""
        for child in unorderedList.children {
            content += visit(child)
        }
        
        let classAttr = isTaskList ? " class=\"task-list\"" : ""
        return "<ul\(classAttr)>\n\(content)</ul>\n"
    }
    
    mutating func visitListItem(_ listItem: ListItem) -> String {
        if let checkbox = listItem.checkbox {
            let isChecked = (checkbox == .checked)
            let checkedAttr = isChecked ? " checked" : ""
            let checkedClass = isChecked ? " checked" : ""
            
            var content = ""
            for child in listItem.children {
                content += visit(child)
            }
            
            // If the content is wrapped in <p>...</p>, unwrap it to keep it inline with checkbox
            if content.hasPrefix("<p>") && content.hasSuffix("</p>\n") {
                let start = content.index(content.startIndex, offsetBy: 3)
                let end = content.index(content.endIndex, offsetBy: -5)
                content = String(content[start..<end])
            }
            
            return "<li class=\"task-list-item\(checkedClass)\"><input type=\"checkbox\" disabled\(checkedAttr)> <span>\(content)</span></li>\n"
        }
        
        var content = ""
        for child in listItem.children {
            content += visit(child)
        }
        if content.hasPrefix("<p>") && content.hasSuffix("</p>\n") {
            let start = content.index(content.startIndex, offsetBy: 3)
            let end = content.index(content.endIndex, offsetBy: -5)
            content = String(content[start..<end])
        }
        return "<li>\(content)</li>\n"
    }
    
    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        var content = ""
        for child in emphasis.children {
            content += visit(child)
        }
        return "<em>\(content)</em>"
    }
    
    mutating func visitStrong(_ strong: Strong) -> String {
        var content = ""
        for child in strong.children {
            content += visit(child)
        }
        return "<strong>\(content)</strong>"
    }
    
    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        var content = ""
        for child in strikethrough.children {
            content += visit(child)
        }
        return "<del>\(content)</del>"
    }
    
    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        let escaped = HTMLSanitizer.escapeHTML(inlineCode.code)
        return "<code>\(escaped)</code>"
    }
    
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let rawCode = codeBlock.code
        let langId = codeBlock.language?.trimmingCharacters(in: .whitespacesAndNewlines)
        let supportedLang = SupportedLanguage.from(identifier: langId)
        
        let highlightedCode: String
        if settings.enableSyntaxHighlighting {
            highlightedCode = SyntaxHighlighter.shared.highlight(code: rawCode, languageIdentifier: langId)
        } else {
            highlightedCode = HTMLSanitizer.escapeHTML(rawCode)
        }
        
        var headerHTML = ""
        if let lang = langId, !lang.isEmpty {
            let label = supportedLang != .unknown ? supportedLang.displayName : lang.uppercased()
            headerHTML = "<div class=\"code-header\"><span>\(HTMLSanitizer.escapeHTML(label))</span></div>"
        }
        
        let langClass = langId.map { " class=\"language-\(HTMLSanitizer.escapeHTML($0))\"" } ?? ""
        return """
        <pre>\(headerHTML)<code\(langClass)>\(highlightedCode)</code></pre>\n
        """
    }
    
    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        return "<hr>\n"
    }
    
    mutating func visitTable(_ table: Table) -> String {
        var content = ""
        for child in table.children {
            content += visit(child)
        }
        return "<table>\n\(content)</table>\n"
    }
    
    mutating func visitTableHead(_ head: Table.Head) -> String {
        var content = ""
        for child in head.children {
            content += visit(child)
        }
        return "<thead>\n\(content)</thead>\n"
    }
    
    mutating func visitTableBody(_ body: Table.Body) -> String {
        var content = ""
        for child in body.children {
            content += visit(child)
        }
        return "<tbody>\n\(content)</tbody>\n"
    }
    
    mutating func visitTableRow(_ row: Table.Row) -> String {
        var content = ""
        for child in row.children {
            content += visit(child)
        }
        return "<tr>\n\(content)</tr>\n"
    }
    
    mutating func visitTableCell(_ cell: Table.Cell) -> String {
        var content = ""
        for child in cell.children {
            content += visit(child)
        }
        
        let tag = (cell.parent is Table.Head) ? "th" : "td"
        return "<\(tag)>\(content)</\(tag)>\n"
    }
    
    mutating func visitLink(_ link: Link) -> String {
        let destination = link.destination ?? ""
        let safeURL = HTMLSanitizer.sanitizeURL(destination)
        
        var titleAttr = ""
        if let title = link.title, !title.isEmpty {
            titleAttr = " title=\"\(HTMLSanitizer.escapeHTML(title))\""
        }
        
        var textContent = ""
        for child in link.children {
            textContent += visit(child)
        }
        
        return "<a href=\"\(safeURL)\" target=\"_blank\" rel=\"noopener noreferrer\"\(titleAttr)>\(textContent)</a>"
    }
    
    mutating func visitImage(_ image: Image) -> String {
        let source = image.source ?? ""
        let alt = image.plainText
        
        let resolved = ResourceResolver.resolveImage(
            source: source,
            alt: alt,
            documentURL: documentURL,
            allowRemoteImages: settings.allowRemoteImages
        )
        
        if resolved.isBlockedRemote {
            return "<span class=\"image-blocked\">🔒 Remote image blocked (\(HTMLSanitizer.escapeHTML(resolved.altText)))</span>"
        }
        
        if resolved.isError {
            let msg = resolved.errorMessage ?? "Image error"
            return "<span class=\"image-error\">⚠️ \(HTMLSanitizer.escapeHTML(msg))</span>"
        }
        
        var titleAttr = ""
        if let title = image.title, !title.isEmpty {
            titleAttr = " title=\"\(HTMLSanitizer.escapeHTML(title))\""
        }
        
        return "<img src=\"\(resolved.src)\" alt=\"\(HTMLSanitizer.escapeHTML(resolved.altText))\" loading=\"lazy\"\(titleAttr)>"
    }
    
    mutating func visitText(_ text: Text) -> String {
        return HTMLSanitizer.escapeHTML(text.string)
    }
    
    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> String {
        return HTMLSanitizer.sanitizeRawHTML(inlineHTML.rawHTML)
    }
    
    mutating func visitHTMLBlock(_ htmlBlock: HTMLBlock) -> String {
        return HTMLSanitizer.sanitizeRawHTML(htmlBlock.rawHTML) + "\n"
    }
    
    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        return "\n"
    }
    
    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        return "<br>\n"
    }
}
