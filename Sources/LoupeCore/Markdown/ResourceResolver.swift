import Foundation
import UniformTypeIdentifiers

public struct ResolvedImageResult: Sendable {
    public let src: String
    public let altText: String
    public let isBlockedRemote: Bool
    public let isError: Bool
    public let errorMessage: String?
    
    public init(src: String, altText: String, isBlockedRemote: Bool = false, isError: Bool = false, errorMessage: String? = nil) {
        self.src = src
        self.altText = altText
        self.isBlockedRemote = isBlockedRemote
        self.isError = isError
        self.errorMessage = errorMessage
    }
}

public enum ResourceResolver {
    private static let maxImageSizeBytes: Int = 10 * 1024 * 1024 // 10 MB
    
    public static func mimeType(for fileExtension: String) -> String {
        if let utType = UTType(filenameExtension: fileExtension.lowercased()),
           let mime = utType.preferredMIMEType {
            return mime
        }
        
        switch fileExtension.lowercased() {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "webp": return "image/webp"
        case "heic": return "image/heic"
        case "avif": return "image/avif"
        case "ico": return "image/x-icon"
        case "bmp": return "image/bmp"
        case "tiff", "tif": return "image/tiff"
        default: return "application/octet-stream"
        }
    }
    
    public static func resolveImage(
        source: String,
        alt: String,
        documentURL: URL?,
        allowRemoteImages: Bool
    ) -> ResolvedImageResult {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Data URLs (already embedded)
        if trimmed.hasPrefix("data:image/") {
            return ResolvedImageResult(src: trimmed, altText: alt)
        }
        
        // 2. Remote URLs (http / https)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            if !allowRemoteImages {
                return ResolvedImageResult(
                    src: "",
                    altText: alt.isEmpty ? "Remote image blocked for privacy" : alt,
                    isBlockedRemote: true
                )
            }
            return ResolvedImageResult(src: HTMLSanitizer.sanitizeURL(trimmed), altText: alt)
        }
        
        // 3. Local relative path
        guard let docURL = documentURL else {
            // No base document URL available
            return ResolvedImageResult(src: HTMLSanitizer.sanitizeURL(trimmed), altText: alt)
        }
        
        let docDir = docURL.deletingLastPathComponent()
        let resolvedLocalURL: URL
        if trimmed.hasPrefix("/") {
            // Absolute path on disk: check if valid file
            resolvedLocalURL = URL(fileURLWithPath: trimmed)
        } else {
            // Relative path: append to document directory
            resolvedLocalURL = docDir.appendingPathComponent(trimmed)
        }
        
        // Path Traversal Security:
        // Canonicalize both base directory and destination URL to prevent symlink and ../ escapes
        let canonicalBase = docDir.resolvingSymlinksInPath().path
        let canonicalTarget = resolvedLocalURL.resolvingSymlinksInPath().path
        
        // Ensure canonical target resides within or equal to canonicalBase
        let isWithinBase = canonicalTarget.hasPrefix(canonicalBase)
        if !isWithinBase && !trimmed.hasPrefix("/") {
            return ResolvedImageResult(
                src: "",
                altText: alt,
                isError: true,
                errorMessage: "Image path outside document directory blocked"
            )
        }
        
        // Check file existence
        guard FileManager.default.fileExists(atPath: canonicalTarget) else {
            return ResolvedImageResult(
                src: "",
                altText: alt,
                isError: true,
                errorMessage: "Image not found: \(trimmed)"
            )
        }
        
        // Check file size to avoid loading multi-gigabyte files into memory
        if let attrs = try? FileManager.default.attributesOfItem(atPath: canonicalTarget),
           let fileSize = attrs[.size] as? Int, fileSize > maxImageSizeBytes {
            return ResolvedImageResult(
                src: "",
                altText: alt,
                isError: true,
                errorMessage: "Image exceeds 10MB limit"
            )
        }
        
        // Read file data and convert to Base64 Data URL
        if let data = try? Data(contentsOf: URL(fileURLWithPath: canonicalTarget)) {
            let mime = mimeType(for: (canonicalTarget as NSString).pathExtension)
            let base64 = data.base64EncodedString()
            let dataURI = "data:\(mime);base64,\(base64)"
            return ResolvedImageResult(src: dataURI, altText: alt)
        }
        
        return ResolvedImageResult(src: HTMLSanitizer.sanitizeURL(trimmed), altText: alt)
    }
}
