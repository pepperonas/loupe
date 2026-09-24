import Foundation
import LoupeCore

// Aufruf: render-previews <ausgabeordner> <datei>...
// Schreibt je Datei <name>-light.html und <name>-dark.html -- erzeugt ueber
// denselben Weg wie die Quick-Look-Erweiterung: RendererRegistry waehlt den
// Renderer, PreviewFileReader liest nach dessen Lesestrategie.

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write(Data("usage: render-previews <out-dir> <file>...\n".utf8))
    exit(2)
}
let outDir = URL(fileURLWithPath: args[1], isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for path in args.dropFirst(2) {
    let url = URL(fileURLWithPath: path)
    guard let renderer = RendererRegistry.renderer(for: url) else {
        FileHandle.standardError.write(Data("no renderer for \(path)\n".utf8))
        exit(1)
    }
    let read = try PreviewFileReader.read(url: url,
                                          strategy: type(of: renderer).readStrategy,
                                          headLimit: ParseLimits().maxBytes)
    let input = PreviewInput(data: read.data, url: url,
                             wasTruncatedByReader: read.truncatedAtEnd,
                             skippedBytesAtStart: read.skippedBytesAtStart,
                             skippedLineBreaks: read.skippedLineBreaks)
    for (suffix, appearance) in [("light", LoupeAppearance.light), ("dark", .dark)] {
        var settings = LoupeSettings()
        settings.appearance = appearance
        let html = renderer.renderHTML(input: input, settings: settings)
        let target = outDir.appendingPathComponent("\(url.lastPathComponent)-\(suffix).html")
        try html.write(to: target, atomically: true, encoding: .utf8)
    }
    print("\(url.lastPathComponent) -> \(type(of: renderer))")
}
