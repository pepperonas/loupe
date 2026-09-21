import Foundation

/// Bewusste Kopie aus MarkLooks HTMLSanitizer.
///
/// ⚠ Diese 15 Zeilen liegen in zwei Repos. Eine Korrektur hier erreicht
/// MarkLook NICHT von selbst (siehe Spec §9).
public enum HTMLEscape {
    public static func escape(_ text: String) -> String {
        var result = String()
        result.reserveCapacity(text.count + 20)
        for char in text {
            switch char {
            case "&":  result.append("&amp;")
            case "<":  result.append("&lt;")
            case ">":  result.append("&gt;")
            case "\"": result.append("&quot;")
            case "'":  result.append("&#39;")
            default:   result.append(char)
            }
        }
        return result
    }
}
