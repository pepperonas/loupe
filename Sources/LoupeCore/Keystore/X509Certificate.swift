import Foundation
import CryptoKit

/// Was die Vorschau von einem X.509-Zertifikat zeigt. Bewusst klein: gelesen wird
/// nur der Kopf (Inhaber, Aussteller, Gueltigkeit, Schluesselart), nichts geprueft.
public struct X509Summary: Equatable, Sendable {
    public let subject: String
    public let issuer: String
    public let notBefore: Date?
    public let notAfter: Date?
    public let serialHex: String
    public let signatureAlgorithm: String
    public let publicKey: String
    public let sha1: String
    public let sha256: String

    public var isSelfSigned: Bool { subject == issuer }
}

public enum X509Parser {

    public static func parse(_ der: [UInt8]) -> X509Summary? {
        guard let cert = DERReader.first(in: der[...]), cert.tag == 0x30 else { return nil }
        let outer = cert.children
        guard let tbs = outer.first, tbs.tag == 0x30 else { return nil }
        var fields = tbs.children[...]
        // [0] EXPLICIT Version ist optional (fehlt bei v1-Zertifikaten).
        if fields.first?.tag == 0xA0 { fields = fields.dropFirst() }
        guard fields.count >= 6 else { return nil }
        let f = Array(fields)
        guard f[0].tag == 0x02, f[1].tag == 0x30, f[2].tag == 0x30,
              f[3].tag == 0x30, f[4].tag == 0x30, f[5].tag == 0x30 else { return nil }

        let times = f[3].children
        let whole = Array(cert.whole)
        return X509Summary(
            subject: name(f[4]),
            issuer: name(f[2]),
            notBefore: times.first.flatMap(time),
            notAfter: times.dropFirst().first.flatMap(time),
            serialHex: serial(f[0]),
            signatureAlgorithm: f[1].children.first?.oid.map(signatureName) ?? "unbekannt",
            publicKey: publicKey(f[5]),
            sha1: hex(Array(Insecure.SHA1.hash(data: whole)), separator: ":"),
            sha256: hex(Array(SHA256.hash(data: whole)), separator: ":")
        )
    }

    // MARK: - Namen

    private static let attributeNames: [String: String] = [
        "2.5.4.3": "CN", "2.5.4.6": "C", "2.5.4.7": "L", "2.5.4.8": "ST",
        "2.5.4.10": "O", "2.5.4.11": "OU", "2.5.4.5": "SERIALNUMBER",
        "2.5.4.9": "STREET", "2.5.4.12": "T", "2.5.4.4": "SN", "2.5.4.42": "GN",
        "1.2.840.113549.1.9.1": "EMAILADDRESS", "0.9.2342.19200300.100.1.25": "DC",
        "0.9.2342.19200300.100.1.1": "UID"
    ]

    /// Gespeichert ist die Reihenfolge Land → Name; angezeigt wird wie bei
    /// keytool und RFC 2253 umgekehrt ("CN=…, O=…, C=…").
    static func name(_ node: DERNode) -> String {
        var parts: [String] = []
        for set in node.children where set.tag == 0x31 {
            for pair in set.children where pair.tag == 0x30 {
                let kv = pair.children
                guard kv.count >= 2, let oid = kv[0].oid else { continue }
                let value = kv[1].string ?? hex(Array(kv[1].content), separator: "")
                parts.append("\(attributeNames[oid] ?? oid)=\(value)")
            }
        }
        return parts.reversed().joined(separator: ", ")
    }

    // MARK: - Zeit

