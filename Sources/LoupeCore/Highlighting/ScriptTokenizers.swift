import Foundation

// Tokenizer fuer Windows-Skripte: PowerShell (.ps1/.psm1/.psd1) und Batch (.bat/.cmd).
//
// Grundregel fuer jeden Zweig: das aktuelle Zeichen wird IMMER verbraucht.
// Ein Zweig, der ein Token beginnt, ohne es zu verbrauchen, haengt den ganzen
// Tokenizer auf (so geschehen mit "$" im allgemeinen Tokenizer).

extension SyntaxHighlighter {

    // MARK: - PowerShell

    private static let psKeywords: Set<String> = [
        "begin", "break", "catch", "class", "continue", "data", "do", "dynamicparam", "else",
        "elseif", "end", "enum", "exit", "filter", "finally", "for", "foreach", "function",
        "if", "in", "param", "process", "return", "switch", "throw", "trap", "try", "until",
        "using", "while", "workflow", "hidden", "static", "default"
    ]

    /// Vergleichs- und Logikoperatoren in Wortform (`-eq`, `-like`, `-and`, …).
    private static let psOperators: Set<String> = [
        "eq", "ne", "gt", "ge", "lt", "le", "like", "notlike", "match", "notmatch",
        "contains", "notcontains", "in", "notin", "replace", "split", "join", "is", "isnot",
        "as", "and", "or", "not", "xor", "band", "bor", "bxor", "bnot", "shl", "shr", "f",
        "ceq", "cne", "clike", "cmatch", "ieq", "ine", "ilike", "imatch"
    ]

    private static let psSizeSuffixes: Set<String> = ["kb", "mb", "gb", "tb", "pb"]

