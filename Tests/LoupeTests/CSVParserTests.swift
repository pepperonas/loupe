import Foundation
import LoupeCore

@MainActor
public enum CSVParserTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("CSVParser") {

            runner.runTest(name: "testBasicCommaSeparatedParsing") {
                let csv = "name,age,city\nAlice,30,Berlin\nBob,25,Munich"
                let doc = CSVParser().parse(text: csv)
                try assertEqual(doc.delimiter, ",")
                try assertEqual(doc.columnCount, 3)
                try assertEqual(doc.totalRowsCount, 3)
                try assertFalse(doc.wasTruncated)
                try assertEqual(doc.headers ?? [], ["name", "age", "city"])
                try assertEqual(doc.rows.count, 2)
                try assertEqual(doc.rows[0], ["Alice", "30", "Berlin"])
                try assertEqual(doc.rows[1], ["Bob", "25", "Munich"])
            }

            runner.runTest(name: "testSemicolonDetectionAndParsing") {
                let csv = "Vorname;Nachname;Ort\nMax;Mustermann;Köln\nErika;Musterfrau;Hamburg"
                let doc = CSVParser().parse(text: csv)
                try assertEqual(doc.delimiter, ";")
                try assertEqual(doc.columnCount, 3)
                try assertEqual(doc.headers ?? [], ["Vorname", "Nachname", "Ort"])
                try assertEqual(doc.rows.count, 2)
                try assertEqual(doc.rows[0], ["Max", "Mustermann", "Köln"])
            }

            runner.runTest(name: "testTabSeparatedParsing") {
                let tsv = "col1\tcol2\tcol3\nval1\tval2\tval3"
                let doc = CSVParser().parse(text: tsv)
                try assertEqual(doc.delimiter, "\t")
                try assertEqual(doc.columnCount, 3)
                try assertEqual(doc.headers ?? [], ["col1", "col2", "col3"])
                try assertEqual(doc.rows.count, 1)
                try assertEqual(doc.rows[0], ["val1", "val2", "val3"])
            }

            runner.runTest(name: "testPreferredDelimiterOverridesDetection") {
                let text = "a;b;c"
                let doc = CSVParser(preferredDelimiter: ",").parse(text: text)
                try assertEqual(doc.delimiter, ",")
                try assertEqual(doc.columnCount, 1)
                try assertEqual(doc.headers ?? [], ["a;b;c"])
            }

            runner.runTest(name: "testQuotedFieldsWithDelimitersAndNewlines") {
                let csv = "name,bio\nAlice,\"Loves commas, semicolons; and\nnewlines\"\nBob,\"Normal\""
                let doc = CSVParser().parse(text: csv)
                try assertEqual(doc.headers ?? [], ["name", "bio"])
                try assertEqual(doc.rows.count, 2)
                try assertEqual(doc.rows[0][1], "Loves commas, semicolons; and\nnewlines")
                try assertEqual(doc.rows[1][1], "Normal")
            }

            runner.runTest(name: "testEscapedQuotesInQuotedFields") {
                let csv = "title,author\n\"The \"\"Loupe\"\" Guide\",Martin"
                let doc = CSVParser().parse(text: csv)
                try assertEqual(doc.rows.count, 1)
                try assertEqual(doc.rows[0][0], "The \"Loupe\" Guide")
                try assertEqual(doc.rows[0][1], "Martin")
            }

            runner.runTest(name: "testCRLFAndTrailingNewlines") {
                let csv = "a,b\r\n1,2\r\n3,4\r\n"
                let doc = CSVParser().parse(text: csv)
                try assertEqual(doc.headers ?? [], ["a", "b"])
                try assertEqual(doc.rows.count, 2)
                try assertEqual(doc.rows[0], ["1", "2"])
                try assertEqual(doc.rows[1], ["3", "4"])
            }

            runner.runTest(name: "testEmptyAndWhitespaceInput") {
                let doc1 = CSVParser().parse(text: "")
                try assertTrue(doc1.headers == nil)
                try assertTrue(doc1.rows.isEmpty)
                try assertEqual(doc1.columnCount, 0)
                try assertFalse(doc1.wasTruncated)

                let doc2 = CSVParser().parse(text: "   \n\t  ")
                try assertTrue(doc2.headers == nil)
                try assertTrue(doc2.rows.isEmpty)
            }

            runner.runTest(name: "testMaxRowsTruncation") {
                let csv = "h1,h2\n1,2\n3,4\n5,6\n7,8\n9,10"
                let doc = CSVParser(maxRows: 3).parse(text: csv)
                try assertTrue(doc.wasTruncated)
                try assertEqual(doc.headers ?? [], ["h1", "h2"])
                try assertEqual(doc.rows.count, 2)
                try assertEqual(doc.totalRowsCount, 3)
            }

            runner.runTest(name: "testReaderTruncationPropagates") {
                let csv = "a,b\n1,2"
                let doc = CSVParser().parse(text: csv, wasTruncatedByReader: true)
                try assertTrue(doc.wasTruncated)
                try assertTrue(doc.wasTruncatedByReader)
            }

            runner.runTest(name: "testNumericFirstRowSynthesizesNoHeader") {
                let csv = "1,2,3\n4,5,6"
                let doc = CSVParser().parse(text: csv)
                try assertTrue(doc.headers == nil)
                try assertEqual(doc.rows.count, 2)
                try assertEqual(doc.rows[0], ["1", "2", "3"])
                try assertEqual(doc.rows[1], ["4", "5", "6"])
            }

            runner.runTest(name: "testUnicodeAndEmojiInCells") {
                let csv = "Icon,Text\n🎉,Party\n🇩🇪,Grüße"
                let doc = CSVParser().parse(text: csv)
                try assertEqual(doc.headers ?? [], ["Icon", "Text"])
                try assertEqual(doc.rows[0], ["🎉", "Party"])
                try assertEqual(doc.rows[1], ["🇩🇪", "Grüße"])
            }

            runner.runTest(name: "testRaggedRowsHandling") {
                let csv = "a,b,c\n1\n2,3,4,5"
                let doc = CSVParser().parse(text: csv)
                try assertEqual(doc.columnCount, 4)
                try assertEqual(doc.rows[0].count, 1)
                try assertEqual(doc.rows[1].count, 4)
            }
        }
    }
}
