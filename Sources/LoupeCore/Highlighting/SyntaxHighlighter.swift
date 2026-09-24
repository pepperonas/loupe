import Foundation

public final class SyntaxHighlighter: Sendable {
    public static let shared = SyntaxHighlighter()

    private let swiftKeywords: Set<String> = [
        "actor", "any", "as", "associatedtype", "async", "await", "break", "case", "catch",
        "class", "continue", "default", "defer", "deinit", "do", "else", "enum", "extension",
        "fallthrough", "false", "fileprivate", "final", "for", "func", "guard", "if", "import",
        "in", "init", "inout", "internal", "is", "let", "mutating", "nil", "nonisolated",
        "open", "operator", "override", "private", "protocol", "public", "repeat", "rethrows",
        "return", "self", "Self", "some", "static", "struct", "subscript", "super", "switch",
        "throws", "true", "try", "typealias", "var", "where", "while", "yield"
    ]

    private let rustKeywords: Set<String> = [
        "as", "async", "await", "break", "const", "continue", "crate", "dyn", "else", "enum",
        "extern", "false", "fn", "for", "if", "impl", "in", "let", "loop", "match", "mod",
        "move", "mut", "pub", "ref", "return", "self", "Self", "static", "struct", "super",
        "trait", "true", "type", "unsafe", "use", "where", "while"
    ]
    
    private let pythonKeywords: Set<String> = [
        "and", "as", "assert", "async", "await", "break", "class", "continue", "def", "del",
        "elif", "else", "except", "False", "finally", "for", "from", "global", "if", "import",
        "in", "is", "lambda", "None", "nonlocal", "not", "or", "pass", "raise", "return",
        "True", "try", "while", "with", "yield", "self"
    ]
    
    private let jsTsKeywords: Set<String> = [
        "async", "await", "break", "case", "catch", "class", "const", "continue", "debugger",
        "default", "delete", "do", "else", "export", "extends", "false", "finally", "for",
        "function", "if", "import", "in", "instanceof", "let", "new", "null", "return",
        "super", "switch", "this", "throw", "true", "try", "typeof", "undefined", "var",
        "void", "while", "with", "yield", "interface", "type", "enum", "implements", "public",
        "private", "protected", "readonly", "as", "from"
    ]
    
    private let javaKotlinKeywords: Set<String> = [
        "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char", "class",
        "const", "continue", "default", "do", "double", "else", "enum", "extends", "final",
        "finally", "float", "for", "goto", "if", "implements", "import", "instanceof", "int",
        "interface", "long", "native", "new", "null", "package", "private", "protected", "public",
        "return", "short", "static", "strictfp", "super", "switch", "synchronized", "this",
        "throw", "throws", "transient", "true", "false", "try", "void", "volatile", "while",
        "val", "var", "fun", "when", "data", "sealed", "open", "override", "suspend"
    ]
    
    private let sqlKeywords: Set<String> = [
        "SELECT", "FROM", "WHERE", "INSERT", "INTO", "UPDATE", "DELETE", "JOIN", "LEFT",
        "RIGHT", "INNER", "OUTER", "FULL", "ON", "GROUP", "BY", "ORDER", "HAVING", "LIMIT",
        "OFFSET", "CREATE", "TABLE", "DROP", "ALTER", "INDEX", "VIEW", "AS", "DISTINCT",
        "UNION", "ALL", "AND", "OR", "NOT", "NULL", "IS", "IN", "BETWEEN", "LIKE", "EXISTS",
        "CASE", "WHEN", "THEN", "ELSE", "END", "PRIMARY", "KEY", "FOREIGN", "REFERENCES",
        "DEFAULT", "CHECK", "UNIQUE", "CONSTRAINT", "CASCADE", "SET", "VALUES"
    ]
    
    private let bashKeywords: Set<String> = [
        "if", "then", "else", "elif", "fi", "case", "esac", "for", "while", "until", "do",
        "done", "in", "function", "select", "time", "return", "exit", "export", "local",
        "readonly", "echo", "cd", "pwd", "source", "alias", "set", "unset"
    ]
    