    func tokenizePowerShell(code: String) -> String {
        let chars = Array(code)
        let count = chars.count
        var out = ""
        out.reserveCapacity(code.count * 2)
        var i = 0

        func isNameChar(_ c: Character) -> Bool { c.isLetter || c.isNumber || c == "_" }
        func at(_ k: Int) -> Character? { k < count ? chars[k] : nil }

        while i < count {
            let c = chars[i]

            // Blockkommentar <# ... #>
            if c == "<", at(i + 1) == "#" {
                var j = i + 2
                while j < count, !(chars[j] == "#" && at(j + 1) == ">") { j += 1 }
                j = min(count, j + 2)
                out += wrapToken(String(chars[i..<j]), .comment)
                i = j
                continue
            }

            // Zeilenkommentar (auch #Requires)
            if c == "#" {
                var j = i
                while j < count, chars[j] != "\n" { j += 1 }
                out += wrapToken(String(chars[i..<j]), .comment)
                i = j
                continue
            }

            // Here-String @" … "@ bzw. @' … '@ -- endet an "@/'@ am Zeilenanfang
            if c == "@", let q = at(i + 1), q == "\"" || q == "'",
               at(i + 2) == "\n" || (at(i + 2) == "\r" && at(i + 3) == "\n") {
                var j = i + 2
                while j < count, !(chars[j] == "\n" && at(j + 1) == q && at(j + 2) == "@") { j += 1 }
                j = min(count, j + 3)
                let text = String(chars[i..<j])
                out += q == "\"" ? psInterpolated(text) : wrapToken(text, .string)
                i = j
                continue
            }

            // "…": Backtick maskiert, "" ist ein Anfuehrungszeichen, Variablen werden eingesetzt
            if c == "\"" {
                var j = i + 1
                while j < count {
                    if chars[j] == "`" { j += 2; continue }
                    if chars[j] == "\"" {
                        if at(j + 1) == "\"" { j += 2; continue }
                        j += 1
                        break
                    }
                    j += 1
                }
                j = min(count, j)
                out += psInterpolated(String(chars[i..<j]))
                i = j
                continue
            }

            // '…': woertlich, '' ist ein Apostroph
            if c == "'" {
                var j = i + 1
                while j < count {
                    if chars[j] == "'" {
                        if at(j + 1) == "'" { j += 2; continue }
                        j += 1
                        break
                    }
                    j += 1
                }
                j = min(count, j)
                out += wrapToken(String(chars[i..<j]), .string)
                i = j
                continue
            }

            // Variablen: $name, $env:PATH, ${beliebig}, $_, $?, $true/$false/$null
            if c == "$" {
                let j = psVariableEnd(chars, from: i)
                if j > i + 1 {
                    let v = String(chars[i..<j])
                    let lower = v.lowercased()
                    let isConstant = lower == "$true" || lower == "$false" || lower == "$null"
                    out += wrapToken(v, isConstant ? .keyword : .property)
                    i = j
                } else {
                    out += wrapToken("$", .operatorChar)
                    i += 1
                }
                continue
            }

            // Typ-Literal [string], [System.IO.File]
            if c == "[", let first = at(i + 1), first.isLetter || first == "_" {
                var j = i + 1
                while j < count, isNameChar(chars[j]) || chars[j] == "." { j += 1 }
                if at(j) == "]" {
                    out += wrapToken("[", .punctuation)
                    out += wrapToken(String(chars[(i + 1)..<j]), .typeName)
                    out += wrapToken("]", .punctuation)
                    i = j + 1
                    continue
                }
                out += wrapToken("[", .punctuation)
                i += 1
                continue
            }

            // -Parameter bzw. -Operator
            if c == "-", let next = at(i + 1), next.isLetter,
               i == 0 || !isNameChar(chars[i - 1]) {
                var j = i + 1
                while j < count, isNameChar(chars[j]) { j += 1 }
                let word = String(chars[(i + 1)..<j])
                let type: TokenType = Self.psOperators.contains(word.lowercased()) ? .keyword : .attribute
                out += wrapToken("-" + word, type)
                i = j
                continue
            }

            // Zahlen inkl. 0x1F und Groessen-Suffix (10MB)
            if c.isNumber {
                // Bei i + 1 beginnen: "½" oder "٣" sind isNumber, aber keine Hex-Ziffer --
                // mit j = i blieb der Tokenizer an ihnen stehen (vom ASCII-Test gefunden).
                var j = i + 1
                while j < count, chars[j].isHexDigit || chars[j] == "." || chars[j] == "x" || chars[j] == "X" || chars[j] == "_" {
                    j += 1
                }
                if j + 1 < count, Self.psSizeSuffixes.contains(String(chars[j...(j + 1)]).lowercased()),
                   j + 2 >= count || !isNameChar(chars[j + 2]) {
                    j += 2
                }
                out += wrapToken(String(chars[i..<j]), .number)
                i = j
                continue
            }

            // Woerter: Schluesselwoerter, Cmdlets (Verb-Noun), Funktionsaufrufe
            if c.isLetter || c == "_" {
                var j = i
                while j < count {
                    if isNameChar(chars[j]) { j += 1; continue }
                    // Bindestrich nur INNERHALB eines Namens (Get-ChildItem)
                    if chars[j] == "-", j > i, let n = at(j + 1), n.isLetter { j += 1; continue }
                    break
                }
                let word = String(chars[i..<j])
                let type: TokenType
                if Self.psKeywords.contains(word.lowercased()) {
                    type = .keyword
                } else if word.contains("-") || at(j) == "(" {
                    type = .functionName
                } else {
                    type = .plain
                }
                out += wrapToken(word, type)
                i = j
                continue
            }

            if "+-*/%=<>!|&,;.:".contains(c) {
                out += wrapToken(String(c), .operatorChar)
            } else if "{}()[]".contains(c) {
                out += wrapToken(String(c), .punctuation)
            } else {
                out += HTMLSanitizer.escapeHTML(String(c))
            }
            i += 1
        }
        return out
    }

    /// Ende einer Variablen ab `$` bei `start` (exklusiv). `start + 1` = keine Variable.
    private func psVariableEnd(_ chars: [Character], from start: Int) -> Int {
        let count = chars.count
        var j = start + 1
        guard j < count else { return j }
        if chars[j] == "{" {
            while j < count, chars[j] != "}", chars[j] != "\n" { j += 1 }
            return j < count && chars[j] == "}" ? j + 1 : start + 1
        }
        // Automatische Variablen $?, $^, $$ ($_ laeuft unten als normaler Name)
        if "?^$".contains(chars[j]) { return j + 1 }
        let nameStart = j
        while j < count, chars[j].isLetter || chars[j].isNumber || chars[j] == "_" { j += 1 }
        guard j > nameStart else { return start + 1 }
        // Bereich: $env:PATH, $script:count, $global:x
        if j + 1 < count, chars[j] == ":", chars[j + 1].isLetter || chars[j + 1] == "_" {
            j += 1
            while j < count, chars[j].isLetter || chars[j].isNumber || chars[j] == "_" { j += 1 }
        }
        return j
    }

