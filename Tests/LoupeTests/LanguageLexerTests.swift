import Foundation
import LoupeCore

@MainActor
public enum LanguageLexerTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("LanguageLexer & SupportedLanguages") {
            runner.runTest(name: "testLanguageFromIdentifierAliases") {
                // Swift
                try assertEqual(SupportedLanguage.from(identifier: "swift"), .swift)
                try assertEqual(SupportedLanguage.from(identifier: "SWIFT"), .swift)
                
                // Rust
                try assertEqual(SupportedLanguage.from(identifier: "rust"), .rust)
                try assertEqual(SupportedLanguage.from(identifier: "rs"), .rust)
                
                // Python
                try assertEqual(SupportedLanguage.from(identifier: "python"), .python)
                try assertEqual(SupportedLanguage.from(identifier: "py"), .python)
                
                // JavaScript & TypeScript
                try assertEqual(SupportedLanguage.from(identifier: "javascript"), .javascript)
                try assertEqual(SupportedLanguage.from(identifier: "js"), .javascript)
                try assertEqual(SupportedLanguage.from(identifier: "mjs"), .javascript)
                try assertEqual(SupportedLanguage.from(identifier: "cjs"), .javascript)
                try assertEqual(SupportedLanguage.from(identifier: "typescript"), .typescript)
                try assertEqual(SupportedLanguage.from(identifier: "ts"), .typescript)
                try assertEqual(SupportedLanguage.from(identifier: "tsx"), .typescript)
                try assertEqual(SupportedLanguage.from(identifier: "jsx"), .typescript)
                
                // JSON & YAML
                try assertEqual(SupportedLanguage.from(identifier: "json"), .json)
                try assertEqual(SupportedLanguage.from(identifier: "jsonc"), .json)
                try assertEqual(SupportedLanguage.from(identifier: "yaml"), .yaml)
                try assertEqual(SupportedLanguage.from(identifier: "yml"), .yaml)
                
                // HTML & XML
                try assertEqual(SupportedLanguage.from(identifier: "html"), .html)
                try assertEqual(SupportedLanguage.from(identifier: "xhtml"), .html)
                try assertEqual(SupportedLanguage.from(identifier: "xml"), .xml)
                try assertEqual(SupportedLanguage.from(identifier: "plist"), .xml)
                try assertEqual(SupportedLanguage.from(identifier: "svg"), .xml)
                
                // CSS
                try assertEqual(SupportedLanguage.from(identifier: "css"), .css)
                try assertEqual(SupportedLanguage.from(identifier: "scss"), .css)
                try assertEqual(SupportedLanguage.from(identifier: "sass"), .css)
                try assertEqual(SupportedLanguage.from(identifier: "less"), .css)
                
                // SQL & Shell
                try assertEqual(SupportedLanguage.from(identifier: "sql"), .sql)
                try assertEqual(SupportedLanguage.from(identifier: "bash"), .bash)
                try assertEqual(SupportedLanguage.from(identifier: "sh"), .bash)
                try assertEqual(SupportedLanguage.from(identifier: "zsh"), .bash)
                try assertEqual(SupportedLanguage.from(identifier: "shell"), .bash)
                
                // Java & Kotlin
                try assertEqual(SupportedLanguage.from(identifier: "java"), .java)
                try assertEqual(SupportedLanguage.from(identifier: "kotlin"), .kotlin)
                try assertEqual(SupportedLanguage.from(identifier: "kt"), .kotlin)
                try assertEqual(SupportedLanguage.from(identifier: "kts"), .kotlin)
                
                // C & C++ & Go
                try assertEqual(SupportedLanguage.from(identifier: "c"), .c)
                try assertEqual(SupportedLanguage.from(identifier: "cpp"), .cpp)
                try assertEqual(SupportedLanguage.from(identifier: "c++"), .cpp)
                try assertEqual(SupportedLanguage.from(identifier: "cc"), .cpp)
                try assertEqual(SupportedLanguage.from(identifier: "cxx"), .cpp)
                try assertEqual(SupportedLanguage.from(identifier: "hpp"), .cpp)
                try assertEqual(SupportedLanguage.from(identifier: "go"), .go)
                try assertEqual(SupportedLanguage.from(identifier: "golang"), .go)
                
                // Markdown
                try assertEqual(SupportedLanguage.from(identifier: "markdown"), .markdown)
                try assertEqual(SupportedLanguage.from(identifier: "md"), .markdown)
                try assertEqual(SupportedLanguage.from(identifier: "mdown"), .markdown)
            }
            
            runner.runTest(name: "testLanguageDisplayNames") {
                try assertEqual(SupportedLanguage.swift.displayName, "Swift")
                try assertEqual(SupportedLanguage.rust.displayName, "Rust")
                try assertEqual(SupportedLanguage.python.displayName, "Python")
                try assertEqual(SupportedLanguage.javascript.displayName, "JavaScript")
                try assertEqual(SupportedLanguage.typescript.displayName, "TypeScript")
                try assertEqual(SupportedLanguage.json.displayName, "JSON")
                try assertEqual(SupportedLanguage.yaml.displayName, "YAML")
                try assertEqual(SupportedLanguage.html.displayName, "HTML")
                try assertEqual(SupportedLanguage.xml.displayName, "XML")
                try assertEqual(SupportedLanguage.css.displayName, "CSS")
                try assertEqual(SupportedLanguage.sql.displayName, "SQL")
                try assertEqual(SupportedLanguage.bash.displayName, "Shell")
                try assertEqual(SupportedLanguage.java.displayName, "Java")
                try assertEqual(SupportedLanguage.kotlin.displayName, "Kotlin")
                try assertEqual(SupportedLanguage.markdown.displayName, "Markdown")
                try assertEqual(SupportedLanguage.c.displayName, "C")
                try assertEqual(SupportedLanguage.cpp.displayName, "C++")
                try assertEqual(SupportedLanguage.go.displayName, "Go")
                try assertEqual(SupportedLanguage.unknown.displayName, "")
            }
            
            runner.runTest(name: "testUnknownLanguageHandling") {
                try assertEqual(SupportedLanguage.from(identifier: nil), .unknown)
                try assertEqual(SupportedLanguage.from(identifier: ""), .unknown)
                try assertEqual(SupportedLanguage.from(identifier: "   "), .unknown)
                try assertEqual(SupportedLanguage.from(identifier: "unknown-lang-xyz"), .unknown)
            }
            
            runner.runTest(name: "testTokenStructInitialization") {
                let kwToken = HighlightToken(type: .keyword, text: "func")
                try assertEqual(kwToken.type, .keyword)
                try assertEqual(kwToken.text, "func")
                
                let strToken = HighlightToken(type: .string, text: "\"hello\"")
                try assertEqual(strToken.type, .string)
                try assertEqual(strToken.text, "\"hello\"")
                
                let numToken = HighlightToken(type: .number, text: "123")
                try assertEqual(numToken.type, .number)
                
                let opToken = HighlightToken(type: .operatorChar, text: "==")
                try assertEqual(opToken.type, .operatorChar)
            }
        }
    }
}