    /// UTCTime (YYMMDDHHMMSSZ) und GeneralizedTime (YYYYMMDDHHMMSSZ).
    static func time(_ node: DERNode) -> Date? {
        guard node.tag == 0x17 || node.tag == 0x18,
              let text = String(data: Data(node.content), encoding: .ascii) else { return nil }
        let digits = text.prefix { $0.isNumber }.compactMap { $0.wholeNumberValue }
        let yearDigits = node.tag == 0x17 ? 2 : 4
        guard digits.count >= yearDigits + 8 else { return nil }
        func number(_ from: Int, _ length: Int) -> Int {
            digits[from..<(from + length)].reduce(0) { $0 * 10 + $1 }
        }
        var year = number(0, yearDigits)
        // RFC 5280: zweistellige Jahre ab 50 liegen im 20. Jahrhundert.
        if node.tag == 0x17 { year += year >= 50 ? 1900 : 2000 }
        var c = DateComponents()
        c.year = year
        c.month = number(yearDigits, 2)
        c.day = number(yearDigits + 2, 2)
        c.hour = number(yearDigits + 4, 2)
        c.minute = number(yearDigits + 6, 2)
        c.second = digits.count >= yearDigits + 10 ? number(yearDigits + 8, 2) : 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: c)
    }

    // MARK: - Algorithmen

    private static let signatureNames: [String: String] = [
        "1.2.840.113549.1.1.4": "MD5withRSA",
        "1.2.840.113549.1.1.5": "SHA1withRSA",
        "1.2.840.113549.1.1.11": "SHA256withRSA",
        "1.2.840.113549.1.1.12": "SHA384withRSA",
        "1.2.840.113549.1.1.13": "SHA512withRSA",
        "1.2.840.113549.1.1.10": "RSASSA-PSS",
        "1.2.840.10045.4.1": "SHA1withECDSA",
        "1.2.840.10045.4.3.2": "SHA256withECDSA",
        "1.2.840.10045.4.3.3": "SHA384withECDSA",
        "1.2.840.10045.4.3.4": "SHA512withECDSA",
        "1.2.840.10040.4.3": "SHA1withDSA",
        "2.16.840.1.101.3.4.3.2": "SHA256withDSA",
        "1.3.101.112": "Ed25519",
        "1.3.101.113": "Ed448"
    ]

    static func signatureName(_ oid: String) -> String { signatureNames[oid] ?? oid }

    private static let curveNames: [String: String] = [
        "1.2.840.10045.3.1.7": "P-256", "1.3.132.0.34": "P-384", "1.3.132.0.35": "P-521",
        "1.3.132.0.10": "secp256k1"
    ]

    /// "RSA 2048 Bit", "EC P-256" -- die Schluessellaenge steht im oeffentlichen Teil.
    static func publicKey(_ spki: DERNode) -> String {
        let parts = spki.children
        guard parts.count >= 2, parts[0].tag == 0x30 else { return "unbekannt" }
        let algorithm = parts[0].children
        guard let oid = algorithm.first?.oid else { return "unbekannt" }
        switch oid {
        case "1.2.840.113549.1.1.1":
            // BIT STRING: ein Byte "unbenutzte Bits", dann SEQUENCE { Modulus, Exponent }.
            guard parts[1].tag == 0x03, let key = DERReader.first(in: parts[1].content.dropFirst()),
                  let modulus = key.children.first, modulus.tag == 0x02 else { return "RSA" }
            let bytes = modulus.content.drop { $0 == 0 }
            guard let top = bytes.first else { return "RSA" }
            let bits = (bytes.count - 1) * 8 + (8 - top.leadingZeroBitCount)
            return "RSA \(bits) Bit"
        case "1.2.840.10045.2.1":
            let curve = algorithm.dropFirst().first?.oid
            return "EC \(curve.map { curveNames[$0] ?? $0 } ?? "")".trimmingCharacters(in: .whitespaces)
        case "1.2.840.10040.4.1": return "DSA"
        case "1.3.101.112": return "Ed25519"
        case "1.3.101.113": return "Ed448"
        default: return oid
        }
    }

    /// Ein fuehrendes Null-Byte ist nur das Vorzeichen der DER-Ganzzahl -- keytool
    /// und Browser zeigen es nicht.
    static func serial(_ node: DERNode) -> String {
        var bytes = Array(node.content)
        while bytes.count > 1, bytes[0] == 0 { bytes.removeFirst() }
        return hex(bytes, separator: ":")
    }

    static func hex(_ bytes: [UInt8], separator: String) -> String {
        bytes.map { String(format: "%02X", $0) }.joined(separator: separator)
    }
}