    /// Doppelt quotierter Text mit hervorgehobenen Variablen und $(…)-Ausdruecken.
    private func psInterpolated(_ text: String) -> String {
        let chars = Array(text)
        let count = chars.count
        var out = ""
        var segment = ""
        var i = 0
        func flush() {
            if !segment.isEmpty { out += wrapToken(segment, .string); segment = "" }
        }
        while i < count {
            let c = chars[i]
            if c == "`", i + 1 < count {
                segment.append(c)
                segment.append(chars[i + 1])
                i += 2
                continue
            }
            if c == "$", i + 1 < count, chars[i + 1] == "(" {
                var depth = 0
                var j = i + 1
                while j < count {
                    if chars[j] == "(" { depth += 1 }
                    if chars[j] == ")" { depth -= 1; if depth == 0 { j += 1; break } }
                    j += 1
                }
                flush()
                out += wrapToken(String(chars[i..<min(j, count)]), .property)
                i = min(j, count)
                continue
            }
            if c == "$" {
                let j = psVariableEnd(chars, from: i)
                if j > i + 1 {
                    flush()
                    out += wrapToken(String(chars[i..<j]), .property)
                    i = j
                    continue
                }
            }
            segment.append(c)
            i += 1
        }
        flush()
        return out
    }

    // MARK: - Batch (.bat / .cmd)

    private static let batchKeywords: Set<String> = [
        "echo", "set", "setlocal", "endlocal", "if", "else", "not", "exist", "defined",
        "errorlevel", "equ", "neq", "lss", "leq", "gtr", "geq", "for", "in", "do", "goto",
        "call", "exit", "pause", "shift", "start", "cd", "chdir", "pushd", "popd", "cls",
        "title", "color", "mkdir", "md", "rmdir", "rd", "del", "erase", "copy", "xcopy",
        "robocopy", "move", "ren", "rename", "type", "choice", "timeout", "where", "ver",
        "enabledelayedexpansion", "disabledelayedexpansion", "enableextensions", "cmdextversion"
    ]

    func tokenizeBatch(code: String) -> String {
        var out = ""
        out.reserveCapacity(code.count * 2)
        let lines = code.split(omittingEmptySubsequences: false, whereSeparator: { $0 == "\n" || $0 == "\r\n" })
        for (index, line) in lines.enumerated() {
            if index > 0 { out += "\n" }
            out += batchLine(Array(line))
        }
        return out
    }

