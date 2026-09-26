import Foundation

/// Links im Bereich „Über Loupe“ der Begleit-App. Jeder ist per Test auf sein
/// echtes Ziel festgenagelt -- die App darf nie eine erfundene Adresse zeigen.
public enum AboutLinks {
    public static let author = "Martin Pfeffer"
    public static let websiteURL = URL(string: "https://celox.io")!
    public static let productURL = URL(string: "https://loupe.celox.io")!
    public static let repoURL = URL(string: "https://github.com/pepperonas/loupe")!
    public static let licenseURL = URL(string: "https://github.com/pepperonas/loupe/blob/main/LICENSE")!

    /// PayPal-Spende an den Autor, EUR, die App als Verwendungszweck.
    /// Leerzeichen als %20 -- ein '+' zeigt PayPal woertlich an.
    public static func donateURL(item: String = "Loupe") -> URL {
        var c = URLComponents(string: "https://www.paypal.com/donate/")!
        c.percentEncodedQueryItems = [
            URLQueryItem(name: "business", value: "martin.pfeffer@celox.io"),
            URLQueryItem(name: "currency_code", value: "EUR"),
            URLQueryItem(name: "item_name",
                         value: item.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? item)
        ]
        return c.url!
    }

    /// Version aus dem Info.plist der App ("0.5.1").
    public static func version(bundle: Bundle = .main) -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}