    private let cCppKeywords: Set<String> = [
        "auto", "break", "case", "char", "const", "continue", "default", "do", "double",
        "else", "enum", "extern", "float", "for", "goto", "if", "inline", "int", "long",
        "register", "restrict", "return", "short", "signed", "sizeof", "static", "struct",
        "switch", "typedef", "union", "unsigned", "void", "volatile", "while",
        "class", "namespace", "template", "typename", "this", "friend", "virtual",
        "public", "protected", "private", "operator", "try", "catch", "throw",
        "new", "delete", "nullptr", "true", "false", "constexpr", "override", "final",
        "using", "decltype", "noexcept", "static_assert"
    ]

    private let goKeywords: Set<String> = [
        "break", "case", "chan", "const", "continue", "default", "defer", "else",
        "fallthrough", "for", "func", "go", "goto", "if", "import", "interface",
        "map", "package", "range", "return", "select", "struct", "switch", "type", "var",
        "nil", "true", "false", "iota"
    ]

    private let phpKeywords: Set<String> = [
        "abstract", "and", "array", "as", "break", "callable", "case", "catch", "class",
        "clone", "const", "continue", "declare", "default", "die", "do", "echo", "else",
        "elseif", "empty", "endfor", "endforeach", "endif", "endswitch", "endwhile", "eval",
        "exit", "extends", "final", "finally", "fn", "for", "foreach", "function", "global",
        "goto", "if", "implements", "include", "include_once", "instanceof", "insteadof",
        "interface", "isset", "list", "match", "namespace", "new", "or", "print", "private",
        "protected", "public", "readonly", "require", "require_once", "return", "static",
        "switch", "throw", "trait", "try", "unset", "use", "var", "while", "xor", "yield"
    ]

    private let rubyKeywords: Set<String> = [
        "alias", "and", "begin", "break", "case", "class", "def", "defined?", "do",
        "else", "elsif", "end", "ensure", "false", "for", "if", "in", "module",
        "next", "nil", "not", "or", "redo", "rescue", "retry", "return", "self",
        "super", "then", "true", "undef", "unless", "until", "when", "while", "yield"
    ]

    public init() {}
    
    public func highlight(code: String, languageIdentifier: String?) -> String {
        let lang = SupportedLanguage.from(identifier: languageIdentifier)
        if lang == .unknown && (languageIdentifier == nil || languageIdentifier!.isEmpty) {
            return HTMLSanitizer.escapeHTML(code)
        }
        
        switch lang {
        case .swift:
            return tokenizeGeneral(code: code, keywords: swiftKeywords, lineComment: "//", blockCommentStart: "/*", blockCommentEnd: "*/")
        case .rust:
            return tokenizeGeneral(code: code, keywords: rustKeywords, lineComment: "//", blockCommentStart: "/*", blockCommentEnd: "*/")
        case .python:
            return tokenizeGeneral(code: code, keywords: pythonKeywords, lineComment: "#", blockCommentStart: nil, blockCommentEnd: nil)
        case .javascript, .typescript:
            return tokenizeGeneral(code: code, keywords: jsTsKeywords, lineComment: "//", blockCommentStart: "/*", blockCommentEnd: "*/")
        case .java, .kotlin:
            return tokenizeGeneral(code: code, keywords: javaKotlinKeywords, lineComment: "//", blockCommentStart: "/*", blockCommentEnd: "*/")
        case .c, .cpp:
            return tokenizeGeneral(code: code, keywords: cCppKeywords, lineComment: "//", blockCommentStart: "/*", blockCommentEnd: "*/")
        case .go:
            return tokenizeGeneral(code: code, keywords: goKeywords, lineComment: "//", blockCommentStart: "/*", blockCommentEnd: "*/")
        case .php:
            return tokenizeGeneral(code: code, keywords: phpKeywords, lineComment: "//", blockCommentStart: "/*", blockCommentEnd: "*/")
        case .ruby:
            return tokenizeGeneral(code: code, keywords: rubyKeywords, lineComment: "#", blockCommentStart: "=begin", blockCommentEnd: "=end")
        case .yaml, .toml:
            return tokenizeGeneral(code: code, keywords: ["true", "false", "yes", "no", "null"], lineComment: "#", blockCommentStart: nil, blockCommentEnd: nil)
        case .docker:
            return tokenizeGeneral(code: code, keywords: ["FROM", "RUN", "CMD", "LABEL", "EXPOSE", "ENV", "ADD", "COPY", "ENTRYPOINT", "VOLUME", "USER", "WORKDIR", "ARG", "ONBUILD", "STOPSIGNAL", "HEALTHCHECK", "SHELL"], lineComment: "#", blockCommentStart: nil, blockCommentEnd: nil)
        case .sql:
            return tokenizeSQL(code: code)
        case .bash:
            return tokenizeBash(code: code)
        case .json:
            return tokenizeJSON(code: code)
        case .html:
            return tokenizeMarkup(code: code, isHTML: true)
        case .xml:
            return tokenizeMarkup(code: code, isHTML: false)
        case .css:
            return tokenizeCSS(code: code)
        case .powershell:
            return tokenizePowerShell(code: code)
        case .batch:
            return tokenizeBatch(code: code)
        default:
            // Fallback: tokenize general with common C-style comments and keywords
            return tokenizeGeneral(code: code, keywords: swiftKeywords, lineComment: "//", blockCommentStart: "/*", blockCommentEnd: "*/")
        }
    }
    
