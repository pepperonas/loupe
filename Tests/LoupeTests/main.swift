import Foundation

print("Starting Loupe Test Suite...")
let start = CFAbsoluteTimeGetCurrent()

JSONValueTests.run()
JSONLexerTests.run()
JSONParserTests.run()

let totalTime = (CFAbsoluteTimeGetCurrent() - start) * 1000
print(String(format: "Total Test Suite Time: %.2f ms", totalTime))

let success = TestRunner.shared.report()
exit(success ? 0 : 1)
