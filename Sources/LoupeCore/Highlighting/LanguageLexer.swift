import Foundation

public enum TokenType: Sendable {
    case plain
    case keyword
    case typeName
    case string
    case number
    case comment
    case attribute
    case functionName
    case property
    case operatorChar
    case punctuation
    case tag
    case tagAttribute
}

public struct HighlightToken: Sendable, Equatable {
    public let type: TokenType
    public let text: String
    
    public init(type: TokenType, text: String) {
        self.type = type
        self.text = text
    }
}
public typealias SyntaxToken = HighlightToken

public enum SupportedLanguage: String, CaseIterable, Sendable {
    case swift
    case rust
    case python
    case javascript = "js"
    case typescript = "ts"
    case json
    case yaml = "yml"
    case html
    case xml
    case css
    case sql
    case bash = "sh"
    case java
    case kotlin = "kt"
    case markdown = "md"
    case c
    case cpp = "cpp"
    case go
    case php
    case ruby = "rb"
    case docker = "dockerfile"
    case toml
    case unknown
    
    public static func from(identifier: String?) -> SupportedLanguage {
        guard let id = identifier?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else {
            return .unknown
        }
        switch id {
        case "swift": return .swift
        case "rust", "rs": return .rust
        case "python", "py", "pyw": return .python
        case "javascript", "js", "mjs", "cjs": return .javascript
        case "typescript", "ts", "tsx", "jsx": return .typescript
        case "json", "jsonc": return .json
        case "yaml", "yml": return .yaml
        case "html", "htm", "xhtml": return .html
        case "xml", "plist", "svg": return .xml
        case "css", "scss", "sass", "less": return .css
        case "sql": return .sql
        case "bash", "sh", "zsh", "shell", "makefile", "make": return .bash
        case "java": return .java
        case "kotlin", "kt", "kts": return .kotlin
        case "markdown", "md", "mdown", "mkd": return .markdown
        case "c", "h": return .c
        case "cpp", "c++", "cc", "cxx", "hpp", "hxx", "h++": return .cpp
        case "go", "golang": return .go
        case "php": return .php
        case "ruby", "rb": return .ruby
        case "dockerfile", "docker": return .docker
        case "toml", "ini", "conf", "env": return .toml
        default: return .unknown
        }
    }
    
    public var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .rust: return "Rust"
        case .python: return "Python"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .json: return "JSON"
        case .yaml: return "YAML"
        case .html: return "HTML"
        case .xml: return "XML"
        case .css: return "CSS"
        case .sql: return "SQL"
        case .bash: return "Shell"
        case .java: return "Java"
        case .kotlin: return "Kotlin"
        case .markdown: return "Markdown"
        case .c: return "C"
        case .cpp: return "C++"
        case .go: return "Go"
        case .php: return "PHP"
        case .ruby: return "Ruby"
        case .docker: return "Dockerfile"
        case .toml: return "TOML"
        case .unknown: return ""
        }
    }
}
