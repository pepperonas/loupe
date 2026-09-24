import Foundation
import LoupeCore

/// PowerShell (.ps1/.psm1/.psd1) und Windows-Batch (.bat/.cmd).
@MainActor
public enum ScriptLanguageTests {
    private static func ps(_ code: String) -> String {
        SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "ps1")
    }
    private static func bat(_ code: String) -> String {
        SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "bat")
    }

    public static func run() {
        let runner = TestRunner.shared

        runner.suite("PowerShell") {
            runner.runTest(name: "testExtensionsMapToPowerShell") {
                for ext in ["ps1", "psm1", "psd1", "PS1", "powershell", "pwsh"] {
                    try assertEqual(SupportedLanguage.from(identifier: ext), .powershell, ext)
                }
                try assertEqual(SupportedLanguage.powershell.displayName, "PowerShell")
            }

            runner.runTest(name: "testCommentsLineAndBlock") {
                let html = ps("# setup\n<# multi\nline #>\nWrite-Host 1")
                try assertTrue(html.contains(#"<span class="hl-com"># setup</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-com">&lt;# multi</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-com">line #&gt;</span>"#), html)
            }

            runner.runTest(name: "testVariablesIncludingScopesAndBraces") {
                let html = ps(#"$name = $env:PATH + $_ + ${my var} + $script:count"#)
                for v in ["$name", "$env:PATH", "$_", "${my var}", "$script:count"] {
                    try assertTrue(html.contains("<span class=\"hl-prop\">\(v)</span>"), "\(v) in \(html)")
                }
            }

            runner.runTest(name: "testBooleanAndNullAreKeywords") {
                let html = ps("if ($ok -eq $true) { $x = $null }")
                try assertTrue(html.contains(#"<span class="hl-kw">$true</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-kw">$null</span>"#))
            }

            runner.runTest(name: "testCmdletsParametersAndOperators") {
                let html = ps("Get-ChildItem -Path C:\\Temp -Recurse | Where-Object { $_.Length -gt 1MB }")
                try assertTrue(html.contains(#"<span class="hl-fn">Get-ChildItem</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-fn">Where-Object</span>"#))
                try assertTrue(html.contains(#"<span class="hl-attr">-Path</span>"#))
                try assertTrue(html.contains(#"<span class="hl-attr">-Recurse</span>"#))
                try assertTrue(html.contains(#"<span class="hl-kw">-gt</span>"#), "Vergleichsoperatoren sind Schluesselwoerter")
                try assertTrue(html.contains(#"<span class="hl-num">1MB</span>"#), "Groessen-Suffix gehoert zur Zahl")
            }

            runner.runTest(name: "testKeywordsAreCaseInsensitive") {
                let html = ps("Function Test { Param($a) ForEach ($i in $a) { If ($i) { Return } } }")
                for kw in ["Function", "Param", "ForEach", "in", "If", "Return"] {
                    try assertTrue(html.contains("<span class=\"hl-kw\">\(kw)</span>"), kw)
                }
            }

            runner.runTest(name: "testTypeLiterals") {
                let html = ps("[string]$s = [System.IO.File]::Exists($p)")
                try assertTrue(html.contains(#"<span class="hl-type">string</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-type">System.IO.File</span>"#))
            }

            runner.runTest(name: "testDoubleQuotedStringsInterpolateSingleQuotedDoNot") {
                let dq = ps(#""Hello $name!""#)
                try assertTrue(dq.contains(#"<span class="hl-prop">$name</span>"#), dq)
                try assertTrue(dq.contains(#"<span class="hl-str">&quot;Hello </span>"#), dq)
                let sq = ps("'Hello $name'")
                try assertFalse(sq.contains("hl-prop"), sq)
                try assertTrue(sq.contains(#"<span class="hl-str">&#39;Hello $name&#39;</span>"#), sq)
            }

            runner.runTest(name: "testSubexpressionInsideStringIsHighlighted") {
                let html = ps(#""$($f.FullName).zip""#)
                try assertTrue(html.contains(#"<span class="hl-prop">$($f.FullName)</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-str">.zip&quot;</span>"#), html)
            }

            runner.runTest(name: "testBacktickEscapesDoNotEndTheString") {
                let html = ps("\"a `\" b\" + 1")
                try assertTrue(html.contains(#"<span class="hl-num">1</span>"#), "String endet am richtigen Anfuehrungszeichen: \(html)")
            }

            runner.runTest(name: "testHereStringSpansLines") {
                let html = ps("$t = @\"\nline one\nline $two\n\"@\nWrite-Host $t")
                try assertTrue(html.contains(#"<span class="hl-str">line one</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-prop">$two</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-fn">Write-Host</span>"#), "nach dem Here-String geht es normal weiter")
            }

            runner.runTest(name: "testRealisticScriptRoundTrips") {
                let script = """
                #Requires -Version 7
                param([Parameter(Mandatory)][string]$Target, [int]$Retries = 3)
                $ErrorActionPreference = 'Stop'
                foreach ($f in Get-ChildItem -Path $Target -Filter *.log) {
                    if ($f.Length -gt 10MB) { Compress-Archive -Path $f.FullName -DestinationPath "$($f.FullName).zip" }
                }
                """
                try assertEqual(visibleText(ps(script)), script)
            }
        }

        runner.suite("Batch") {
            runner.runTest(name: "testExtensionsMapToBatch") {
                for ext in ["bat", "cmd", "BAT", "batch"] {
                    try assertEqual(SupportedLanguage.from(identifier: ext), .batch, ext)
                }
                try assertEqual(SupportedLanguage.batch.displayName, "Batch")
            }

            runner.runTest(name: "testRemAndDoubleColonComments") {
                let html = bat("REM build it\nrem lower\n:: also a comment\necho done")
                try assertTrue(html.contains(#"<span class="hl-com">REM build it</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-com">rem lower</span>"#))
                try assertTrue(html.contains(#"<span class="hl-com">:: also a comment</span>"#))
                // Nur REM als eigenes Wort: eine Zeile, die mit "remote…" beginnt, ist keiner.
                try assertFalse(bat("remotectl list").contains("hl-com"))
                try assertFalse(bat("REMOTE_HOST=x").contains("hl-com"))
                try assertTrue(bat("rem.").contains("hl-com"), "REM. ist ein gueltiger Kommentar")
            }

            runner.runTest(name: "testLabelsAndGoto") {
                let html = bat(":start\ngoto :eof\ncall :sub arg")
                try assertTrue(html.contains(#"<span class="hl-fn">:start</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-kw">goto</span>"#))
                try assertTrue(html.contains(#"<span class="hl-fn">:eof</span>"#))
                try assertTrue(html.contains(#"<span class="hl-fn">:sub</span>"#))
            }

            runner.runTest(name: "testVariablesAllForms") {
                let html = bat("echo %PATH% %~dp0 %1 %%i !count! %DATE:~0,4%")
                for v in ["%PATH%", "%~dp0", "%1", "%%i", "!count!", "%DATE:~0,4%"] {
                    try assertTrue(html.contains("<span class=\"hl-prop\">\(v)</span>"), "\(v) in \(html)")
                }
            }

            runner.runTest(name: "testKeywordsCaseInsensitiveAndEchoOff") {
                let html = bat("@ECHO OFF\nIF NOT EXIST out (MKDIR out) ELSE (Echo ok)\nif %ERRORLEVEL% EQU 0 exit /b 0")
                for kw in ["ECHO", "IF", "NOT", "EXIST", "ELSE", "Echo", "if", "EQU", "exit"] {
                    try assertTrue(html.contains("<span class=\"hl-kw\">\(kw)</span>"), kw)
                }
                try assertTrue(html.contains(#"<span class="hl-attr">/b</span>"#), "Schalter wie /b")
            }

            runner.runTest(name: "testQuotedStringsWithVariables") {
                let html = bat(#"set "OUT=%TEMP%\build""#)
                try assertTrue(html.contains(#"<span class="hl-kw">set</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-prop">%TEMP%</span>"#), html)
                try assertTrue(html.contains("hl-str"), html)
            }

            runner.runTest(name: "testLonePercentIsNotAVariable") {
                // Zwei "%" mit Leerzeichen dazwischen sind KEINE Variable "% and 50%".
                let html = bat("echo 100% and 50% done")
                try assertFalse(html.contains("hl-prop"), html)
                try assertEqual(visibleText(html), "echo 100% and 50% done")
            }

            runner.runTest(name: "testRealisticScriptRoundTrips") {
                let script = """
                @echo off
                setlocal EnableDelayedExpansion
                REM Build all projects
                set "ROOT=%~dp0"
                for /r "%ROOT%src" %%f in (*.csproj) do (
                    dotnet build "%%f" -c Release || goto :fail
                    set /a count+=1
                )
                echo Built !count! projects.
                exit /b 0
                :fail
                echo Build failed with %ERRORLEVEL% 1>&2
                exit /b 1
                """
                try assertEqual(visibleText(bat(script)), script)
            }
        }

        runner.suite("Script previews & registration") {
            runner.runTest(name: "testScriptFilesUseTheSourceCodeRenderer") {
                let cases = [("deploy.ps1", "PowerShell"), ("Tools.psm1", "PowerShell"), ("Manifest.psd1", "PowerShell"),
                             ("build.bat", "Batch"), ("run.CMD", "Batch")]
                for (name, badge) in cases {
                    let url = URL(fileURLWithPath: "/tmp/\(name)")
                    try assertTrue(RendererRegistry.renderer(for: url) is SourceCodePreviewRenderer, name)
                    let html = SourceCodePreviewRenderer().renderHTML(
                        input: PreviewInput(data: Data("echo hi".utf8), url: url, wasTruncatedByReader: false),
                        settings: LoupeSettings())
                    try assertTrue(html.contains("<span class=\"lp-badge\">\(badge)</span>"), "\(name) -> \(badge)")
                }
            }

            runner.runTest(name: "testTypesAreDeclaredAndReachQuickLook") {
                // macOS vergibt fuer .ps1/.bat nur DYNAMISCHE Typen -- ohne eigene
                // Deklaration ruft Quick Look die Erweiterung dafuer nie auf.
                let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
                    .deletingLastPathComponent().deletingLastPathComponent()
                let app = try plist(root.appendingPathComponent("Sources/Loupe/Resources/Info.plist"))
                let ext = try plist(root.appendingPathComponent("Sources/LoupePreview/Resources/Info.plist"))

                let imported = (app["UTImportedTypeDeclarations"] as? [[String: Any]]) ?? []
                func declared(_ uti: String) -> [String] {
                    let d = imported.first { $0["UTTypeIdentifier"] as? String == uti }
                    let tags = d?["UTTypeTagSpecification"] as? [String: Any]
                    return (tags?["public.filename-extension"] as? [String]) ?? []
                }
                try assertEqual(Set(declared("com.microsoft.powershell-script")), ["ps1", "psm1", "psd1"])
                try assertEqual(Set(declared("com.microsoft.batch-file")), ["bat", "cmd"])

                let attrs = ((ext["NSExtension"] as? [String: Any])?["NSExtensionAttributes"] as? [String: Any]) ?? [:]
                let supported = (attrs["QLSupportedContentTypes"] as? [String]) ?? []
                try assertTrue(supported.contains("com.microsoft.powershell-script"))
                try assertTrue(supported.contains("com.microsoft.batch-file"))
            }
        }
    }

    private static func plist(_ url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        return (try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]) ?? [:]
    }
}
