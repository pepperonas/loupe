import Foundation

/// Ein Eintrag eines Keystores, soweit er OHNE Passwort lesbar ist.
public struct KeystoreEntry: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case privateKey, trustedCertificate, secretKey
    }
    public let alias: String
    public let kind: Kind
    /// Anlagezeitpunkt (JKS/JCEKS speichern ihn; PKCS #12 nicht).
    public let created: Date?
    /// Zertifikatskette, das eigene Zertifikat zuerst.
    public let certificates: [X509Summary]
    /// Zertifikate, die da sind, sich aber nicht lesen liessen.
    public let unreadableCertificates: Int

    public init(alias: String, kind: Kind, created: Date?,
                certificates: [X509Summary], unreadableCertificates: Int) {
        self.alias = alias
        self.kind = kind
        self.created = created
        self.certificates = certificates
        self.unreadableCertificates = unreadableCertificates
    }
}

public struct KeystoreDocument: Equatable, Sendable {
    public enum Format: String, Equatable, Sendable {
        case jks = "JKS", jceks = "JCEKS", pkcs12 = "PKCS #12", bks = "BKS", unknown = ""
    }
    public let format: Format
    /// Laut Dateikopf (JKS/JCEKS); nil, wenn das Format keine Zahl nennt.
    public let declaredEntries: Int?
    public let entries: [KeystoreEntry]
    /// PKCS #12: Teile, die mit dem Passwort verschluesselt sind (meist die Zertifikate).
    public let encryptedParts: Int
    /// Klartext-Hinweise, warum etwas fehlt.
    public let notes: [String]

    public init(format: Format, declaredEntries: Int?, entries: [KeystoreEntry],
                encryptedParts: Int, notes: [String]) {
        self.format = format
        self.declaredEntries = declaredEntries
        self.entries = entries
        self.encryptedParts = encryptedParts
        self.notes = notes
    }
}

/// Liest Java-Keystores. Nichts wird entschluesselt und kein Passwort gebraucht:
/// JKS und JCEKS legen Aliase und Zertifikate offen ab, nur die privaten
/// Schluessel sind verschluesselt. PKCS #12 verschluesselt meist auch die
/// Zertifikate -- dort bleiben die Aliase der Schluessel lesbar.
public enum KeystoreParser {

    /// Mehr Eintraege werden nicht gelesen (ein Truststore hat ~150).
    public static let maxEntries = 1_000

