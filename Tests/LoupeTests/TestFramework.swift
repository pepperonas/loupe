import Foundation

@MainActor
public final class TestRunner {
    public static let shared = TestRunner()
    
    public private(set) var totalTests = 0
    public private(set) var passedTests = 0
    public private(set) var failedTests = 0
    private var failures: [String] = []
    
    public func runTest(name: String, block: () throws -> Void) {
        totalTests += 1
        let start = CFAbsoluteTimeGetCurrent()
        do {
            try block()
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            passedTests += 1
            let formattedTime = String(format: "%.2fms", elapsed)
            print("  \u{001B}[32m✓\u{001B}[0m \(name) (\(formattedTime))")
        } catch {
            failedTests += 1
            let failureMsg = "  \u{001B}[31m✗\u{001B}[0m \(name) FAILED: \(error)"
            print(failureMsg)
            failures.append("\(name): \(error)")
        }
    }
    
    public func suite(_ name: String, block: () -> Void) {
        print("\n\u{001B}[1m--- Suite: \(name) ---\u{001B}[0m")
        block()
    }
    
    public func report() -> Bool {
        print("\n" + String(repeating: "=", count: 50))
        if failedTests == 0 {
            print("\u{001B}[32m\u{001B}[1mTEST RESULT: SUCCESS\u{001B}[0m")
            print("All \(passedTests) unit tests passed successfully!")
            print(String(repeating: "=", count: 50) + "\n")
            return true
        } else {
            print("\u{001B}[31m\u{001B}[1mTEST RESULT: FAILED\u{001B}[0m")
            print("\(failedTests) of \(totalTests) tests failed.")
            for fail in failures {
                print(" - \(fail)")
            }
            print(String(repeating: "=", count: 50) + "\n")
            return false
        }
    }
}

public struct TestFailure: Error, CustomStringConvertible, Sendable {
    public let message: String
    public let file: StaticString
    public let line: UInt
    
    public var description: String {
        "\(message) at \(file):\(line)"
    }
}

public func assertEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String = "", file: StaticString = #file, line: UInt = #line) throws {
    if a != b {
        throw TestFailure(message: "Expected '\(b)', but got '\(a)'. \(msg)", file: file, line: line)
    }
}

public func assertTrue(_ condition: Bool, _ msg: String = "", file: StaticString = #file, line: UInt = #line) throws {
    if !condition {
        throw TestFailure(message: "Expected true, but got false. \(msg)", file: file, line: line)
    }
}

public func assertFalse(_ condition: Bool, _ msg: String = "", file: StaticString = #file, line: UInt = #line) throws {
    if condition {
        throw TestFailure(message: "Expected false, but got true. \(msg)", file: file, line: line)
    }
}

public func assertLessThan<T: Comparable>(_ a: T, _ b: T, _ msg: String = "", file: StaticString = #file, line: UInt = #line) throws {
    if a >= b {
        throw TestFailure(message: "Expected \(a) < \(b). \(msg)", file: file, line: line)
    }
}
