import Foundation

public struct CSVDocument: Sendable, Equatable {
    public let headers: [String]?
    public let rows: [[String]]
    public let columnCount: Int
    public let totalRowsCount: Int
    public let wasTruncated: Bool
    public let wasTruncatedByReader: Bool
    public let delimiter: Character
    
    public init(
        headers: [String]?,
        rows: [[String]],
        columnCount: Int,
        totalRowsCount: Int,
        wasTruncated: Bool,
        wasTruncatedByReader: Bool = false,
        delimiter: Character
    ) {
        self.headers = headers
        self.rows = rows
        self.columnCount = columnCount
        self.totalRowsCount = totalRowsCount
        self.wasTruncated = wasTruncated
        self.wasTruncatedByReader = wasTruncatedByReader
        self.delimiter = delimiter
    }
}

public struct CSVParser: Sendable {
    public let maxRows: Int
    public let maxColumns: Int
    public let preferredDelimiter: Character?
    
    public init(maxRows: Int = 2000, maxColumns: Int = 200, preferredDelimiter: Character? = nil) {
        self.maxRows = maxRows
        self.maxColumns = maxColumns
        self.preferredDelimiter = preferredDelimiter
    }
    
    public static func detectDelimiter(in text: String) -> Character {
        let candidates: [Character] = [",", ";", "\t"]
        var candidateCounts: [Character: [Int]] = [",": [], ";": [], "\t": []]
        
        var inQuotes = false
        var currentCounts: [Character: Int] = [",": 0, ";": 0, "\t": 0]
        var linesChecked = 0
        let maxLinesToCheck = 10
        
        var chars = text.makeIterator()
        while let c = chars.next(), linesChecked < maxLinesToCheck {
            if c == "\"" {
                inQuotes.toggle()
            } else if !inQuotes {
                if c == "\n" || c == "\r" || c == "\r\n" {
                    for cand in candidates {
                        candidateCounts[cand]?.append(currentCounts[cand] ?? 0)
                        currentCounts[cand] = 0
                    }
                    linesChecked += 1
                } else if let cnt = currentCounts[c] {
                    currentCounts[c] = cnt + 1
                }
            }
        }
        if linesChecked == 0 || (currentCounts.values.contains { $0 > 0 }) {
            for cand in candidates {
                candidateCounts[cand]?.append(currentCounts[cand] ?? 0)
            }
        }
        
        var bestCandidate: Character = ","
        var bestScore = -1
        
        for cand in candidates {
            guard let counts = candidateCounts[cand], !counts.isEmpty else { continue }
            let first = counts[0]
            if first > 0 {
                let matching = counts.filter { $0 == first }.count
                let total = counts.count
                let consistency = (matching * 100) / total
                let score = consistency * 10 + first
                if score > bestScore {
                    bestScore = score
                    bestCandidate = cand
                }
            }
        }
        
        return bestCandidate
    }
    
    public func parse(text: String, wasTruncatedByReader: Bool = false) -> CSVDocument {
        guard text.contains(where: { !$0.isWhitespace }) else {
            return CSVDocument(
                headers: nil,
                rows: [],
                columnCount: 0,
                totalRowsCount: 0,
                wasTruncated: wasTruncatedByReader,
                wasTruncatedByReader: wasTruncatedByReader,
                delimiter: preferredDelimiter ?? ","
            )
        }
        
        let delimiter = preferredDelimiter ?? Self.detectDelimiter(in: text)
        
        var allRows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        var wasTruncated = wasTruncatedByReader
        
        var i = text.startIndex
        let end = text.endIndex
        
        while i < end {
            let c = text[i]
            
            if inQuotes {
                if c == "\"" {
                    let nextIndex = text.index(after: i)
                    if nextIndex < end && text[nextIndex] == "\"" {
                        currentField.append("\"")
                        i = text.index(after: nextIndex)
                        continue
                    } else {
                        inQuotes = false
                        i = nextIndex
                        continue
                    }
                } else {
                    if c == "\r\n" || c == "\r" {
                        currentField.append("\n")
                    } else {
                        currentField.append(c)
                    }
                    i = text.index(after: i)
                    continue
                }
            } else {
                if c == "\"" {
                    inQuotes = true
                    i = text.index(after: i)
                    continue
                } else if c == delimiter {
                    if currentRow.count < maxColumns {
                        currentRow.append(currentField)
                    }
                    currentField = ""
                    i = text.index(after: i)
                    continue
                } else if c == "\n" || c == "\r" || c == "\r\n" {
                    if currentRow.count < maxColumns {
                        currentRow.append(currentField)
                    }
                    currentField = ""
                    allRows.append(currentRow)
                    currentRow = []
                    i = text.index(after: i)
                    if allRows.count >= maxRows {
                        wasTruncated = true
                        break
                    }
                    continue
                } else {
                    currentField.append(c)
                    i = text.index(after: i)
                    continue
                }
            }
        }
        
        if !wasTruncated && (!currentField.isEmpty || !currentRow.isEmpty) {
            if currentRow.count < maxColumns {
                currentRow.append(currentField)
            }
            allRows.append(currentRow)
        }
        
        // Remove phantom trailing empty row if caused by ending newline
        if allRows.count > 1, let last = allRows.last, last.count == 1 && last[0].isEmpty {
            allRows.removeLast()
        }
        
        guard !allRows.isEmpty else {
            return CSVDocument(
                headers: nil,
                rows: [],
                columnCount: 0,
                totalRowsCount: 0,
                wasTruncated: wasTruncated,
                wasTruncatedByReader: wasTruncatedByReader,
                delimiter: delimiter
            )
        }
        
        // Determine whether first row is likely headers or data
        let firstRow = allRows[0]
        let hasHeader: Bool
        if allRows.count == 1 {
            hasHeader = !firstRow.allSatisfy { cell in
                let t = cell.trimmingCharacters(in: .whitespaces)
                return !t.isEmpty && Double(t) != nil
            }
        } else {
            let firstRowAllNumeric = !firstRow.isEmpty && firstRow.allSatisfy { cell in
                let t = cell.trimmingCharacters(in: .whitespaces)
                return !t.isEmpty && Double(t) != nil
            }
            hasHeader = !firstRowAllNumeric
        }
        
        let headers: [String]?
        let dataRows: [[String]]
        if hasHeader {
            headers = firstRow
            dataRows = Array(allRows.dropFirst())
        } else {
            headers = nil
            dataRows = allRows
        }
        
        let maxCols = allRows.reduce(0) { max($0, $1.count) }
        
        return CSVDocument(
            headers: headers,
            rows: dataRows,
            columnCount: maxCols,
            totalRowsCount: allRows.count,
            wasTruncated: wasTruncated,
            wasTruncatedByReader: wasTruncatedByReader,
            delimiter: delimiter
        )
    }
}