    private func cssClass(for type: TokenType) -> String? {
        switch type {
        case .plain: return nil
        case .keyword: return "hl-kw"
        case .typeName: return "hl-type"
        case .string: return "hl-str"
        case .number: return "hl-num"
        case .comment: return "hl-com"
        case .attribute: return "hl-attr"
        case .functionName: return "hl-fn"
        case .property: return "hl-prop"
        case .operatorChar: return "hl-op"
        case .punctuation: return "hl-punct"
        case .tag: return "hl-tag"
        case .tagAttribute: return "hl-attr"
        }
    }

    func wrapToken(_ text: String, _ type: TokenType) -> String {
        let escaped = HTMLSanitizer.escapeHTML(text)
        guard let cls = cssClass(for: type) else { return escaped }
        if escaped.contains("\n") {
            let parts = escaped.components(separatedBy: "\n")
            return parts.map { "<span class=\"\(cls)\">\($0)</span>" }.joined(separator: "\n")
        }
        return "<span class=\"\(cls)\">\(escaped)</span>"
    }
    
    private func tokenizeGeneral(
        code: String,
        keywords: Set<String>,
        lineComment: String,
        blockCommentStart: String?,
        blockCommentEnd: String?
    ) -> String {
        var output = ""
        output.reserveCapacity(code.count * 2)
        let chars = Array(code)
        var i = 0
        let count = chars.count
        let lineCommentChars = Array(lineComment)
        let blockCommentStartChars = blockCommentStart.map(Array.init)
        let blockCommentEndChars = blockCommentEnd.map(Array.init)
        
        while i < count {
            let c = chars[i]
            
            // Block comment
            if let startChars = blockCommentStartChars,
               let endChars = blockCommentEndChars,
               matchPrefix(chars, i, startChars) {
                var comment = String(startChars)
                i += startChars.count
                while i < count && !matchPrefix(chars, i, endChars) {
                    comment.append(chars[i])
                    i += 1
                }
                if i < count && matchPrefix(chars, i, endChars) {
                    comment.append(contentsOf: endChars)
                    i += endChars.count
                }
                output.append(wrapToken(comment, .comment))
                continue
            }
            
            // Line comment
            if matchPrefix(chars, i, lineCommentChars) {
                var comment = ""
                while i < count && chars[i] != "\n" {
                    comment.append(chars[i])
                    i += 1
                }
                output.append(wrapToken(comment, .comment))
                continue
            }
            
            // Strings: "..." or '...' or `...`
            if c == "\"" || c == "'" || c == "`" {
                let quote = c
                var str = String(quote)
                i += 1
                // Check for triple quotes
                let isTriple = (quote == "\"" && i + 1 < count && chars[i] == "\"" && chars[i+1] == "\"")
                if isTriple {
                    str.append("\"\"")
                    i += 2
                    while i < count {
                        if chars[i] == "\"" && i + 2 < count && chars[i+1] == "\"" && chars[i+2] == "\"" {
                            str.append("\"\"\"")
                            i += 3
                            break
                        }
                        str.append(chars[i])
                        i += 1
                    }
                } else {
                    var escaped = false
                    while i < count {
                        let cur = chars[i]
                        str.append(cur)
                        i += 1
                        if escaped {
                            escaped = false
                        } else if cur == "\\" {
                            escaped = true
                        } else if cur == quote {
                            break
                        } else if cur == "\n" {
                            break // unclosed single line string
                        }
                    }
                }
                output.append(wrapToken(str, .string))
                continue
            }
            
            // Numbers
            if c.isNumber || (c == "." && i + 1 < count && chars[i+1].isNumber) {
                var num = ""
                while i < count && (chars[i].isNumber || chars[i] == "." || chars[i] == "x" || chars[i] == "X" || chars[i] == "_" || (chars[i] >= "a" && chars[i] <= "f") || (chars[i] >= "A" && chars[i] <= "F")) {
                    num.append(chars[i])
                    i += 1
                }
                output.append(wrapToken(num, .number))
                continue
            }
            
            // Attributes (@available, #[derive])
            if c == "@" || (c == "#" && i + 1 < count && chars[i+1] == "[") {
                var attr = String(c)
                i += 1
                while i < count && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_" || chars[i] == "[" || chars[i] == "]") {
                    attr.append(chars[i])
                    i += 1
                }
                output.append(wrapToken(attr, .attribute))
                continue
            }
            
            // Identifiers / Keywords / Types
            if c.isLetter || c == "_" || c == "$" {
                var word = ""
                // "$" MUSS auch hier stehen: als Anfang erlaubt, aber nicht verbraucht,
                // blieb i stehen -> Endlosschleife bei Swift-"$0" oder jQuery-"$".
                while i < count && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_" || chars[i] == "$") {
                    word.append(chars[i])
                    i += 1
                }
                
                if keywords.contains(word) {
                    output.append(wrapToken(word, .keyword))
                } else if word.first?.isUppercase == true {
                    output.append(wrapToken(word, .typeName))
                } else {
                    // Check if function call (followed by optional whitespace then '(')
                    var peek = i
                    while peek < count && (chars[peek] == " " || chars[peek] == "\t") {
                        peek += 1
                    }
                    if peek < count && chars[peek] == "(" {
                        output.append(wrapToken(word, .functionName))
                    } else {
                        output.append(wrapToken(word, .plain))
                    }
                }
                continue
            }
            
