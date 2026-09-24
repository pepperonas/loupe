import Foundation

// XML- und HTML-Tokenizer.
//
// Anders als der fruehere Ansatz ("alles von < bis zum naechsten >") liest er
// Tags quote-bewusst: ein ">" in einem Attributwert, in einem Kommentar, in
// CDATA oder im internen DTD-Teil eines DOCTYPE beendet nichts. Jeder Zweig
// verbraucht mindestens ein Zeichen -- sonst haengt der Tokenizer.

extension SyntaxHighlighter {

    func tokenizeMarkup(code: String, isHTML: Bool) -> String {
        let chars = Array(code)
        let count = chars.count
        var out = ""
        out.reserveCapacity(code.count * 2)
        var i = 0
        var text = ""

        func at(_ k: Int) -> Character? { k < count ? chars[k] : nil }
        func starts(_ s: String, _ k: Int) -> Bool {
            var j = k
            for c in s {
                guard j < count, chars[j] == c else { return false }
                j += 1
            }
            return true
        }
        func startsCI(_ s: String, _ k: Int) -> Bool {
            var j = k
            for c in s {
                guard j < count, chars[j].lowercased() == c.lowercased() else { return false }
                j += 1
            }
            return true
        }
        func flushText() {
            if !text.isEmpty { out += markupText(text); text = "" }
        }
        /// Index hinter `end`, oder `count`, wenn `end` nie kommt.
        func scan(to end: String, from k: Int) -> Int {
            var j = k
            while j < count, !starts(end, j) { j += 1 }
            return min(count, j + (j < count ? end.count : 0))
        }
        func isNameStart(_ c: Character) -> Bool { c.isLetter || c == "_" || c == ":" }
        func isNameChar(_ c: Character) -> Bool { c.isLetter || c.isNumber || "_:.-".contains(c) }

        while i < count {
            let c = chars[i]

            guard c == "<" else {
                text.append(c)
                i += 1
                continue
            }

            // Kommentar
            if starts("<!--", i) {
                flushText()
                let j = scan(to: "-->", from: i + 4)
                out += wrapToken(String(chars[i..<j]), .comment)
                i = j
                continue
            }

            // CDATA: Inhalt ist Text, kein Markup
            if starts("<![CDATA[", i) {
                flushText()
                out += wrapToken("<![CDATA[", .keyword)
                var j = i + 9
                while j < count, !starts("]]>", j) { j += 1 }
                if j > i + 9 { out += wrapToken(String(chars[(i + 9)..<j]), .string) }
                if j < count {
                    out += wrapToken("]]>", .keyword)
                    j += 3
                }
                i = j
                continue
            }

            // <!DOCTYPE …> bzw. andere Deklarationen, inkl. [ … ]-Teil
            if at(i + 1) == "!", let n = at(i + 2), n.isLetter {
                flushText()
                var j = i + 2
                while j < count, chars[j].isLetter { j += 1 }
                out += wrapToken(String(chars[i..<j]), .keyword)
                var depth = 0
                var rest = ""
                while j < count {
                    let d = chars[j]
                    if d == "\"" || d == "'" {
                        if !rest.isEmpty { out += HTMLSanitizer.escapeHTML(rest); rest = "" }
                        var k = j + 1
                        while k < count, chars[k] != d { k += 1 }
                        k = min(count, k + 1)
                        out += wrapToken(String(chars[j..<k]), .string)
                        j = k
                        continue
                    }
                    if d == "[" { depth += 1 }
                    if d == "]" { depth = max(0, depth - 1) }
                    if d == ">", depth == 0 { break }
                    rest.append(d)
                    j += 1
                }
                if !rest.isEmpty { out += HTMLSanitizer.escapeHTML(rest) }
                if j < count {
                    out += wrapToken(">", .punctuation)
                    j += 1
                }
                i = j
                continue
            }

            // Processing Instruction <?name … ?>
            if at(i + 1) == "?" {
                flushText()
                out += wrapToken("<?", .punctuation)
                var j = i + 2
                let nameStart = j
                while j < count, isNameChar(chars[j]) { j += 1 }
                if j > nameStart { out += wrapToken(String(chars[nameStart..<j]), .keyword) }
                j = markupAttributes(chars, from: j, into: &out, isHTML: false, closer: "?>")
                i = j
                continue
            }

            // Start- oder End-Tag -- nur wenn wirklich ein Name folgt ("a < b" ist Text)
            let isEnd = at(i + 1) == "/"
            let nameStart = i + (isEnd ? 2 : 1)
            guard let first = at(nameStart), isNameStart(first) else {
                text.append(c)
                i += 1
                continue
            }
            flushText()
            out += wrapToken(isEnd ? "</" : "<", .punctuation)
            var j = nameStart
            while j < count, isNameChar(chars[j]) { j += 1 }
            let name = String(chars[nameStart..<j])
            out += wrapToken(name, .tag)
            j = markupAttributes(chars, from: j, into: &out, isHTML: isHTML, closer: nil)
            i = j

            // HTML: Inhalt von <script>/<style> ist Rohtext bis zum passenden End-Tag
            let lower = name.lowercased()
            if isHTML, !isEnd, lower == "script" || lower == "style",
               i > 0, chars[i - 1] == ">", !(i > 1 && chars[i - 2] == "/") {
                var k = i
                while k < count, !startsCI("</\(lower)", k) { k += 1 }
                if k > i { out += HTMLSanitizer.escapeHTML(String(chars[i..<k])) }
                i = k
            }
        }
        flushText()
        return out
    }

