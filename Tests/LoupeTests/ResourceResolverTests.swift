import Foundation
import LoupeCore

@MainActor
public enum ResourceResolverTests {
    public static func run() {
        let runner = TestRunner.shared
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        
        runner.suite("ResourceResolver") {
            runner.runTest(name: "testResolveDataURI") {
                let dataURI = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
                let result = ResourceResolver.resolveImage(source: dataURI, alt: "Dot", documentURL: nil, allowRemoteImages: false)
                try assertEqual(result.src, dataURI)
                try assertFalse(result.isBlockedRemote)
                try assertFalse(result.isError)
            }
            
            runner.runTest(name: "testResolveRemoteImageBlockedWhenDisallowed") {
                let remoteURL = "https://example.com/tracking.png"
                let result = ResourceResolver.resolveImage(source: remoteURL, alt: "Tracking", documentURL: nil, allowRemoteImages: false)
                try assertTrue(result.isBlockedRemote)
                try assertTrue(result.src.isEmpty)
                
                // Fallback alt text when alt is empty
                let emptyAltResult = ResourceResolver.resolveImage(source: remoteURL, alt: "", documentURL: nil, allowRemoteImages: false)
                try assertTrue(emptyAltResult.isBlockedRemote)
                try assertTrue(emptyAltResult.altText.contains("Remote image blocked"))
            }
            
            runner.runTest(name: "testResolveRemoteImageAllowedWhenEnabled") {
                let remoteURL = "https://example.com/photo.jpg"
                let result = ResourceResolver.resolveImage(source: remoteURL, alt: "Photo", documentURL: nil, allowRemoteImages: true)
                try assertFalse(result.isBlockedRemote)
                try assertEqual(result.src, remoteURL)
            }
            
            runner.runTest(name: "testResolveLocalRelativeImage") {
                let imageURL = tempDirectory.appendingPathComponent("image.png")
                let dummyPNG = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
                try dummyPNG.write(to: imageURL)
                
                let docURL = tempDirectory.appendingPathComponent("document.md")
                
                let result = ResourceResolver.resolveImage(source: "./image.png", alt: "Local Image", documentURL: docURL, allowRemoteImages: false)
                try assertFalse(result.isError)
                try assertFalse(result.isBlockedRemote)
                try assertTrue(result.src.hasPrefix("data:image/png;base64,"))
            }
            
            runner.runTest(name: "testResolveAbsoluteDiskPath") {
                let imageURL = tempDirectory.appendingPathComponent("absolute.png")
                let dummyPNG = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
                try dummyPNG.write(to: imageURL)
                
                let docURL = tempDirectory.appendingPathComponent("document.md")
                let result = ResourceResolver.resolveImage(source: imageURL.path, alt: "Absolute", documentURL: docURL, allowRemoteImages: false)
                try assertFalse(result.isError)
                try assertTrue(result.src.hasPrefix("data:image/png;base64,"))
            }
            
            runner.runTest(name: "testPathTraversalBlocked") {
                let subDir = tempDirectory.appendingPathComponent("sub")
                try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
                let docURL = subDir.appendingPathComponent("test.md")
                
                let result = ResourceResolver.resolveImage(source: "../../../../../../etc/passwd", alt: "Attack", documentURL: docURL, allowRemoteImages: false)
                try assertTrue(result.isError)
                try assertEqual(result.errorMessage, "Image path outside document directory blocked")
            }
            
            runner.runTest(name: "testResolveNonExistentLocalImageReturnsError") {
                let docURL = tempDirectory.appendingPathComponent("document.md")
                let result = ResourceResolver.resolveImage(source: "non_existent_file.png", alt: "Missing", documentURL: docURL, allowRemoteImages: false)
                try assertTrue(result.isError)
                try assertTrue(result.errorMessage?.contains("Image not found") ?? false)
            }
            
            runner.runTest(name: "testResolveImageWithNilDocumentURL") {
                let result = ResourceResolver.resolveImage(source: "relative.png", alt: "Relative", documentURL: nil, allowRemoteImages: false)
                try assertFalse(result.isError)
                try assertEqual(result.src, "relative.png")
            }
            
            runner.runTest(name: "testMimeTypeDetectionComprehensive") {
                try assertEqual(ResourceResolver.mimeType(for: "png"), "image/png")
                try assertEqual(ResourceResolver.mimeType(for: "PNG"), "image/png")
                try assertEqual(ResourceResolver.mimeType(for: "jpg"), "image/jpeg")
                try assertEqual(ResourceResolver.mimeType(for: "jpeg"), "image/jpeg")
                try assertEqual(ResourceResolver.mimeType(for: "gif"), "image/gif")
                try assertEqual(ResourceResolver.mimeType(for: "svg"), "image/svg+xml")
                try assertEqual(ResourceResolver.mimeType(for: "webp"), "image/webp")
                try assertEqual(ResourceResolver.mimeType(for: "heic"), "image/heic")
                try assertEqual(ResourceResolver.mimeType(for: "avif"), "image/avif")
                let icoMime = ResourceResolver.mimeType(for: "ico")
                try assertTrue(icoMime == "image/x-icon" || icoMime == "image/vnd.microsoft.icon")
                try assertEqual(ResourceResolver.mimeType(for: "bmp"), "image/bmp")
                try assertEqual(ResourceResolver.mimeType(for: "tiff"), "image/tiff")
                try assertEqual(ResourceResolver.mimeType(for: "tif"), "image/tiff")
                try assertEqual(ResourceResolver.mimeType(for: "unknown_ext"), "application/octet-stream")
            }
        }
    }
}
