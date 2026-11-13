import Foundation
import UniformTypeIdentifiers
import LoupeCore

/// Java-Keystores und `.properties`. Die Fixtures unter Tests/Fixtures/keystore
/// stammen aus `keytool` (Passwort "loupe-test", nur fuer diese Tests erzeugt);
/// die erwarteten Werte sind die Ausgabe von `keytool -list -v`.
@MainActor
public enum KeystoreTests {
    private static let fixtures = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Fixtures/keystore")

    private static func load(_ name: String) throws -> Data {
        try Data(contentsOf: fixtures.appendingPathComponent(name))
    }

    private static func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = 12
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: c)!
    }

    private static func hl(_ code: String) -> String {
        SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "properties")
    }

    public static func run() {
        let runner = TestRunner.shared

        runner.suite("Properties") {
            runner.runTest(name: "testPropertiesRouteToTheCodeRenderer") {
                try assertTrue(SourceCodePreviewRenderer.supportedExtensions.contains("properties"))
                let r = RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/keystore.properties"))
                try assertTrue(r is SourceCodePreviewRenderer, "\(String(describing: r))")
                try assertEqual(SupportedLanguage.from(identifier: "properties"), .properties)
                try assertEqual(SupportedLanguage.properties.displayName, "Properties")
            }

            runner.runTest(name: "testKeySeparatorAndValueGetTheirOwnColors") {
                let html = hl("storeFile=release.jks")
                try assertEqual(html, #"<span class="hl-prop">storeFile</span><span class="hl-op">=</span><span class="hl-str">release.jks</span>"#)
            }

            runner.runTest(name: "testColonAndBlankSeparators") {
                try assertTrue(hl("keyAlias: upload").contains(#"<span class="hl-prop">keyAlias</span><span class="hl-op">:</span> <span class="hl-str">upload</span>"#), hl("keyAlias: upload"))
                try assertEqual(hl("key value"), #"<span class="hl-prop">key</span> <span class="hl-str">value</span>"#)
            }

            runner.runTest(name: "testOnlyTheFirstSeparatorSplits") {
                // Ein Passwort darf "=" und ":" enthalten -- es gehoert ganz zum Wert.
                let html = hl("password=a=b:c")
                try assertTrue(html.hasSuffix(#"<span class="hl-str">a=b:c</span>"#), html)
                // Direkt nach dem Trenner: das zweite "=" ist schon der Wert.
                try assertEqual(hl("key==value"),
                                #"<span class="hl-prop">key</span><span class="hl-op">=</span><span class="hl-str">=value</span>"#)
            }

            runner.runTest(name: "testHashAndBangStartComments") {
                try assertEqual(hl("# note"), #"<span class="hl-com"># note</span>"#)
                try assertEqual(hl("  ! note"), #"  <span class="hl-com">! note</span>"#)
                // Mitten im Wert ist "#" kein Kommentar.
                try assertTrue(hl("color=#ff0000").contains(#"<span class="hl-str">#ff0000</span>"#))
            }

            runner.runTest(name: "testBooleansAndNumbersAreTyped") {
                try assertTrue(hl("minify=true").contains(#"<span class="hl-kw">true</span>"#))
                try assertTrue(hl("versionCode=42").contains(#"<span class="hl-num">42</span>"#))
                // Eine Versionsnummer ist keine Zahl.
                try assertTrue(hl("version=1.2.3").contains(#"<span class="hl-str">1.2.3</span>"#))
            }

            runner.runTest(name: "testBackslashContinuesTheValueOnTheNextLine") {
                let html = hl("text=first \\\n    key=second\nnext=1")
                let lines = html.components(separatedBy: "\n")
                try assertEqual(lines.count, 3)
                try assertEqual(lines[1], #"<span class="hl-str">    key=second</span>"#, "Fortsetzung ist Wert, kein Schluessel")
                try assertTrue(lines[2].hasPrefix(#"<span class="hl-prop">next</span>"#), lines[2])
                // Zwei Backslashes sind ein maskierter Backslash, keine Fortsetzung.
                let escaped = hl("path=C:\\\\\nnext=1").components(separatedBy: "\n")
                try assertTrue(escaped[1].hasPrefix(#"<span class="hl-prop">next</span>"#), escaped[1])
            }

            runner.runTest(name: "testEscapedSeparatorStaysInTheKey") {
                try assertTrue(hl(#"a\=b=c"#).hasPrefix(#"<span class="hl-prop">a\=b</span>"#), hl(#"a\=b=c"#))
            }

            runner.runTest(name: "testValuesAreEscaped") {
                let html = hl("x=<script>alert(1)</script>")
                try assertFalse(html.contains("<script>"), html)
                try assertTrue(html.contains("&lt;script&gt;"), html)
            }
        }

        runner.suite("Keystore parser") {
            runner.runTest(name: "testJKSListsAliasesAndCertificatesWithoutPassword") {
                let doc = KeystoreParser.parse(try load("release.jks"))
                try assertEqual(doc.format, .jks)
                try assertEqual(doc.declaredEntries, 2)
                try assertEqual(Set(doc.entries.map(\.alias)), ["upload", "ec-key"])
                try assertTrue(doc.entries.allSatisfy { $0.kind == .privateKey })
                try assertTrue(doc.notes.isEmpty, "\(doc.notes)")
                let upload = try unwrap(doc.entries.first { $0.alias == "upload" }?.certificates.first)
                try assertEqual(upload.subject, "CN=Loupe Test, OU=Mobile, O=Loupe, L=Berlin, C=DE")
                try assertTrue(upload.isSelfSigned)
                try assertEqual(upload.publicKey, "RSA 2048 Bit")
                try assertEqual(upload.signatureAlgorithm, "SHA256withRSA")
                try assertEqual(upload.serialHex, "C3:53:75:4A:B8:A2:9E:22", "ohne Vorzeichen-Byte, wie keytool")
                try assertEqual(upload.sha1, "5F:4F:6D:8A:38:E5:1A:6D:50:2D:B8:C9:B8:61:85:4F:D2:B5:D5:03")
                try assertEqual(upload.sha256, "5C:71:ED:AE:FA:1E:DE:E2:36:08:D8:97:31:3D:7D:9C:00:FD:1C:57:95:81:BA:5E:0E:BA:54:43:FC:CD:DB:45")
                try assertEqual(upload.notBefore.map(KeystorePreviewRenderer.day), "2026-11-13")
                try assertEqual(upload.notAfter.map(KeystorePreviewRenderer.day), "2051-11-07")
            }

            runner.runTest(name: "testEllipticCurveKeyNamesItsCurve") {
                let doc = KeystoreParser.parse(try load("release.jks"))
                let ec = try unwrap(doc.entries.first { $0.alias == "ec-key" }?.certificates.first)
                try assertEqual(ec.publicKey, "EC P-256")
                try assertEqual(ec.signatureAlgorithm, "SHA256withECDSA")
                try assertEqual(ec.sha1, "A6:ED:E2:EB:3B:60:03:24:95:81:DF:82:B5:EE:C5:48:93:3B:28:85")
            }

            runner.runTest(name: "testTruststoreEntryIsACertificate") {
                let doc = KeystoreParser.parse(try load("truststore.jks"))
                try assertEqual(doc.entries.map(\.alias), ["trusted-root"])
                try assertEqual(doc.entries.first?.kind, .trustedCertificate)
                try assertEqual(doc.entries.first?.certificates.first?.subject,
                                "CN=Loupe Test, OU=Mobile, O=Loupe, L=Berlin, C=DE")
            }

            runner.runTest(name: "testJKSCarriesTheCreationDate") {
                let doc = KeystoreParser.parse(try load("truststore.jks"))
                try assertEqual(doc.entries.first?.created.map(KeystorePreviewRenderer.day), "2026-11-13")
            }

            runner.runTest(name: "testPKCS12ShowsTheKeyAliasAndSaysWhatIsEncrypted") {
                // keytool schreibt seit Java 9 PKCS #12, auch in Dateien namens .jks.
                let doc = KeystoreParser.parse(try load("pkcs12.jks"))
                try assertEqual(doc.format, .pkcs12)
                try assertEqual(doc.entries.map(\.alias), ["upload"])
                try assertEqual(doc.entries.first?.kind, .privateKey)
                try assertEqual(doc.entries.first?.certificates.count, 0, "Zertifikate sind verschluesselt")
                try assertEqual(doc.encryptedParts, 1)
                try assertTrue(doc.notes.joined().contains("verschlüsselt"), "\(doc.notes)")
            }

            runner.runTest(name: "testJCEKSSecretKeyIsNamedNotRead") {
                let doc = KeystoreParser.parse(try load("secret.jceks.keystore"))
                try assertEqual(doc.format, .jceks)
                try assertEqual(doc.declaredEntries, 2)
                try assertTrue(doc.entries.contains { $0.alias == "aes" && $0.kind == .secretKey })
            }

            runner.runTest(name: "testTruncatedFileKeepsWhatWasReadable") {
                let full = try load("release.jks")
                // Mitten im zweiten Eintrag abgeschnitten.
                let doc = KeystoreParser.parse(full.prefix(full.count - 400))
                try assertEqual(doc.format, .jks)
                try assertEqual(doc.entries.count, 1)
                try assertTrue(doc.notes.joined().contains("beschädigt"), "\(doc.notes)")
            }

            runner.runTest(name: "testEveryPrefixParsesWithoutCrashing") {
                // Fremde Binaerdatei: jede Laenge und jedes gekippte Byte muss
                // durchlaufen, ohne dass die Vorschau abstuerzt.
                for name in ["release.jks", "pkcs12.jks", "secret.jceks.keystore"] {
                    let full = try load(name)
                    for length in stride(from: 0, to: full.count, by: 7) {
                        _ = KeystoreParser.parse(full.prefix(length))
                    }
                    var bytes = [UInt8](full)
                    for index in stride(from: 0, to: bytes.count, by: 5) {
                        let saved = bytes[index]
                        bytes[index] = 0xFF
                        _ = KeystoreParser.parse(Data(bytes))
                        bytes[index] = saved
                    }
                }
            }

            runner.runTest(name: "testUnknownAndEmptyFilesSayWhy") {
                try assertEqual(KeystoreParser.parse(Data()).format, .unknown)
                let text = KeystoreParser.parse(Data("just some text, not a keystore".utf8))
                try assertEqual(text.format, .unknown)
                try assertTrue(text.entries.isEmpty)
                try assertFalse(text.notes.isEmpty)
                // Bouncy Castle: Version 2 als erste vier Bytes.
                try assertEqual(KeystoreParser.parse(Data([0, 0, 0, 2, 0, 0, 0, 20])).format, .bks)
            }

            runner.runTest(name: "testHugeDeclaredLengthsDoNotAllocate") {
                // Kopf behauptet 4 Mrd. Eintraege und ein Alias, das es nicht gibt.
                var bytes: [UInt8] = [0xFE, 0xED, 0xFE, 0xED, 0, 0, 0, 2, 0xFF, 0xFF, 0xFF, 0xFF]
                bytes += [0, 0, 0, 1, 0xFF, 0xFF]
                let doc = KeystoreParser.parse(Data(bytes))
                try assertTrue(doc.entries.isEmpty)
                try assertFalse(doc.notes.isEmpty)
            }
        }

        runner.suite("Keystore preview") {
            let renderer = KeystorePreviewRenderer()

            runner.runTest(name: "testKeystoreExtensionsRouteToTheKeystoreRenderer") {
                for name in ["release.jks", "debug.keystore", "RELEASE.JKS"] {
                    let r = RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/\(name)"))
                    try assertTrue(r is KeystorePreviewRenderer, "\(name) -> \(String(describing: r))")
                }
                try assertFalse(SourceCodePreviewRenderer.supportedExtensions.contains("jks"),
                                "ein Binaerformat darf nie als Code gezeigt werden")
            }

            runner.runTest(name: "testKeystoreHasItsOwnSwitchAndNoPlainTextFallback") {
                try assertEqual(KeystorePreviewRenderer.category, .keystore)
                try assertFalse(KeystorePreviewRenderer.plainTextWhenDisabled,
                                "abgeschaltet: Datei-Karte statt Zeichensalat")
                try assertTrue(SourceCodePreviewRenderer.plainTextWhenDisabled)
                try assertTrue(ChartPreviewRenderer.plainTextWhenDisabled)
            }

            runner.runTest(name: "testBodyShowsAliasKindAndFingerprints") {
                let doc = KeystoreParser.parse(try load("release.jks"))
                let html = renderer.renderBody(document: doc, filename: "release.jks", totalBytes: 2755,
                                               truncated: false, now: date(2027, 1, 1))
                try assertTrue(html.contains(#"<span class="lp-badge">JKS</span>"#), html)
                try assertTrue(html.contains("<span>2 Einträge</span>"))
                try assertTrue(html.contains(#"<span class="ks-alias">upload</span>"#))
                try assertTrue(html.contains("Privater Schlüssel"))
                try assertTrue(html.contains("5F:4F:6D:8A:38:E5:1A:6D:50:2D:B8:C9:B8:61:85:4F:D2:B5:D5:03"))
                try assertTrue(html.contains("selbstsigniert"))
                try assertTrue(html.contains("Schlüssel bleiben verschlüsselt"))
            }

            runner.runTest(name: "testValidityStatesFollowTheClock") {
                let doc = KeystoreParser.parse(try load("release.jks"))
                let ec = try unwrap(doc.entries.first { $0.alias == "ec-key" }?.certificates.first)
                // Gueltig 2026-11-13 bis 2026-12-13.
                try assertTrue(renderer.validity(ec, now: date(2026, 11, 1)).contains("noch nicht gültig"))
                try assertTrue(renderer.validity(ec, now: date(2026, 12, 1)).contains("läuft in 11 Tagen ab"),
                               renderer.validity(ec, now: date(2026, 12, 1)))
                try assertTrue(renderer.validity(ec, now: date(2027, 1, 1)).contains("abgelaufen"))
                let rsa = try unwrap(doc.entries.first { $0.alias == "upload" }?.certificates.first)
                let fine = renderer.validity(rsa, now: date(2030, 1, 1))
                try assertTrue(fine.contains(#"ks-ok">gültig"#), fine)
                try assertFalse(fine.contains("läuft"), fine)
            }

            runner.runTest(name: "testAliasIsEscaped") {
                let entry = KeystoreEntry(alias: "<img src=x onerror=alert(1)>", kind: .trustedCertificate,
                                          created: nil, certificates: [], unreadableCertificates: 0)
                let doc = KeystoreDocument(format: .jks, declaredEntries: 1, entries: [entry],
                                           encryptedParts: 0, notes: ["<b>note</b>"])
                let html = renderer.renderBody(document: doc, filename: "<x>.jks", totalBytes: 10,
                                               truncated: false, now: Date())
                try assertFalse(html.contains("<img"), html)
                try assertFalse(html.contains("<b>note"), html)
                try assertFalse(html.contains("<x>"), html)
            }

            runner.runTest(name: "testUnknownFormatRendersANoticeNotGarbage") {
                let input = PreviewInput(data: Data("no keystore".utf8),
                                         url: URL(fileURLWithPath: "/tmp/broken.jks"), wasTruncatedByReader: false)
                let html = renderer.renderHTML(input: input, settings: LoupeSettings())
                try assertTrue(html.contains("Kein bekanntes Keystore-Format"), html)
                try assertTrue(html.contains(#"<span class="lp-badge">KEYSTORE</span>"#))
                try assertFalse(html.contains("Einträge</span>"), "ohne Format keine Eintragszahl")
            }

            runner.runTest(name: "testPreviewNeverContainsKeyMaterial") {
                // Der verschluesselte private Schluessel steht in der Datei; kein
                // Byte davon darf in der Vorschau landen. Geprueft: die Vorschau ist
                // kleiner als ein Hex-Abzug des Schluessels und nennt nur Zertifikatsfelder.
                let input = PreviewInput(data: try load("release.jks"),
                                         url: URL(fileURLWithPath: "/tmp/release.jks"), wasTruncatedByReader: false)
                let html = renderer.renderHTML(input: input, settings: LoupeSettings())
                let body = html.components(separatedBy: "<body").last ?? ""
                let longHex = try NSRegularExpression(pattern: "(?:[0-9A-F]{2}:){40,}")
                try assertEqual(longHex.numberOfMatches(in: body, range: NSRange(body.startIndex..., in: body)), 0,
                                "laenger als ein SHA-256 ist kein Fingerabdruck")
            }
        }
    }

    private static func unwrap<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) throws -> T {
        guard let value else { throw TestFailure(message: "nil", file: file, line: line) }
        return value
    }
}
