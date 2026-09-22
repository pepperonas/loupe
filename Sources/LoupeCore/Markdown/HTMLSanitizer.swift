import Foundation

public enum HTMLSanitizer {
    private static let dangerousTagNames: Set<String> = [
        "script", "style", "iframe", "object", "embed", "applet",
        "form", "textarea", "select", "button", "link", "meta", "base"
    ]
    
    // Allowed safe tags for inline and block HTML in markdown
    private static let allowedTagNames: Set<String> = [
        "p", "br", "hr", "h1", "h2", "h3", "h4", "h5", "h6",
        "strong", "b", "em", "i", "u", "s", "del", "strike", "ins",
        "code", "pre", "kbd", "samp", "var",
        "blockquote", "q", "cite",
        "ul", "ol", "li", "dl", "dt", "dd",
        "table", "thead", "tbody", "tfoot", "tr", "th", "td", "caption",
        "a", "img", "picture", "source", "figure", "figcaption",
        "div", "span", "details", "summary", "mark", "small", "sub", "sup", "abbr",
        "input" // Only for disabled checkboxes
    ]
    
    private static let dangerousProtocols: [String] = [
        "javascript:", "vbscript:", "data:text/html", "data:text/javascript", "data:application/javascript"
    ]
    
    public static func escapeHTML(_ text: String) -> String {
        var result = String()
        result.reserveCapacity(text.count + 20)
        for char in text {
            switch char {
            case "&": result.append("&amp;")
            case "<": result.append("&lt;")
            case ">": result.append("&gt;")
            case "\"": result.append("&quot;")
            case "'": result.append("&#39;")
            default: result.append(char)
            }
        }
        return result
    }
    
    public static func sanitizeURL(_ urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        
        for dangerous in dangerousProtocols {
            if lower.contains(dangerous) || lower.hasPrefix(dangerous) {
                return "#"
            }
        }
        
        // Decode HTML numeric character references (e.g. &#106; -> j, &#x6a; -> j)
        var decoded = trimmed
        if let regex = try? NSRegularExpression(pattern: "&#(?:x([0-9a-fA-F]+)|([0-9]+));", options: .caseInsensitive) {
            let nsString = decoded as NSString
            let matches = regex.matches(in: decoded, options: [], range: NSRange(location: 0, length: nsString.length)).reversed()
            for match in matches {
                var charStr: String?
                if match.range(at: 1).location != NSNotFound {
                    let hex = nsString.substring(with: match.range(at: 1))
                    if let code = UInt32(hex, radix: 16), let scalar = UnicodeScalar(code) {
                        charStr = String(scalar)
                    }
                } else if match.range(at: 2).location != NSNotFound {
                    let dec = nsString.substring(with: match.range(at: 2))
                    if let code = UInt32(dec, radix: 10), let scalar = UnicodeScalar(code) {
                        charStr = String(scalar)
                    }
                }
                if let replacement = charStr {
                    decoded = (decoded as NSString).replacingCharacters(in: match.range, with: replacement)
                }
            }
        }
        let lowerDecoded = decoded.lowercased()
        for dangerous in dangerousProtocols {
            if lowerDecoded.contains(dangerous) || lowerDecoded.hasPrefix(dangerous) {
                return "#"
            }
        }
        
        return escapeHTML(trimmed)
    }
    
    public static func sanitizeRawHTML(_ html: String) -> String {
        var sanitized = html
        
        // Remove dangerous tags and their content
        for tag in dangerousTagNames {
            let pattern = "<\\s*\(tag)\\b[^>]*>([\\s\\S]*?)<\\s*/\\s*\(tag)\\s*>"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                sanitized = regex.stringByReplacingMatches(
                    in: sanitized,
                    options: [],
                    range: NSRange(location: 0, length: sanitized.utf16.count),
                    withTemplate: ""
                )
            }
            // Also remove self-closing or unclosed instances
            let singlePattern = "<\\s*\(tag)\\b[^>]*\\/?>"
            if let regex = try? NSRegularExpression(pattern: singlePattern, options: .caseInsensitive) {
                sanitized = regex.stringByReplacingMatches(
                    in: sanitized,
                    options: [],
                    range: NSRange(location: 0, length: sanitized.utf16.count),
                    withTemplate: ""
                )
            }
        }
        
        // Strip event handlers like onclick, onload, onerror, etc.
        let eventHandlerPattern = "(?i)\\s+on[a-z0-9_-]+\\s*=\\s*([\"'][^\"']*[\"']|[^\\s>]+)"
        if let regex = try? NSRegularExpression(pattern: eventHandlerPattern, options: []) {
            sanitized = regex.stringByReplacingMatches(
                in: sanitized,
                options: [],
                range: NSRange(location: 0, length: sanitized.utf16.count),
                withTemplate: ""
            )
        }
        
        // Strip javascript: in href/src attributes
        let jsHrefPattern = "(?i)(href|src)\\s*=\\s*([\"'])(?:javascript|vbscript):[\\s\\S]*?\\2"
        if let regex = try? NSRegularExpression(pattern: jsHrefPattern, options: []) {
            sanitized = regex.stringByReplacingMatches(
                in: sanitized,
                options: [],
                range: NSRange(location: 0, length: sanitized.utf16.count),
                withTemplate: "$1=\"#\""
            )
        }
        
        return sanitized
    }
}
