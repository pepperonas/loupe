import Foundation

/// Zerlegt Log-Text in Eintraege. Jede Zeile wird gegen die bekannten Formate
/// geprueft (strukturiert zuerst, generisch zuletzt); Zeilen ohne eigenen Kopf
/// haengen als Folgezeile am vorigen Eintrag -- so bleiben Stacktraces beisammen.
public enum LogParser {

    /// Hoechstens so viele Zeilen werden gezeigt -- die NEUESTEN.
    public static let defaultMaxLines = 5000

    /// - Parameters:
    ///   - maxLines: Zeilengrenze; aeltere Zeilen fallen weg.
    ///   - startsMidLine: true, wenn der Text nicht am Dateianfang beginnt
    ///     (Tail-Lesen). Die erste, angeschnittene Zeile wird dann verworfen.
    ///   - firstLineNumber: Nummer der ersten Zeile von `text` (inkl. einer
    ///     angeschnittenen) -- haelt die Nummern beim Tail-Lesen absolut.
    public static func parse(text: String,
                             maxLines: Int = defaultMaxLines,
                             startsMidLine: Bool = false,
                             firstLineNumber: Int = 1) -> LogDocument {
        // "\r\n" ist in Swift EIN Zeichen -- split(separator: "\n") traefe es nie.
        var lines = text.split(omittingEmptySubsequences: false,
                               whereSeparator: { $0 == "\n" || $0 == "\r\n" })
            .map { sub -> Substring in sub.hasSuffix("\r") ? sub.dropLast() : sub }
        var base = firstLineNumber
        if startsMidLine, lines.count > 1 {
            lines.removeFirst()
            base += 1
        }
        if lines.count > 1, lines.last?.isEmpty == true { lines.removeLast() }
        if lines.count == 1, lines[0].isEmpty { lines = [] }

        var dropped = 0
        if lines.count > maxLines {
            dropped = lines.count - maxLines
            lines = Array(lines.suffix(maxLines))
        }

        var entries: [LogEntry] = []
        var current: LogEntry?
        for (i, raw) in lines.enumerated() {
            let number = base + dropped + i
            let line = String(raw)
            if let start = parseStart(line, lineNumber: number) {
                if let c = current { entries.append(c) }
                current = start
            } else if var c = current, c.format != .plain {
                c.continuation.append(LogLine(lineNumber: number, text: line))
                current = c
            } else {
                if let c = current { entries.append(c) }
                current = LogEntry(lineNumber: number, format: .plain, message: line)
            }
        }
        if let c = current { entries.append(c) }

        var counts: [LogLevel: Int] = [:]
        var formats: [LogFormat: Int] = [:]
        for e in entries {
            if let l = e.level { counts[l, default: 0] += 1 }
            if e.format != .plain { formats[e.format, default: 0] += 1 }
        }
        let dominant = formats.max { a, b in a.value < b.value }?.key

        return LogDocument(entries: entries, totalLines: lines.count, droppedLines: dropped,
                           levelCounts: counts, dominantFormat: dominant)
    }

    /// Erkennt einen Eintragskopf. nil = keine eigene Struktur (Folgezeile oder Klartext).
    static func parseStart(_ line: String, lineNumber: Int) -> LogEntry? {
        if line.first == "{", let e = parseJSON(line, lineNumber) { return e }
        if let e = parseAccess(line, lineNumber) { return e }
        if let e = parseUnified(line, lineNumber) { return e }
        if let e = parseSyslog(line, lineNumber) { return e }
        if let e = parseLogcat(line, lineNumber) { return e }
        if let e = parseLogfmt(line, lineNumber) { return e }
        return parseGeneric(line, lineNumber)
    }

    // MARK: - Regex-Helfer

    private static func rx(_ pattern: String) -> NSRegularExpression {
        // Muster sind Konstanten dieses Moduls; ein Fehler waere ein Programmierfehler.
        try! NSRegularExpression(pattern: pattern)
    }

