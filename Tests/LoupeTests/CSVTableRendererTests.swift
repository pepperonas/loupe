import Foundation
import LoupeCore

@MainActor
public enum CSVTableRendererTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("CSVTableRenderer") {

            runner.runTest(name: "testEmptyDocumentRendersNoticeBanner") {
                let doc = CSVDocument(headers: nil, rows: [], columnCount: 0, totalRowsCount: 0, wasTruncated: false, delimiter: ",")
                let html = CSVTableRenderer().renderBody(document: doc)
                try assertTrue(html.contains("lp-banner lp-banner-notice"))
                try assertTrue(html.contains("Leere Datei"))
            }

            runner.runTest(name: "testBasicTableRenderingWithStickyElements") {
                let doc = CSVDocument(
                    headers: ["Name", "Score"],
                    rows: [["Alice", "95"], ["Bob", "88"]],
                    columnCount: 2,
                    totalRowsCount: 3,
                    wasTruncated: false,
                    delimiter: ","
                )
                let html = CSVTableRenderer().renderBody(document: doc)
                try assertTrue(html.contains("<table class=\"lp-csv-table\">"))
                try assertTrue(html.contains("<thead>"))
                try assertTrue(html.contains("<tbody>"))
                try assertTrue(html.contains("<th class=\"lp-csv-row-num\">#</th>"))
                try assertTrue(html.contains("<td class=\"lp-csv-row-num\">1</td>"))
                try assertTrue(html.contains("<td class=\"lp-csv-row-num\">2</td>"))
                try assertTrue(html.contains("Alice"))
                try assertTrue(html.contains("Bob"))
            }

            runner.runTest(name: "testNumericDetectionAndRightAlignment") {
                try assertTrue(CSVTableRenderer.isNumeric("123", delimiter: ","))
                try assertTrue(CSVTableRenderer.isNumeric("-45.67", delimiter: ","))
                try assertTrue(CSVTableRenderer.isNumeric("+100", delimiter: ","))
                try assertTrue(CSVTableRenderer.isNumeric("50%", delimiter: ","))
                try assertTrue(CSVTableRenderer.isNumeric("3,14", delimiter: ";"))
                try assertFalse(CSVTableRenderer.isNumeric("3,14", delimiter: ","))
                try assertFalse(CSVTableRenderer.isNumeric("abc", delimiter: ","))
                try assertFalse(CSVTableRenderer.isNumeric("1.2.3", delimiter: ","))
                try assertFalse(CSVTableRenderer.isNumeric("", delimiter: ","))

                let doc = CSVDocument(
                    headers: ["Item", "Price"],
                    rows: [["Book", "19.99"], ["Pen", "2.50"]],
                    columnCount: 2,
                    totalRowsCount: 3,
                    wasTruncated: false,
                    delimiter: ","
                )
                let html = CSVTableRenderer().renderBody(document: doc)
                try assertTrue(html.contains("<td class=\"lp-csv-num\">19.99</td>"))
                try assertTrue(html.contains("<td class=\"lp-csv-num\">2.50</td>"))
                // Column header should also be marked numeric
                try assertTrue(html.contains("<th class=\"lp-csv-num\">Price</th>"))
            }

            runner.runTest(name: "testColumnLettersSynthesizedWhenNoHeaders") {
                let doc = CSVDocument(
                    headers: nil,
                    rows: [["1", "2", "3"]],
                    columnCount: 3,
                    totalRowsCount: 1,
                    wasTruncated: false,
                    delimiter: ","
                )
                let html = CSVTableRenderer().renderBody(document: doc)
                try assertTrue(html.contains(">A</th>"))
                try assertTrue(html.contains(">B</th>"))
                try assertTrue(html.contains(">C</th>"))
            }

            runner.runTest(name: "testHTMLEscapingNeutralizesScriptsAndTags") {
                let doc = CSVDocument(
                    headers: ["<script>alert('xss')</script>"],
                    rows: [["<b>Bold</b>"]],
                    columnCount: 1,
                    totalRowsCount: 2,
                    wasTruncated: false,
                    delimiter: ","
                )
                let html = CSVTableRenderer().renderBody(document: doc)
                try assertFalse(html.contains("<script>"))
                try assertTrue(html.contains("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"))
                try assertFalse(html.contains("<b>Bold</b>"))
                try assertTrue(html.contains("&lt;b&gt;Bold&lt;/b&gt;"))
            }

            runner.runTest(name: "testSummaryToolbarContents") {
                let doc = CSVDocument(
                    headers: ["Col1"],
                    rows: [["Val1"], ["Val2"]],
                    columnCount: 1,
                    totalRowsCount: 3,
                    wasTruncated: false,
                    delimiter: ";"
                )
                let html = CSVTableRenderer().renderBody(document: doc)
                try assertTrue(html.contains("2 Zeilen"))
                try assertTrue(html.contains("1 Spalte"))
                try assertTrue(html.contains("Semikolon (;)"))
            }

            runner.runTest(name: "testTruncationBannerWhenTruncated") {
                let doc1 = CSVDocument(
                    headers: ["Col"],
                    rows: [["Val"]],
                    columnCount: 1,
                    totalRowsCount: 2,
                    wasTruncated: true,
                    wasTruncatedByReader: false,
                    delimiter: ","
                )
                let html1 = CSVTableRenderer().renderBody(document: doc1)
                try assertTrue(html1.contains("lp-banner lp-banner-notice"))
                try assertTrue(html1.contains("Große Datei"))

                let doc2 = CSVDocument(
                    headers: ["Col"],
                    rows: [["Val"]],
                    columnCount: 1,
                    totalRowsCount: 2,
                    wasTruncated: true,
                    wasTruncatedByReader: true,
                    delimiter: ","
                )
                let html2 = CSVTableRenderer().renderBody(document: doc2)
                try assertTrue(html2.contains("Datei abgeschnitten"))
            }

            runner.runTest(name: "testDelimiterDisplayNames") {
                try assertEqual(CSVTableRenderer.delimiterDisplayName(","), "Komma (,)")
                try assertEqual(CSVTableRenderer.delimiterDisplayName(";"), "Semikolon (;)")
                try assertEqual(CSVTableRenderer.delimiterDisplayName("\t"), "Tabulator (⇥)")
                try assertEqual(CSVTableRenderer.delimiterDisplayName("|"), "Pipe (|)")
            }

            runner.runTest(name: "testColumnLetterGeneration") {
                try assertEqual(CSVTableRenderer.columnLetter(for: 0), "A")
                try assertEqual(CSVTableRenderer.columnLetter(for: 25), "Z")
                try assertEqual(CSVTableRenderer.columnLetter(for: 26), "AA")
                try assertEqual(CSVTableRenderer.columnLetter(for: 27), "AB")
                try assertEqual(CSVTableRenderer.columnLetter(for: 51), "AZ")
                try assertEqual(CSVTableRenderer.columnLetter(for: 52), "BA")
            }
        }
    }
}