    /// Attribute bis einschliesslich `>`, `/>` bzw. `closer`. Liefert den Index danach.
    private func markupAttributes(_ chars: [Character], from start: Int, into out: inout String,
                                  isHTML: Bool, closer: String?) -> Int {
        let count = chars.count
        var j = start
        func starts(_ s: String, _ k: Int) -> Bool {
            var m = k
            for c in s {
                guard m < count, chars[m] == c else { return false }
                m += 1
            }
            return true
        }
        while j < count {
            let c = chars[j]
            if let closer, starts(closer, j) {
                out += wrapToken(closer, .punctuation)
                return j + closer.count
            }
            if c == ">" {
                out += wrapToken(">", .punctuation)
                return j + 1
            }
            if c == "/", j + 1 < count, chars[j + 1] == ">" {
                out += wrapToken("/>", .punctuation)
                return j + 2
            }
            if c == "=" {
                out += wrapToken("=", .operatorChar)
                j += 1
                continue
            }
            if c == "\"" || c == "'" {
                var k = j + 1
                while k < count, chars[k] != c { k += 1 }
                k = min(count, k + 1)
                out += wrapToken(String(chars[j..<k]), .string)
                j = k
                continue
            }
            if c.isWhitespace {
                out.append(c)
                j += 1
                continue
            }
            // Attributname -- oder (HTML) unquotierter Wert direkt nach "="
            var k = j
            while k < count, !chars[k].isWhitespace, !"=>\"'".contains(chars[k]),
                  !(chars[k] == "/" && k + 1 < count && chars[k + 1] == ">"),
                  !(closer.map { starts($0, k) } ?? false) {
                k += 1
            }
            if k == j { k = j + 1 }   // Sicherheitsnetz: immer vorwaerts
            let word = String(chars[j..<k])
            let afterEquals = out.hasSuffix("<span class=\"hl-op\">=</span>")
            out += wrapToken(word, isHTML && afterEquals ? .string : .tagAttribute)
            j = k
        }
        return j
    }

    /// Textinhalt: Entities (&amp; &#169; &#x1F600;) hervorheben, Rest maskieren.
    private func markupText(_ text: String) -> String {
        let chars = Array(text)
        let count = chars.count
        var out = ""
        var plain = ""
        var i = 0
        while i < count {
            if chars[i] == "&" {
                var j = i + 1
                if j < count, chars[j] == "#" { j += 1 }
                if j < count, chars[j] == "x" || chars[j] == "X", chars[i + 1] == "#" { j += 1 }
                let bodyStart = j
                while j < count, chars[j].isLetter || chars[j].isNumber { j += 1 }
                if j > bodyStart, j < count, chars[j] == ";" {
                    if !plain.isEmpty { out += HTMLSanitizer.escapeHTML(plain); plain = "" }
                    out += wrapToken(String(chars[i...j]), .typeName)
                    i = j + 1
                    continue
                }
            }
            plain.append(chars[i])
            i += 1
        }
        if !plain.isEmpty { out += HTMLSanitizer.escapeHTML(plain) }
        return out
    }
}