    private static func match(_ re: NSRegularExpression, _ s: String) -> [String?]? {
        let ns = s as NSString
        guard let m = re.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)) else { return nil }
        return (0..<m.numberOfRanges).map { i in
            let r = m.range(at: i)
            return r.location == NSNotFound ? nil : ns.substring(with: r)
        }
    }

    // MARK: - Access-Log (Common/Combined)

    private nonisolated(unsafe) static let accessRe = rx(
        #"^(\S+) \S+ \S+ \[([^\]]+)\] "((?:[^"\\]|\\.)*)" (\d{3}) (\S+)(?: "((?:[^"\\]|\\.)*)" "((?:[^"\\]|\\.)*)")?"#)

    static func parseAccess(_ line: String, _ n: Int) -> LogEntry? {
        guard let g = match(accessRe, line), let status = g[4].flatMap({ Int($0) }) else { return nil }
        let request = g[3] ?? ""
        let parts = request.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        var info = AccessInfo(status: status)
        let isMethod = parts.first.map { !$0.isEmpty && $0.allSatisfy { $0.isUppercase && $0.isLetter } } ?? false
        if isMethod, parts.count == 3 || parts.count == 2 {
            info.method = parts[0]
            info.path = parts[1]
            info.proto = parts.count == 3 ? parts[2] : nil
        } else {
            info.path = request
        }
        info.bytes = g[5]
        info.referer = dashAsNil(g[6])
        info.userAgent = dashAsNil(g[7])
        let level: LogLevel = status >= 500 ? .error : (status >= 400 ? .warning : .info)
        return LogEntry(lineNumber: n, format: .access, timestamp: g[2], level: level,
                        source: g[1], message: request, access: info)
    }

    private static func dashAsNil(_ s: String?) -> String? {
        guard let s, !s.isEmpty, s != "-" else { return nil }
        return s
    }

    // MARK: - macOS unified log (`log show`)

    private nonisolated(unsafe) static let unifiedRe = rx(
        #"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+[+-]\d{4})\s+0x[0-9a-f]+\s+(Default|Info|Debug|Error|Fault|Activity|Signpost|State)\s+0x[0-9a-f]+\s+(\d+)\s+\d+\s+([^:]+?): ?(.*)$"#)

    static func parseUnified(_ line: String, _ n: Int) -> LogEntry? {
        guard let g = match(unifiedRe, line) else { return nil }
        let level: LogLevel?
        switch g[2] {
        case "Default": level = .notice
        case "Info": level = .info
        case "Debug": level = .debug
        case "Error": level = .error
        case "Fault": level = .fatal
        default: level = nil
        }
        return LogEntry(lineNumber: n, format: .unifiedLog, timestamp: g[1], level: level,
                        source: "\(g[4] ?? "")[\(g[3] ?? "")]", message: g[5] ?? "")
    }

    // MARK: - syslog / journalctl

    private nonisolated(unsafe) static let syslogRe = rx(
        #"^([A-Z][a-z]{2} [ \d]\d \d{2}:\d{2}:\d{2}(?:\.\d+)?|\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}(?::?\d{2})?)?) ([A-Za-z0-9][\w.-]*) ([^\s:\[]+(?:\[\d+\])?): ?(.*)$"#)

    static func parseSyslog(_ line: String, _ n: Int) -> LogEntry? {
        guard let g = match(syslogRe, line) else { return nil }
        // "2026-… ERROR app: x" ist ein Anwendungs-Log, kein Host namens ERROR.
        if let host = g[2], LogLevel.from(host) != nil { return nil }
        var message = g[4] ?? ""
        // Viele Dienste schreiben ihr Level an den Anfang der Nachricht.
        let head = parseHeadLevel(Substring(message), hasTimestamp: true)
        if head.level != nil { message = String(head.rest) }
        return LogEntry(lineNumber: n, format: .syslog, timestamp: g[1], level: head.level,
                        source: "\(g[2] ?? "") \(g[3] ?? "")", message: message)
    }

    // MARK: - logcat

    private nonisolated(unsafe) static let logcatThreadtimeRe = rx(
        #"^(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\s+\d+\s+\d+\s+([VDIWEFA])\s+(.*?)\s*: (.*)$"#)
    private nonisolated(unsafe) static let logcatBriefRe = rx(#"^([VDIWEFA])/(.+?)\(\s*\d+\): (.*)$"#)

    static func parseLogcat(_ line: String, _ n: Int) -> LogEntry? {
        if let g = match(logcatThreadtimeRe, line), let letter = g[2]?.first {
            return LogEntry(lineNumber: n, format: .logcat, timestamp: g[1],
                            level: LogLevel.fromLogcat(letter), source: g[3], message: g[4] ?? "")
        }
        if let g = match(logcatBriefRe, line), let letter = g[1]?.first {
            return LogEntry(lineNumber: n, format: .logcat, timestamp: nil,
                            level: LogLevel.fromLogcat(letter), source: g[2], message: g[3] ?? "")
        }
        return nil
    }

    // MARK: - JSON Lines

    static func parseJSON(_ line: String, _ n: Int) -> LogEntry? {
        var parser = JSONParser(bytes: Array(line.utf8))
        let result = parser.parse()
        guard result.outcome == .complete, case .object(let members, _)? = result.root else { return nil }
        let pairs = members.map { m -> (String, String, Bool) in
            switch m.value {
            case .string(let s): return (m.key, s, true)
            default: return (m.key, compactJSON(m.value), false)
            }
        }
        var entry = structured(pairs: pairs, format: .json, lineNumber: n)
        // Numerische Zeit/Level brauchen den Rohwert.
        for m in members {
            let key = m.key.lowercased()
            if case .number(let raw) = m.value {
                if timeKeys.contains(key), entry.timestamp == raw { entry.timestamp = formatEpoch(raw) ?? raw }
                if levelKeys.contains(key), entry.level == nil, let v = Int(raw) {
                    entry.level = LogLevel.fromNumeric(v)
                    entry.fields.removeAll { $0.key == m.key }
                }
            }
        }
        return entry
    }

    /// Kompakte, gueltige JSON-Darstellung eines Wertes (fuer verschachtelte Felder).
    static func compactJSON(_ value: JSONValue) -> String {
        switch value {
        case .null: return "null"
        case .bool(let b): return b ? "true" : "false"
        case .number(let raw): return raw
        case .string(let s): return quoteJSON(s)
        case .array(let items, _): return "[" + items.map(compactJSON).joined(separator: ",") + "]"
        case .object(let members, _):
            return "{" + members.map { quoteJSON($0.key) + ":" + compactJSON($0.value) }.joined(separator: ",") + "}"
        }
    }

    private static func quoteJSON(_ s: String) -> String {
        var out = "\""
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if scalar.value < 0x20 { out += String(format: "\\u%04x", scalar.value) }
                else { out.unicodeScalars.append(scalar) }
            }
        }
        return out + "\""
    }

    private nonisolated(unsafe) static let epochFormatterMillis: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
        return f
    }()

    private nonisolated(unsafe) static let epochFormatterSeconds: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss'Z'"
        return f
    }()

    /// Unix-Zeit (Sekunden oder Millisekunden) als lesbares UTC-Datum.
    static func formatEpoch(_ raw: String) -> String? {
        guard let v = Double(raw), v > 1e9 else { return nil }
        if v > 1e11 {
            return epochFormatterMillis.string(from: Date(timeIntervalSince1970: v / 1000))
        }
        let isWhole = v.rounded() == v
        return (isWhole ? epochFormatterSeconds : epochFormatterMillis)
            .string(from: Date(timeIntervalSince1970: v))
    }

    // MARK: - logfmt

    private nonisolated(unsafe) static let logfmtPairRe = rx(#"([A-Za-z_@][\w.@-]*)=("(?:[^"\\]|\\.)*"|\S*)"#)

    static func parseLogfmt(_ line: String, _ n: Int) -> LogEntry? {
        guard let first = line.first, first.isLetter || first == "_" || first == "@",
              line.contains("=") else { return nil }
        let ns = line as NSString
        let matches = logfmtPairRe.matches(in: line, range: NSRange(location: 0, length: ns.length))
        guard matches.count >= 2 else { return nil }
        // Die Zeile muss GANZ aus Paaren bestehen -- sonst ist es Fliesstext mit einem "=".
        var cursor = 0
        var pairs: [(String, String, Bool)] = []
        for m in matches {
            let gap = ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor))
            guard gap.allSatisfy({ $0 == " " || $0 == "\t" }) else { return nil }
            cursor = m.range.location + m.range.length
            let key = ns.substring(with: m.range(at: 1))
            var value = ns.substring(with: m.range(at: 2))
            var quoted = false
            if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
                value = String(value.dropFirst().dropLast())
                    .replacingOccurrences(of: "\\\"", with: "\"")
                    .replacingOccurrences(of: "\\\\", with: "\\")
                quoted = true
            }
            pairs.append((key, value, quoted || Double(value) == nil))
        }
        guard ns.substring(from: cursor).allSatisfy({ $0 == " " || $0 == "\t" }) else { return nil }
        let keys = Set(pairs.map { $0.0.lowercased() })
        guard !keys.isDisjoint(with: levelKeys.union(messageKeys)) else { return nil }
        return structured(pairs: pairs, format: .logfmt, lineNumber: n)
    }

    // MARK: - Gemeinsame Feldzuordnung (JSON/logfmt)

    private static let timeKeys: Set<String> = ["time", "ts", "timestamp", "@timestamp", "datetime", "date", "@t", "t"]
    private static let levelKeys: Set<String> = ["level", "lvl", "severity", "levelname", "loglevel", "@l", "log.level"]
    private static let messageKeys: Set<String> = ["msg", "message", "event", "@m", "@mt"]
    private static let sourceKeys: Set<String> = ["logger", "logger_name", "name", "module", "caller", "component", "source", "category"]

    private static func structured(pairs: [(String, String, Bool)], format: LogFormat, lineNumber: Int) -> LogEntry {
        var entry = LogEntry(lineNumber: lineNumber, format: format, message: "")
        var hasMessage = false
        for (key, value, isString) in pairs {
            let k = key.lowercased()
            if entry.timestamp == nil, timeKeys.contains(k) {
                entry.timestamp = value
            } else if entry.level == nil, levelKeys.contains(k), let l = LogLevel.from(value) {
                entry.level = l
            } else if !hasMessage, messageKeys.contains(k) {
                entry.message = value
                hasMessage = true
            } else if entry.source == nil, sourceKeys.contains(k), isString {
                entry.source = value
            } else {
                entry.fields.append(LogField(key: key, value: value, isString: isString))
            }
        }
        return entry
    }

    // MARK: - Generisch: [Zeit] [Level] [Quelle] Nachricht

    private nonisolated(unsafe) static let timestampRe = rx(
        #"^(?:\[([^\]]{5,40})\]|(\d{4}[-/]\d{2}[-/]\d{2}[T ]\d{2}:\d{2}(?::\d{2})?(?:[.,]\d+)?(?:Z|[+-]\d{2}(?::?\d{2})?)?|\d{2}:\d{2}:\d{2}(?:[.,]\d+)?))"#)
    private nonisolated(unsafe) static let timestampShapeRe = rx(#"\d{1,4}[-/:.]\d{2}"#)
    private nonisolated(unsafe) static let bracketLevelRe = rx(#"^\[\s*([A-Za-z]+)\s*\]"#)
    private nonisolated(unsafe) static let assignLevelRe = rx(#"^(?:level|lvl)=([A-Za-z]+)"#)
    private nonisolated(unsafe) static let channelLevelRe = rx(#"^([\w-]+)\.([A-Za-z]+):"#)
    private nonisolated(unsafe) static let wordLevelRe = rx(#"^([A-Za-z]+)(?=[\s:|\]]|$)"#)
    private nonisolated(unsafe) static let pythonSourceRe = rx(#"^:([\w.]+):"#)
    private nonisolated(unsafe) static let bracketSourceRe = rx(#"^\[([^\]]{1,60})\]"#)

    static func parseGeneric(_ line: String, _ n: Int) -> LogEntry? {
        var rest = Substring(line)
        var timestamp: String?

        if let g = match(timestampRe, line) {
            let candidate = g[1] ?? g[2]
            // Eine Klammer am Zeilenanfang ist nur dann Zeit, wenn sie wie Zeit aussieht.
            if let c = candidate, g[1] == nil || match(timestampShapeRe, c) != nil {
                timestamp = c.trimmingCharacters(in: .whitespaces)
                rest = rest.dropFirst(g[0]!.count)
                rest = skipSeparators(rest)
            }
        }

        let head = parseHeadLevel(rest, hasTimestamp: timestamp != nil)
        guard timestamp != nil || head.level != nil else { return nil }
        rest = head.rest
        var source = head.source

        if source == nil, let g = match(bracketSourceRe, String(rest)), let s = g[1] {
            source = s.trimmingCharacters(in: .whitespaces)
            rest = skipSeparators(rest.dropFirst(g[0]!.count))
        }

        return LogEntry(lineNumber: n, format: .generic, timestamp: timestamp, level: head.level,
                        source: source, message: String(rest))
    }

    /// Level am Anfang von `text`. Ohne Zeitstempel wird ein nacktes Wort nur
    /// akzeptiert, wenn es GROSS geschrieben ist oder ein ":" folgt -- sonst
    /// wuerde "Info about the job" zur INFO-Zeile.
    static func parseHeadLevel(_ text: Substring, hasTimestamp: Bool)
        -> (level: LogLevel?, source: String?, rest: Substring) {
        let s = String(text)
        if let g = match(bracketLevelRe, s), let l = g[1].flatMap(LogLevel.from) {
            return (l, nil, skipSeparators(text.dropFirst(g[0]!.count)))
        }
        if let g = match(assignLevelRe, s), let l = g[1].flatMap(LogLevel.from) {
            return (l, nil, skipSeparators(text.dropFirst(g[0]!.count)))
        }
        if let g = match(channelLevelRe, s), let l = g[2].flatMap(LogLevel.from) {
            return (l, g[1], skipSeparators(text.dropFirst(g[0]!.count)))
        }
        if let g = match(wordLevelRe, s), let word = g[1], let l = LogLevel.from(word) {
            var rest = text.dropFirst(word.count)
            let followedByColon = rest.first == ":"
            guard hasTimestamp || word == word.uppercased() || followedByColon else {
                return (nil, nil, text)
            }
            if let p = match(pythonSourceRe, String(rest)), let name = p[1] {
                rest = rest.dropFirst(p[0]!.count)
                return (l, name, rest)
            }
            return (l, nil, skipSeparators(rest))
        }
        return (nil, nil, text)
    }

    private static func skipSeparators(_ s: Substring) -> Substring {
        var r = s
        while let c = r.first, c == " " || c == "\t" || c == "|" || c == ":" || c == "-" {
            // Ein "-" gehoert nur als freistehender Trenner weg, nicht als Vorzeichen.
            if c == "-", let next = r.dropFirst().first, next != " " { break }
            r = r.dropFirst()
        }
        return r
    }
}