            // Operators and Punctuation
            if "+-*/%=&|!<>^~?:".contains(c) {
                output.append(wrapToken(String(c), .operatorChar))
                i += 1
                continue
            }
            
            if "{}()[],;".contains(c) {
                output.append(wrapToken(String(c), .punctuation))
                i += 1
                continue
            }
            
            output.append(HTMLSanitizer.escapeHTML(String(c)))
            i += 1
        }
        
        return output
    }
    
    private func tokenizeSQL(code: String) -> String {
        var output = ""
        output.reserveCapacity(code.count * 2)
        let chars = Array(code)
        var i = 0
        let count = chars.count
        
        while i < count {
            let c = chars[i]
            
            // Comment -- or /* */
            if matchPrefix(chars, i, "--") {
                var com = ""
                while i < count && chars[i] != "\n" {
                    com.append(chars[i])
                    i += 1
                }
                output.append(wrapToken(com, .comment))
                continue
            }
            if matchPrefix(chars, i, "/*") {
                var com = "/*"
                i += 2
                while i < count && !matchPrefix(chars, i, "*/") {
                    com.append(chars[i])
                    i += 1
                }
                if i < count {
                    com.append("*/")
                    i += 2
                }
                output.append(wrapToken(com, .comment))
                continue
            }
            
            // String '...'
            if c == "'" || c == "\"" {
                let quote = c
                var str = String(quote)
                i += 1
                while i < count {
                    let cur = chars[i]
                    str.append(cur)
                    i += 1
                    if cur == quote { break }
                }
                output.append(wrapToken(str, .string))
                continue
            }
            
            // Numbers
            if c.isNumber {
                var num = ""
                while i < count && (chars[i].isNumber || chars[i] == ".") {
                    num.append(chars[i])
                    i += 1
                }
                output.append(wrapToken(num, .number))
                continue
            }
            
            // Identifiers / Keywords
            if c.isLetter || c == "_" {
                var word = ""
                while i < count && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_") {
                    word.append(chars[i])
                    i += 1
                }
                if sqlKeywords.contains(word.uppercased()) {
                    output.append(wrapToken(word, .keyword))
                } else {
                    output.append(wrapToken(word, .plain))
                }
                continue
            }
            
            output.append(HTMLSanitizer.escapeHTML(String(c)))
            i += 1
        }
        
        return output
    }
    
    private func tokenizeBash(code: String) -> String {
        var output = ""
        output.reserveCapacity(code.count * 2)
        let chars = Array(code)
        var i = 0
        let count = chars.count
        
        while i < count {
            let c = chars[i]
            
            if c == "#" {
                var com = ""
                while i < count && chars[i] != "\n" {
                    com.append(chars[i])
                    i += 1
                }
                output.append(wrapToken(com, .comment))
                continue
            }
            
            if c == "\"" || c == "'" {
                let quote = c
                var str = String(quote)
                i += 1
                while i < count {
                    let cur = chars[i]
                    str.append(cur)
                    i += 1
                    if cur == quote { break }
                }
                output.append(wrapToken(str, .string))
                continue
            }
            
            if c == "$" {
                var v = "$"
                i += 1
                while i < count && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_" || chars[i] == "{" || chars[i] == "}") {
                    v.append(chars[i])
                    i += 1
                }
                output.append(wrapToken(v, .attribute))
                continue
            }
            
            if c.isLetter || c == "_" {
                var word = ""
                while i < count && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_" || chars[i] == "-") {
                    word.append(chars[i])
                    i += 1
                }
                if bashKeywords.contains(word) {
                    output.append(wrapToken(word, .keyword))
                } else {
                    output.append(wrapToken(word, .plain))
                }
                continue
            }
            
            output.append(HTMLSanitizer.escapeHTML(String(c)))
            i += 1
        }
        
        return output
    }
    
    private func tokenizeJSON(code: String) -> String {
        var output = ""
        output.reserveCapacity(code.count * 2)
        let chars = Array(code)
        var i = 0
        let count = chars.count
        
        while i < count {
            let c = chars[i]
            
            if c == "\"" {
                var str = "\""
                i += 1
                var escaped = false
                while i < count {
                    let cur = chars[i]
                    str.append(cur)
                    i += 1
                    if escaped {
                        escaped = false
                    } else if cur == "\\" {
                        escaped = true
                    } else if cur == "\"" {
                        break
                    }
                }
                // Check if key (followed by ':')
                var peek = i
                while peek < count && (chars[peek] == " " || chars[peek] == "\t" || chars[peek] == "\n") {
                    peek += 1
                }
                if peek < count && chars[peek] == ":" {
                    output.append(wrapToken(str, .property))
                } else {
                    output.append(wrapToken(str, .string))
                }
                continue
            }
            
            if c.isNumber || c == "-" {
                var num = String(c)
                i += 1
                while i < count && (chars[i].isNumber || chars[i] == "." || chars[i] == "e" || chars[i] == "E" || chars[i] == "+" || chars[i] == "-") {
                    num.append(chars[i])
                    i += 1
                }
                output.append(wrapToken(num, .number))
                continue
            }
            
            if c.isLetter {
                var word = ""
                while i < count && chars[i].isLetter {
                    word.append(chars[i])
                    i += 1
                }
                if word == "true" || word == "false" || word == "null" {
                    output.append(wrapToken(word, .keyword))
                } else {
                    output.append(wrapToken(word, .plain))
                }
                continue
            }
            
            output.append(HTMLSanitizer.escapeHTML(String(c)))
            i += 1
        }
        
        return output
    }
    
    private func tokenizeCSS(code: String) -> String {
        var output = ""
        output.reserveCapacity(code.count * 2)
        let chars = Array(code)
        var i = 0
        let count = chars.count
        
        while i < count {
            if matchPrefix(chars, i, "/*") {
                var com = "/*"
                i += 2
                while i < count && !matchPrefix(chars, i, "*/") {
                    com.append(chars[i])
                    i += 1
                }
                if i < count {
                    com.append("*/")
                    i += 2
                }
                output.append(wrapToken(com, .comment))
                continue
            }
            
            let c = chars[i]
            if c == "{" || c == "}" || c == ";" || c == ":" {
                output.append(wrapToken(String(c), .punctuation))
                i += 1
                continue
            }
            
            output.append(HTMLSanitizer.escapeHTML(String(c)))
            i += 1
        }
        return output
    }
    
    private func matchPrefix(_ chars: [Character], _ index: Int, _ prefix: String) -> Bool {
        matchPrefix(chars, index, Array(prefix))
    }

    private func matchPrefix(_ chars: [Character], _ index: Int, _ prefixChars: [Character]) -> Bool {
        if index + prefixChars.count > chars.count { return false }
        for j in 0..<prefixChars.count {
            if chars[index + j] != prefixChars[j] { return false }
        }
        return true
    }
}