    private func batchLine(_ chars: [Character]) -> String {
        let count = chars.count
        var out = ""
        var i = 0
        while i < count, chars[i] == " " || chars[i] == "\t" {
            out.append(chars[i])
            i += 1
        }
        let rest = String(chars[i...])
        let lower = rest.lowercased()

        // Kommentare: "::" und REM (nur als eigenes Wort -- "REMOTE" ist keiner)
        let remStart = lower.hasPrefix("@rem") ? 4 : (lower.hasPrefix("rem") ? 3 : -1)
        let isRem = remStart > 0 && (lower.count == remStart
            || " \t.:,;=/\\".contains(Array(lower)[remStart]))
        if rest.hasPrefix("::") || isRem {
            return out + wrapToken(rest, .comment)
        }

        // Sprungmarke am Zeilenanfang
        if rest.hasPrefix(":") {
            var j = i + 1
            while j < count, chars[j] != " ", chars[j] != "\t" { j += 1 }
            out += wrapToken(String(chars[i..<j]), .functionName)
            i = j
        }

        func at(_ k: Int) -> Character? { k < count ? chars[k] : nil }
        func isWordChar(_ c: Character) -> Bool { c.isLetter || c.isNumber || c == "_" }

        while i < count {
            let c = chars[i]

            if c == "%" || c == "!", let end = batchVariableEnd(chars, from: i) {
                out += wrapToken(String(chars[i..<end]), .property)
                i = end
                continue
            }

            if c == "\"" {
                var j = i + 1
                while j < count, chars[j] != "\"" { j += 1 }
                j = min(count, j + 1)
                out += batchString(Array(chars[i..<j]))
                i = j
                continue
            }

            // Sprungziel mitten in der Zeile: goto :eof, call :sub
            if c == ":", let n = at(i + 1), n.isLetter || n == "_",
               i > 0, chars[i - 1] == " " || chars[i - 1] == "\t" {
                var j = i + 1
                while j < count, isWordChar(chars[j]) { j += 1 }
                out += wrapToken(String(chars[i..<j]), .functionName)
                i = j
                continue
            }

            // Schalter /b, /a, /r
            if c == "/", let n = at(i + 1), n.isLetter,
               i == 0 || chars[i - 1] == " " || chars[i - 1] == "\t" {
                var j = i + 1
                while j < count, isWordChar(chars[j]) { j += 1 }
                out += wrapToken(String(chars[i..<j]), .attribute)
                i = j
                continue
            }

            if c.isNumber, i == 0 || !isWordChar(chars[i - 1]) {
                var j = i
                while j < count, chars[j].isNumber { j += 1 }
                if j == count || !isWordChar(chars[j]) {
                    out += wrapToken(String(chars[i..<j]), .number)
                    i = j
                    continue
                }
            }

            if c.isLetter || c == "_" {
                var j = i
                while j < count, isWordChar(chars[j]) { j += 1 }
                let word = String(chars[i..<j])
                out += wrapToken(word, Self.batchKeywords.contains(word.lowercased()) ? .keyword : .plain)
                i = j
                continue
            }

            if "@|&<>=".contains(c) {
                out += wrapToken(String(c), .operatorChar)
            } else if "()".contains(c) {
                out += wrapToken(String(c), .punctuation)
            } else {
                out += HTMLSanitizer.escapeHTML(String(c))
            }
            i += 1
        }
        return out
    }

    /// Ende einer Batch-Variablen ab `start`, oder nil wenn dort keine beginnt.
    /// Formen: %1, %*, %~dp0, %%i, %%~nxf, %NAME%, %NAME:~0,4%, !NAME!
    private func batchVariableEnd(_ chars: [Character], from start: Int) -> Int? {
        let count = chars.count
        let c = chars[start]
        var j = start + 1
        guard j < count else { return nil }

        if c == "%" {
            if chars[j] == "%" {                       // %%i, %%~nxf
                j += 1
                if j < count, chars[j] == "~" {
                    j += 1
                    while j + 1 < count, chars[j].isLetter, chars[j + 1].isLetter { j += 1 }
                }
                return j < count && chars[j].isLetter ? j + 1 : nil
            }
            if chars[j].isNumber || chars[j] == "*" { return j + 1 }   // %1, %*
            if chars[j] == "~" {                        // %~dp0
                j += 1
                while j < count, chars[j].isLetter { j += 1 }
                return j < count && chars[j].isNumber ? j + 1 : nil
            }
        }
        // %NAME% bzw. !NAME! -- ohne Leerzeichen, auf derselben Zeile geschlossen
        while j < count, chars[j] != c {
            if chars[j] == " " || chars[j] == "\t" || chars[j] == "\"" { return nil }
            j += 1
        }
        guard j < count, j > start + 1 else { return nil }
        return j + 1
    }

    private func batchString(_ chars: [Character]) -> String {
        var out = ""
        var segment = ""
        var i = 0
        while i < chars.count {
            if chars[i] == "%" || chars[i] == "!", let end = batchVariableEnd(chars, from: i) {
                if !segment.isEmpty { out += wrapToken(segment, .string); segment = "" }
                out += wrapToken(String(chars[i..<end]), .property)
                i = end
                continue
            }
            segment.append(chars[i])
            i += 1
        }
        if !segment.isEmpty { out += wrapToken(segment, .string) }
        return out
    }
}
