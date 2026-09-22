import Foundation

print("Starting Loupe Test Suite...")
let start = CFAbsoluteTimeGetCurrent()

JSONValueTests.run()
JSONLexerTests.run()
JSONParserTests.run()
SourceExcerptTests.run()
HTMLEscapeTests.run()
SettingsTests.run()
CSSGeneratorTests.run()
JSONTreeRendererTests.run()
ExpansionPolicyTests.run()
HTMLSanitizerTests.run()
ResourceResolverTests.run()
LanguageLexerTests.run()
SyntaxHighlighterTests.run()
MarkdownRendererTests.run()
CSVParserTests.run()
CSVTableRendererTests.run()
RegistryTests.run()
ExtensionStatusTests.run()
PerformanceTests.run()

let totalTime = (CFAbsoluteTimeGetCurrent() - start) * 1000
print(String(format: "Total Test Suite Time: %.2f ms", totalTime))

let success = TestRunner.shared.report()
exit(success ? 0 : 1)
