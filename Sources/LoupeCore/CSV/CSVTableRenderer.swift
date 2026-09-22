import Foundation

public struct CSVTableRenderer: Sendable {
    public let settings: LoupeSettings
    
    public init(settings: LoupeSettings = LoupeSettings.load()) {
        self.settings = settings
    }
    
    public static func columnLetter(for index: Int) -> String {
        var n = index
        var result = ""
        while n >= 0 {
            let remainder = n % 26
            if let scalar = UnicodeScalar(65 + remainder) {
                result = String(Character(scalar)) + result
            }
            n = (n / 26) - 1
        }
        return result
    }
    
    public static func delimiterDisplayName(_ delimiter: Character) -> String {
        switch delimiter {
        case ",":  return "Komma (,)"
        case ";":  return "Semikolon (;)"
        case "\t": return "Tabulator (⇥)"
        case "|":  return "Pipe (|)"
        default:   return "'\(delimiter)'"
        }
    }
    
    public static func isNumeric(_ text: String, delimiter: Character = ",") -> Bool {
        var s = text.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return false }
        
        if s.hasSuffix("%") {
            s = String(s.dropLast()).trimmingCharacters(in: .whitespaces)
            guard !s.isEmpty else { return false }
        }
        
        if s.hasPrefix("+") || s.hasPrefix("-") {
            s = String(s.dropFirst())
            guard !s.isEmpty else { return false }
        }
        
        var hasDecimalSep = false
        var digitCount = 0
        
        for c in s {
            if c.isASCII && c.isNumber {
                digitCount += 1
            } else if c == "." || (c == "," && delimiter != ",") {
                if hasDecimalSep { return false }
                hasDecimalSep = true
            } else {
                return false
            }
        }
        
        return digitCount > 0
    }
    
    public func renderBody(document: CSVDocument) -> String {
        if document.totalRowsCount == 0 {
            return """
            <div class="lp-csv-container">
              <div class="lp-banner lp-banner-notice">Leere Datei — keine Tabellendaten gefunden.</div>
            </div>
            """
        }
        
        var html = "<div class=\"lp-csv-container\">\n"
        
        // Toolbar
        html += "  <div class=\"lp-csv-toolbar\">\n"
        let rowLabel = document.rows.count == 1 ? "1 Zeile" : "\(document.rows.count) Zeilen"
        let colLabel = document.columnCount == 1 ? "1 Spalte" : "\(document.columnCount) Spalten"
        let delimLabel = Self.delimiterDisplayName(document.delimiter)
        html += "    <span class=\"lp-csv-badge\">\(rowLabel)</span>\n"
        html += "    <span class=\"lp-csv-badge\">\(colLabel)</span>\n"
        html += "    <span class=\"lp-csv-badge\">Trennzeichen: \(delimLabel)</span>\n"
        html += "  </div>\n"
        
        // Truncation banner
        if document.wasTruncatedByReader {
            html += "  <div class=\"lp-banner lp-banner-notice\">Datei abgeschnitten — nur der Anfang wurde gelesen. Die Datei selbst ist in Ordnung.</div>\n"
        } else if document.wasTruncated {
            html += "  <div class=\"lp-banner lp-banner-notice\">Große Datei — Vorschau auf die ersten \(document.rows.count) Zeilen begrenzt.</div>\n"
        }
        
        // Determine numeric columns
        let colCount = document.columnCount
        var isNumericCol = [Bool](repeating: false, count: colCount)
        for c in 0..<colCount {
            var numericCount = 0
            var filledCount = 0
            for row in document.rows {
                if c < row.count {
                    let val = row[c]
                    if !val.isEmpty {
                        filledCount += 1
                        if Self.isNumeric(val, delimiter: document.delimiter) {
                            numericCount += 1
                        }
                    }
                }
            }
            isNumericCol[c] = filledCount > 0 && (numericCount * 2 >= filledCount)
        }
        
        // Table
        html += "  <div class=\"lp-csv-table-wrapper\">\n"
        html += "    <table class=\"lp-csv-table\">\n"
        html += "      <thead>\n"
        html += "        <tr>\n"
        html += "          <th class=\"lp-csv-row-num\">#</th>\n"
        
        for c in 0..<colCount {
            let headerText: String
            if let headers = document.headers, c < headers.count {
                headerText = headers[c]
            } else {
                headerText = Self.columnLetter(for: c)
            }
            let numClass = isNumericCol[c] ? " class=\"lp-csv-num\"" : ""
            html += "          <th\(numClass)>\(HTMLEscape.escape(headerText))</th>\n"
        }
        html += "        </tr>\n"
        html += "      </thead>\n"
        
        html += "      <tbody>\n"
        for (rIdx, row) in document.rows.enumerated() {
            html += "        <tr>\n"
            html += "          <td class=\"lp-csv-row-num\">\(rIdx + 1)</td>\n"
            for c in 0..<colCount {
                let cellText = c < row.count ? row[c] : ""
                let isNum = Self.isNumeric(cellText, delimiter: document.delimiter)
                let numClass = isNum ? " class=\"lp-csv-num\"" : ""
                html += "          <td\(numClass)>\(HTMLEscape.escape(cellText))</td>\n"
            }
            html += "        </tr>\n"
        }
        html += "      </tbody>\n"
        html += "    </table>\n"
        html += "  </div>\n"
        html += "</div>\n"
        
        return html
    }
}
