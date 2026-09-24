import Foundation
import LoupeCore

@MainActor
public enum LogParserTests {
    private static func one(_ line: String) throws -> LogEntry {
        let doc = LogParser.parse(text: line)
        try assertEqual(doc.entries.count, 1, "genau ein Eintrag erwartet fuer: \(line)")
        return doc.entries[0]
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("LogParser") {

            // MARK: Level-Normalisierung

            runner.runTest(name: "testLevelTokensNormalize") {
                let cases: [(String, LogLevel)] = [
                    ("TRACE", .trace), ("verbose", .trace), ("debug", .debug), ("DBG", .debug),
                    ("Info", .info), ("INF", .info), ("NOTICE", .notice),
                    ("WARN", .warning), ("warning", .warning), ("WRN", .warning),
                    ("ERROR", .error), ("ERR", .error), ("SEVERE", .error),
                    ("CRIT", .fatal), ("critical", .fatal), ("FATAL", .fatal),
                    ("PANIC", .fatal), ("EMERG", .fatal), ("ALERT", .fatal)
                ]
                for (token, level) in cases {
                    try assertEqual(LogLevel.from(token), level, token)
                }
                try assertEqual(LogLevel.from("hello"), nil)
                try assertEqual(LogLevel.from("E"), nil, "Einzelbuchstaben nur im logcat-Kontext")
            }

            runner.runTest(name: "testPinoNumericLevels") {
                try assertEqual(LogLevel.fromNumeric(10), .trace)
                try assertEqual(LogLevel.fromNumeric(20), .debug)
                try assertEqual(LogLevel.fromNumeric(30), .info)
                try assertEqual(LogLevel.fromNumeric(40), .warning)
                try assertEqual(LogLevel.fromNumeric(50), .error)
                try assertEqual(LogLevel.fromNumeric(60), .fatal)
            }

            // MARK: Generisch

            runner.runTest(name: "testGenericIsoTimestampLevelAndTag") {
                let e = try one("2026-09-24 17:01:02.123 INFO  [main] Server started on :8080")
                try assertEqual(e.format, .generic)
                try assertEqual(e.timestamp, "2026-09-24 17:01:02.123")
                try assertEqual(e.level, .info)
                try assertEqual(e.source, "main")
                try assertEqual(e.message, "Server started on :8080")
            }

            runner.runTest(name: "testGenericBracketedLevelAndZuluTime") {
                let e = try one("2026-09-24T17:01:03Z [ERROR] db: Connection refused")
                try assertEqual(e.timestamp, "2026-09-24T17:01:03Z")
                try assertEqual(e.level, .error)
                try assertEqual(e.message, "db: Connection refused")
            }

            runner.runTest(name: "testGenericBracketedTimestampWithChannelLevel") {
                // Laravel/Monolog: "[zeit] kanal.LEVEL: nachricht"
                let e = try one("[2026-09-24 17:01:02] local.WARNING: Cache miss")
                try assertEqual(e.timestamp, "2026-09-24 17:01:02")
                try assertEqual(e.level, .warning)
                try assertEqual(e.source, "local")
                try assertEqual(e.message, "Cache miss")
            }

            runner.runTest(name: "testPythonLoggingDefaultFormat") {
                let e = try one("WARNING:root:disk almost full")
                try assertEqual(e.level, .warning)
                try assertEqual(e.source, "root")
                try assertEqual(e.message, "disk almost full")
            }

            runner.runTest(name: "testLevelWithoutTimestamp") {
                let e = try one("ERROR: something failed")
                try assertEqual(e.level, .error)
                try assertEqual(e.timestamp, nil)
                try assertEqual(e.message, "something failed")
            }

            runner.runTest(name: "testLevelWordInsideMessageIsNotALevel") {
                // Nur die Kopfposition zaehlt -- sonst wird jede Zeile, die
                // das Wort "error" erwaehnt, zum Fehler.
                let e = try one("2026-09-24 12:00:00 user clicked the error details button")
                try assertEqual(e.level, nil)
                try assertEqual(e.timestamp, "2026-09-24 12:00:00")
                try assertEqual(e.message, "user clicked the error details button")
            }

            runner.runTest(name: "testLowercaseLevelWordWithoutTimestampIsProse") {
                // Ohne Zeitstempel ist "Info about ..." ein Satz, kein Level.
                let e = try one("Info about the nightly job")
                try assertEqual(e.format, .plain)
                try assertEqual(e.level, nil)
                // GROSS geschrieben oder mit Doppelpunkt ist es eindeutig.
                try assertEqual(try one("Info: job started").level, .info)
                try assertEqual(try one("WARN job slow").level, .warning)
            }

            runner.runTest(name: "testTimeOnlyTimestamp") {
                let e = try one("17:01:02.555 DEBUG cache warmed")
                try assertEqual(e.timestamp, "17:01:02.555")
                try assertEqual(e.level, .debug)
                try assertEqual(e.message, "cache warmed")
            }

            runner.runTest(name: "testPlainLineHasNoStructure") {
                let e = try one("hello world")
                try assertEqual(e.format, .plain)
                try assertEqual(e.level, nil)
                try assertEqual(e.timestamp, nil)
                try assertEqual(e.message, "hello world")
            }

            // MARK: logcat

            runner.runTest(name: "testLogcatThreadtime") {
                let e = try one("09-24 17:01:02.123  1234  5678 E AndroidRuntime: FATAL EXCEPTION: main")
                try assertEqual(e.format, .logcat)
                try assertEqual(e.timestamp, "09-24 17:01:02.123")
                try assertEqual(e.level, .error)
                try assertEqual(e.source, "AndroidRuntime")
                try assertEqual(e.message, "FATAL EXCEPTION: main")
            }

            runner.runTest(name: "testLogcatBrief") {
                let e = try one("W/ActivityManager( 1234): Slow operation")
                try assertEqual(e.format, .logcat)
                try assertEqual(e.level, .warning)
                try assertEqual(e.source, "ActivityManager")
                try assertEqual(e.message, "Slow operation")
            }

            // MARK: Strukturiert

            runner.runTest(name: "testJSONLineExtractsCoreFieldsAndKeepsOrder") {
                let e = try one(#"{"time":"2026-09-24T17:01:02Z","level":"error","msg":"boom","user":"anna","count":3}"#)
                try assertEqual(e.format, .json)
                try assertEqual(e.timestamp, "2026-09-24T17:01:02Z")
                try assertEqual(e.level, .error)
                try assertEqual(e.message, "boom")
                try assertEqual(e.fields.map(\.key), ["user", "count"])
                try assertEqual(e.fields[0].value, "anna")
                try assertTrue(e.fields[0].isString)
                try assertEqual(e.fields[1].value, "3")
                try assertFalse(e.fields[1].isString)
            }

            runner.runTest(name: "testPinoJSONLineWithEpochMillis") {
                let e = try one(#"{"level":50,"time":1727197262123,"pid":42,"hostname":"mac","msg":"db down"}"#)
                try assertEqual(e.level, .error)
                try assertEqual(e.timestamp, "2024-09-24 17:01:02.123Z")
                try assertEqual(e.message, "db down")
                try assertEqual(e.fields.map(\.key), ["pid", "hostname"])
            }

            runner.runTest(name: "testJSONLineWithAlternativeKeysAndNestedValue") {
                let e = try one(#"{"@timestamp":"t1","severity":"WARNING","message":"slow","logger":"api","ctx":{"a":[1,2]}}"#)
                try assertEqual(e.timestamp, "t1")
                try assertEqual(e.level, .warning)
                try assertEqual(e.source, "api")
                try assertEqual(e.message, "slow")
                try assertEqual(e.fields.map(\.key), ["ctx"])
                try assertEqual(e.fields[0].value, #"{"a":[1,2]}"#)
            }

            runner.runTest(name: "testBrokenJSONFallsBackToPlain") {
                let e = try one(#"{"level":"error","msg":"#)
                try assertTrue(e.format != .json)
                try assertEqual(e.message, #"{"level":"error","msg":"#)
            }

            runner.runTest(name: "testLogfmtLine") {
                let e = try one(#"time="2026-09-24T17:01:02Z" level=warning msg="disk low" path=/var free=3%"#)
                try assertEqual(e.format, .logfmt)
                try assertEqual(e.timestamp, "2026-09-24T17:01:02Z")
                try assertEqual(e.level, .warning)
                try assertEqual(e.message, "disk low")
                try assertEqual(e.fields.map(\.key), ["path", "free"])
                try assertEqual(e.fields[0].value, "/var")
            }

            // MARK: Access-Log

            runner.runTest(name: "testCombinedAccessLog") {
                let e = try one(#"203.0.113.7 - - [24/Sep/2026:17:01:02 +0200] "GET /api/users?id=3 HTTP/1.1" 404 512 "https://example.com/" "curl/8.4.0""#)
                try assertEqual(e.format, .access)
                try assertEqual(e.timestamp, "24/Sep/2026:17:01:02 +0200")
                try assertEqual(e.source, "203.0.113.7")
                try assertEqual(e.level, .warning, "4xx zaehlt als Warnung")
                let a = try unwrap(e.access)
                try assertEqual(a.method, "GET")
                try assertEqual(a.path, "/api/users?id=3")
                try assertEqual(a.proto, "HTTP/1.1")
                try assertEqual(a.status, 404)
                try assertEqual(a.bytes, "512")
                try assertEqual(a.referer, "https://example.com/")
                try assertEqual(a.userAgent, "curl/8.4.0")
            }

            runner.runTest(name: "testCommonAccessLogStatusClasses") {
                let ok = try one(#"10.0.0.1 - bob [24/Sep/2026:17:01:02 +0000] "POST /login HTTP/2.0" 200 -"#)
                try assertEqual(ok.level, .info)
                try assertEqual(ok.access?.bytes, "-")
                try assertEqual(ok.access?.referer, nil)
                let err = try one(#"10.0.0.1 - - [24/Sep/2026:17:01:02 +0000] "GET / HTTP/1.1" 502 157"#)
                try assertEqual(err.level, .error)
                // Kaputte Request-Zeile (Scanner): der rohe Inhalt bleibt erhalten.
                let junk = try one(#"10.0.0.1 - - [24/Sep/2026:17:01:02 +0000] "\x16\x03\x01" 400 0"#)
                try assertEqual(junk.format, .access)
                try assertEqual(junk.access?.method, nil)
                try assertEqual(junk.access?.path, #"\x16\x03\x01"#)
            }

            // MARK: syslog / unified log

            runner.runTest(name: "testSyslogLine") {
                let e = try one("Sep 24 17:01:02 raspi5 sshd[1234]: Accepted publickey for pi")
                try assertEqual(e.format, .syslog)
                try assertEqual(e.timestamp, "Sep 24 17:01:02")
                try assertEqual(e.source, "raspi5 sshd[1234]")
                try assertEqual(e.message, "Accepted publickey for pi")
            }

            runner.runTest(name: "testSyslogSingleDigitDayWithoutPid") {
                let e = try one("Sep  4 07:30:24 raspi5 kernel: usb 1-1: new device")
                try assertEqual(e.timestamp, "Sep  4 07:30:24")
                try assertEqual(e.source, "raspi5 kernel")
                try assertEqual(e.message, "usb 1-1: new device")
            }

            runner.runTest(name: "testMacOSUnifiedLogLine") {
                let line = "2026-09-24 17:45:35.959564+0200 0x10529bc  Error       0x0                  85035  0    LoupePreview: [io.celox:Preview] failed"
                let e = try one(line)
                try assertEqual(e.format, .unifiedLog)
                try assertEqual(e.timestamp, "2026-09-24 17:45:35.959564+0200")
                try assertEqual(e.level, .error)
                try assertEqual(e.source, "LoupePreview[85035]")
                try assertEqual(e.message, "[io.celox:Preview] failed")
            }

            runner.runTest(name: "testUnifiedLogTypesMapToLevels") {
                func lvl(_ type: String) -> LogLevel? {
                    let l = "2026-09-24 17:45:35.959564+0200 0x1  \(type)  0x0  1  0    proc: x"
                    return LogParser.parse(text: l).entries.first?.level
                }
                try assertEqual(lvl("Default"), .notice)
                try assertEqual(lvl("Info"), .info)
                try assertEqual(lvl("Debug"), .debug)
                try assertEqual(lvl("Fault"), .fatal)
            }

            // MARK: Folgezeilen

            runner.runTest(name: "testJavaStackTraceAttachesToEntry") {
                let text = """
                2026-09-24 17:01:02 ERROR [main] Request failed
                java.lang.IllegalStateException: boom
                \tat com.x.Foo.bar(Foo.java:12)
                \tat com.x.Main.main(Main.java:3)
                Caused by: java.io.IOException: nope
                \t... 2 more
                2026-09-24 17:01:03 INFO [main] recovered
                """
                let doc = LogParser.parse(text: text)
                try assertEqual(doc.entries.count, 2)
                try assertEqual(doc.entries[0].continuation.count, 5)
                try assertEqual(doc.entries[0].continuation[0].lineNumber, 2)
                try assertEqual(doc.entries[0].continuation[1].text, "\tat com.x.Foo.bar(Foo.java:12)")
                try assertEqual(doc.entries[1].lineNumber, 7)
                try assertEqual(doc.entries[1].level, .info)
            }

            runner.runTest(name: "testPythonTracebackAttachesToEntry") {
                let text = """
                2026-09-24 17:01:02,001 ERROR app: crashed
                Traceback (most recent call last):
                  File "app.py", line 3, in <module>
                ValueError: bad value

                2026-09-24 17:01:05,001 INFO app: restarted
                """
                let doc = LogParser.parse(text: text)
                try assertEqual(doc.entries.count, 2)
                try assertEqual(doc.entries[0].timestamp, "2026-09-24 17:01:02,001")
                try assertEqual(doc.entries[0].continuation.count, 4, "inkl. Leerzeile")
            }

            runner.runTest(name: "testPlainFileLinesStaySeparate") {
                let doc = LogParser.parse(text: "first line\nsecond line\n  indented third")
                try assertEqual(doc.entries.count, 3)
                try assertTrue(doc.entries.allSatisfy { $0.continuation.isEmpty })
            }

            runner.runTest(name: "testTrailingNewlineAddsNoEmptyEntry") {
                let doc = LogParser.parse(text: "ERROR a\nINFO b\n")
                try assertEqual(doc.entries.count, 2)
                try assertEqual(doc.totalLines, 2)
            }

            runner.runTest(name: "testCRLFLineEndings") {
                let doc = LogParser.parse(text: "ERROR a\r\nINFO b\r\n")
                try assertEqual(doc.entries.count, 2)
                try assertEqual(doc.entries[0].message, "a")
            }

            // MARK: Dokument

            runner.runTest(name: "testLevelCountsAndDominantFormat") {
                let text = """
                Sep 24 17:01:02 h app[1]: a
                Sep 24 17:01:03 h app[1]: b
                ERROR: c
                """
                let doc = LogParser.parse(text: text)
                try assertEqual(doc.levelCounts[.error], 1)
                try assertEqual(doc.levelCounts[.info], nil)
                try assertEqual(doc.dominantFormat, .syslog)
            }

            runner.runTest(name: "testLineCapKeepsNewestLines") {
                let text = (1...50).map { "INFO line \($0)" }.joined(separator: "\n")
                let doc = LogParser.parse(text: text, maxLines: 10)
                try assertEqual(doc.entries.count, 10)
                try assertEqual(doc.droppedLines, 40)
                try assertEqual(doc.entries.first?.message, "line 41")
                try assertEqual(doc.entries.first?.lineNumber, 41, "Zeilennummern bleiben absolut")
                try assertEqual(doc.entries.last?.message, "line 50")
            }

            runner.runTest(name: "testStartsMidLineDropsThePartialFirstLine") {
                // firstLineNumber = Nummer der (angeschnittenen) ersten Zeile im Text.
                let doc = LogParser.parse(text: "tial line\nINFO whole\n", startsMidLine: true,
                                          firstLineNumber: 101)
                try assertEqual(doc.entries.count, 1)
                try assertEqual(doc.entries[0].message, "whole")
                try assertEqual(doc.entries[0].lineNumber, 102)
            }

            runner.runTest(name: "testTimezoneWithHoursOnly") {
                let e = try one("2026-09-24 18:19:03+02 INFO sandbox purged")
                try assertEqual(e.timestamp, "2026-09-24 18:19:03+02")
                try assertEqual(e.message, "sandbox purged")
            }

            runner.runTest(name: "testSyslogWithISOTimestamp") {
                // macOS install.log und journalctl -o short-iso
                let a = try one("2026-09-24 18:19:03+02 MacBookPro installd[98741]: PackageKit: done")
                try assertEqual(a.format, .syslog)
                try assertEqual(a.timestamp, "2026-09-24 18:19:03+02")
                try assertEqual(a.source, "MacBookPro installd[98741]")
                try assertEqual(a.message, "PackageKit: done")
                let b = try one("2026-09-24T18:19:03+0200 raspi5 systemd[1]: Started nginx.service.")
                try assertEqual(b.format, .syslog)
                try assertEqual(b.source, "raspi5 systemd[1]")
            }

            runner.runTest(name: "testLevelWordIsNeverASyslogHost") {
                let e = try one("2026-09-24 17:01:02 ERROR app: crashed")
                try assertEqual(e.format, .generic)
                try assertEqual(e.level, .error)
                let f = try one("2026-09-24T17:01:03Z [ERROR] db: Connection refused")
                try assertEqual(f.format, .generic)
            }

            runner.runTest(name: "testOrphanContinuationAtTopBecomesPlainEntry") {
                // Nach dem Kappen kann die erste behaltene Zeile ein Stackframe sein.
                let doc = LogParser.parse(text: "\tat com.x.Foo(Foo.java:1)\nINFO ok")
                try assertEqual(doc.entries.count, 2)
                try assertEqual(doc.entries[0].format, .plain)
            }
        }
    }
}

func unwrap<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) throws -> T {
    guard let value else {
        throw TestFailure(message: "Expected a value, got nil", file: file, line: line)
    }
    return value
}