    public static func parse(_ data: Data) -> KeystoreDocument {
        let bytes = [UInt8](data)
        guard bytes.count >= 4 else {
            return KeystoreDocument(format: .unknown, declaredEntries: nil, entries: [], encryptedParts: 0,
                                    notes: ["Die Datei ist zu kurz für einen Keystore."])
        }
        let magic = UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3])
        switch magic {
        case 0xFEED_FEED: return parseJKS(bytes, format: .jks)
        case 0xCECE_CECE: return parseJKS(bytes, format: .jceks)
        default: break
        }
        if bytes[0] == 0x30, let document = parsePKCS12(bytes) { return document }
        // BKS (Bouncy Castle, aeltere Android-Projekte): Version 1 oder 2 als 4 Bytes.
        if magic == 1 || magic == 2 {
            return KeystoreDocument(format: .bks, declaredEntries: nil, entries: [], encryptedParts: 0,
                                    notes: ["Vermutlich ein Bouncy-Castle-Keystore (BKS). Dieses Format liest Loupe nicht."])
        }
        return KeystoreDocument(format: .unknown, declaredEntries: nil, entries: [], encryptedParts: 0,
                                notes: ["Kein bekanntes Keystore-Format (weder JKS, JCEKS noch PKCS #12)."])
    }

    // MARK: - JKS / JCEKS

    private struct Cursor {
        let bytes: [UInt8]
        var index = 0

        mutating func u16() -> Int? {
            guard bytes.count - index >= 2 else { return nil }
            defer { index += 2 }
            return Int(bytes[index]) << 8 | Int(bytes[index + 1])
        }
        mutating func u32() -> Int? {
            guard bytes.count - index >= 4 else { return nil }
            defer { index += 4 }
            return Int(bytes[index]) << 24 | Int(bytes[index + 1]) << 16 | Int(bytes[index + 2]) << 8 | Int(bytes[index + 3])
        }
        mutating func u64() -> UInt64? {
            guard bytes.count - index >= 8 else { return nil }
            defer { index += 8 }
            return bytes[index..<(index + 8)].reduce(0) { $0 << 8 | UInt64($1) }
        }
        mutating func take(_ count: Int) -> [UInt8]? {
            guard count >= 0, bytes.count - index >= count else { return nil }
            defer { index += count }
            return Array(bytes[index..<(index + count)])
        }
        /// Java `writeUTF`: 2 Bytes Laenge, dann (modifiziertes) UTF-8.
        mutating func utf() -> String? {
            guard let length = u16(), let raw = take(length) else { return nil }
            return String(decoding: raw, as: UTF8.self)
        }
    }

    private static func parseJKS(_ bytes: [UInt8], format: KeystoreDocument.Format) -> KeystoreDocument {
        var cursor = Cursor(bytes: bytes, index: 4)
        var notes: [String] = []
        guard let version = cursor.u32(), let count = cursor.u32() else {
            return KeystoreDocument(format: format, declaredEntries: nil, entries: [], encryptedParts: 0,
                                    notes: ["Der Dateikopf ist unvollständig."])
        }
        guard version == 1 || version == 2 else {
            return KeystoreDocument(format: format, declaredEntries: count, entries: [], encryptedParts: 0,
                                    notes: ["Unbekannte Keystore-Version \(version)."])
        }

        /// Version 2 nennt vor jedem Zertifikat dessen Typ ("X.509").
        func certificate(_ cursor: inout Cursor) -> (summary: X509Summary?, ok: Bool) {
            if version == 2, cursor.utf() == nil { return (nil, false) }
            guard let length = cursor.u32(), let der = cursor.take(length) else { return (nil, false) }
            return (X509Parser.parse(der), true)
        }

        var entries: [KeystoreEntry] = []
        var complete = true
        loop: for _ in 0..<min(count, maxEntries) {
            guard let tag = cursor.u32(), let alias = cursor.utf(), let millis = cursor.u64() else {
                complete = false
                break
            }
            let created = Date(timeIntervalSince1970: Double(millis) / 1000)
            var certificates: [X509Summary] = []
            var unreadable = 0
            switch tag {
            case 1:  // privater Schluessel + Kette
                guard let keyLength = cursor.u32(), cursor.take(keyLength) != nil,
                      let chain = cursor.u32() else { complete = false; break loop }
                for _ in 0..<min(chain, 64) {
                    let result = certificate(&cursor)
                    guard result.ok else { complete = false; break loop }
                    if let summary = result.summary { certificates.append(summary) } else { unreadable += 1 }
                }
                entries.append(KeystoreEntry(alias: alias, kind: .privateKey, created: created,
                                             certificates: certificates, unreadableCertificates: unreadable))
            case 2:  // vertrauenswuerdiges Zertifikat
                let result = certificate(&cursor)
                guard result.ok else { complete = false; break loop }
                if let summary = result.summary { certificates.append(summary) } else { unreadable += 1 }
                entries.append(KeystoreEntry(alias: alias, kind: .trustedCertificate, created: created,
                                             certificates: certificates, unreadableCertificates: unreadable))
            case 3 where format == .jceks:
                // Geheimer Schluessel als serialisiertes Java-Objekt: dessen Laenge
                // steht nirgends, dahinter laesst sich nicht weiterlesen.
                entries.append(KeystoreEntry(alias: alias, kind: .secretKey, created: created,
                                             certificates: [], unreadableCertificates: 0))
                if entries.count < count {
                    notes.append("Nach einem geheimen Schlüssel lassen sich die folgenden Einträge nicht lesen.")
                }
                complete = true
                break loop
            default:
                complete = false
                break loop
            }
        }
        if !complete {
            notes.append("Die Datei endet mitten in einem Eintrag oder ist beschädigt — gezeigt wird, was lesbar war.")
        } else if count > maxEntries {
            notes.append("Nur die ersten \(maxEntries) von \(count) Einträgen wurden gelesen.")
        }
        return KeystoreDocument(format: format, declaredEntries: count, entries: entries,
                                encryptedParts: 0, notes: notes)
    }

    // MARK: - PKCS #12

    private static let oidData = "1.2.840.113549.1.7.1"
    private static let oidEncryptedData = "1.2.840.113549.1.7.6"
    private static let oidKeyBag = "1.2.840.113549.1.12.10.1.1"
    private static let oidShroudedKeyBag = "1.2.840.113549.1.12.10.1.2"
    private static let oidCertBag = "1.2.840.113549.1.12.10.1.3"
    private static let oidSecretBag = "1.2.840.113549.1.12.10.1.5"
    private static let oidFriendlyName = "1.2.840.113549.1.9.20"
    private static let oidLocalKeyID = "1.2.840.113549.1.9.21"

    /// PFX ::= SEQUENCE { version INTEGER (3), authSafe ContentInfo, macData OPTIONAL }
    private static func parsePKCS12(_ bytes: [UInt8]) -> KeystoreDocument? {
        guard let pfx = DERReader.first(in: bytes[...]), pfx.tag == 0x30 else { return nil }
        let top = pfx.children
        guard top.count >= 2, top[0].tag == 0x02, Array(top[0].content) == [3],
              let safe = contentOfData(top[1]) else { return nil }

        var keys: [(alias: String?, keyID: [UInt8]?)] = []
        var certs: [(alias: String?, keyID: [UInt8]?, summary: X509Summary?)] = []
        var secrets: [String?] = []
        var encrypted = 0
        // Dieselbe Obergrenze wie bei JKS: eine praeparierte Datei kann sonst
        // hunderttausende winzige Bags enthalten.
        var capped = false

        outer: for info in DERReader.first(in: safe[...])?.children ?? [] {
            guard let oid = info.children.first?.oid else { continue }
            if oid == oidEncryptedData { encrypted += 1; continue }
            guard oid == oidData, let bags = contentOfData(info) else { continue }
            for bag in DERReader.first(in: bags[...])?.children ?? [] {
                guard keys.count + certs.count + secrets.count < maxEntries else {
                    capped = true
                    break outer
                }
                let parts = bag.children
                guard let bagID = parts.first?.oid else { continue }
                var alias: String?
                var keyID: [UInt8]?
                for attribute in parts.first(where: { $0.tag == 0x31 })?.children ?? [] {
                    let kv = attribute.children
                    guard kv.count >= 2, let name = kv[0].oid, let value = kv[1].children.first else { continue }
                    if name == oidFriendlyName { alias = value.string }
                    if name == oidLocalKeyID { keyID = Array(value.content) }
                }
                switch bagID {
                case oidKeyBag, oidShroudedKeyBag:
                    keys.append((alias, keyID))
                case oidSecretBag:
                    secrets.append(alias)
                case oidCertBag:
                    // [0] { SEQUENCE { certId, [0] { OCTET STRING Zertifikat } } }
                    let der = parts.first(where: { $0.tag == 0xA0 })?.children.first?
                        .children.first(where: { $0.tag == 0xA0 })?.children.first
                    certs.append((alias, keyID, der.flatMap { X509Parser.parse(Array($0.content)) }))
                default:
                    continue
                }
            }
        }

        var entries: [KeystoreEntry] = []
        var used = Set<Int>()
        // Ein Zertifikat gehoert zum Schluessel mit derselben localKeyID. Ueber
        // ein Woerterbuch zugeordnet -- eine Schleife je Schluessel waere quadratisch.
        var certsByKeyID: [[UInt8]: [Int]] = [:]
        for (index, cert) in certs.enumerated() {
            if let id = cert.keyID { certsByKeyID[id, default: []].append(index) }
        }
        for key in keys {
            var chain: [X509Summary] = []
            var unreadable = 0
            for index in key.keyID.flatMap({ certsByKeyID[$0] }) ?? [] where !used.contains(index) {
                used.insert(index)
                if let summary = certs[index].summary { chain.append(summary) } else { unreadable += 1 }
            }
            entries.append(KeystoreEntry(alias: key.alias ?? "(ohne Alias)", kind: .privateKey, created: nil,
                                         certificates: chain, unreadableCertificates: unreadable))
        }
        for (index, cert) in certs.enumerated() where !used.contains(index) {
            entries.append(KeystoreEntry(alias: cert.alias ?? "(ohne Alias)", kind: .trustedCertificate, created: nil,
                                         certificates: cert.summary.map { [$0] } ?? [],
                                         unreadableCertificates: cert.summary == nil ? 1 : 0))
        }
        for alias in secrets {
            entries.append(KeystoreEntry(alias: alias ?? "(ohne Alias)", kind: .secretKey, created: nil,
                                         certificates: [], unreadableCertificates: 0))
        }

        var notes: [String] = []
        if capped {
            notes.append("Nur die ersten \(maxEntries) Einträge wurden gelesen.")
        }
        if encrypted > 0 {
            notes.append(encrypted == 1
                ? "Ein Teil der Datei ist mit dem Keystore-Passwort verschlüsselt — in der Regel die Zertifikate. Ohne Passwort bleiben sie unsichtbar."
                : "\(encrypted) Teile der Datei sind mit dem Keystore-Passwort verschlüsselt — in der Regel die Zertifikate. Ohne Passwort bleiben sie unsichtbar.")
        }
        return KeystoreDocument(format: .pkcs12, declaredEntries: nil, entries: entries,
                                encryptedParts: encrypted, notes: notes)
    }

    /// ContentInfo ::= SEQUENCE { contentType OID (data), [0] EXPLICIT OCTET STRING }
    private static func contentOfData(_ info: DERNode) -> [UInt8]? {
        let parts = info.children
        guard parts.count >= 2, parts[0].oid == oidData, parts[1].tag == 0xA0,
              let octets = parts[1].children.first, octets.tag == 0x04 else { return nil }
        return Array(octets.content)
    }
}
