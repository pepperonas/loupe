# Loupe

<div align="center">

  <a href="README.md">
    <img src="https://img.shields.io/badge/Language-English-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="English">
  </a>
  &nbsp;
  <a href="README.de.md">
    <img src="https://img.shields.io/badge/Sprache-Deutsch-555555?style=for-the-badge&logo=apple&logoColor=white" alt="Deutsch">
  </a>

  <br><br>

[![Release](https://img.shields.io/badge/Release-v0.1.0-007AFF?logo=apple&logoColor=white)](https://github.com/pepperonas/loupe/releases)
[![Build](https://img.shields.io/badge/Build-Passing-brightgreen?logo=apple&logoColor=white)](https://github.com/pepperonas/loupe/actions/workflows/ci.yml)
[![Tests](https://img.shields.io/badge/Tests-98%20Unit--Tests%20passed-brightgreen?logo=apple&logoColor=white)](Tests/LoupeTests/)
[![Lines of Code](https://img.shields.io/badge/LoC-2%2C888%20Lines%20of%20Swift-blue?logo=swift&logoColor=white)](Sources/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
<br>
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-000000?logo=apple&logoColor=white)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![Sandboxed](https://img.shields.io/badge/Sandbox-App%20Sandbox%20%2B%20Read--Only-success?logo=apple&logoColor=white)](Sources/LoupePreview/Resources/LoupePreview.entitlements)
[![Zero JS](https://img.shields.io/badge/JavaScript-Zero%20Bytes-success)](https://github.com/pepperonas/loupe)
[![Offline](https://img.shields.io/badge/Works-100%25%20Offline-blue?logo=apple&logoColor=white)](https://github.com/pepperonas/loupe)
[![Zero Telemetry](https://img.shields.io/badge/Telemetry-None%20%E2%9C%93-success)](https://github.com/pepperonas/loupe)
[![SemVer](https://img.shields.io/badge/SemVer-2.0.0-3F4551)](https://semver.org)
[![Keep a Changelog](https://img.shields.io/badge/Changelog-Keep%20a%20Changelog-E05735?logo=keepachangelog&logoColor=white)](CHANGELOG.md)
<br><br>
<a href="https://www.paypal.com/donate/?business=martin.pfeffer%40celox.io&item_name=Loupe&currency_code=EUR">
  <img src="https://img.shields.io/badge/☕_Buy_the_dev_a_coffee-Donate_via_PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" height="42" alt="Donate via PayPal" />
</a>

<br><br>

```
┌────────────────────────────────────────────────────────────┐
│  Finder → Select Any JSON File (.json) → Press Space       │
│  Instant, collapsible tree preview with zero JavaScript!   │
└────────────────────────────────────────────────────────────┘
```

</div>

---

## Overview

**Loupe** is a lightweight, blazing-fast native macOS application and Quick Look Preview Extension (`io.celox.loupe.preview`) that brings interactive, collapsible developer file previews directly to the macOS Finder.

Loupe is the successor to [MarkLook](https://github.com/pepperonas/marklook). In version 0.1.0, Loupe provides first-class, hardened support for JSON files (`public.json`). Additional developer formats (including Markdown, YAML, and CSV) are scheduled for subsequent releases via an extensible renderer architecture.

Pressing **Space** on any `.json` file instantly presents a fully collapsible tree with source-order preservation, type badges, member counts, syntax color roles, and smart breadth-first expansion — **without a single byte of JavaScript**, without Electron, and without background daemons.

Designed strictly according to Apple's Human Interface Guidelines, Loupe looks, behaves, and feels like a native macOS system component.

---

## Key Features

- ⚡ **Instant Preview**: Rapid startup using Apple's modern data-based `QLPreviewProvider` and `QLPreviewReply` APIs (macOS 14.0+). Renders 50 KB JSON in under 10 ms and 5 MB JSON in ~160 ms.
- 🌳 **Zero-JavaScript Collapsible Tree**: 100% interactive tree powered purely by HTML5 `<details>` and `<summary>` elements. Absolutely no script execution, no client-side evaluation, no event listener overhead.
- 📐 **Order-Preserving & Exact AST**: Unlike `JSONSerialization` or standard dictionary decoders, Loupe preserves the exact source key order, retains duplicate keys, and keeps original number spellings (e.g. `1.000` vs `1e3`).
- 🧭 **Smart Breadth-First Expansion (BFS)**: Instead of arbitrary fixed-depth unfolding, Loupe uses a line-budget algorithm (default: 120 visible rows). A standard `package.json` opens completely, while a massive 2,000-element array stays safely collapsed at root.
- 🩹 **Resilient Error Recovery & Source Excerpts**: If a JSON file contains syntax errors, Loupe does not abort with a blank screen. It renders the valid partial tree parsed up to the error, accompanied by an error banner showing line, column, context window, and an exact caret pointer (`^`) with UTF-8 character and tab alignment.
- 🛡️ **Hardened Limits & DoS Protection**: Stack-overflow protection through a depth guard (max 64 levels), memory safety via node limits (20,000 nodes), container child limits (1,000 children), string display caps (4 KB), and file size boundaries (20 MB).
- 🎨 **Apple Typography & Contrast-Verified Themes**: Dual Light and Dark themes styled with `SF Mono` and `ui-monospace`. All semantic color roles are verified on an HTML5 canvas against WCAG AA standards (all ratios > 4.5:1, ranging from 6.4:1 to 16.8:1).
- 💻 **Native Companion App**: Built-in AppKit companion app providing live Quick Look extension registration status, troubleshooting tips, and user preferences for appearance and text size.

---

## Supported JSON Features & Capabilities

| Feature | Description | Supported | Technical Detail |
| :--- | :--- | :---: | :--- |
| **Objects (`{ ... }`)** | Nested dictionary structures | ✅ | Shows member count badge and collapsed key preview peek |
| **Arrays (`[ ... ]`)** | Sequential value lists | ✅ | Shows item count badge and element type/index preview |
| **Source Key Order** | Exact document sequence | ✅ | Preserves file order without alphabetical re-sorting |
| **Duplicate Keys** | Repeated object keys | ✅ | Preserves and displays both occurrences |
| **Numeric Precision** | Arbitrary precision numbers | ✅ | Keeps exact source representation without float rounding |
| **Strings & Escapes** | UTF-8 strings & surrogates | ✅ | Handles `\uXXXX` escapes, surrogate pairs (e.g. `😀`), and newlines |
| **Collapsible Nodes** | Native folder interaction | ✅ | HTML5 `<details>`/`<summary>` with animated indicator |
| **Smart Expansion** | Initial open/closed state | ✅ | Breadth-first queue within configurable line budget |
| **Partial Tree Recovery** | Resilient error recovery | ✅ | Shows valid nodes parsed prior to syntax failure |
| **Error Excerpt** | Visual syntax error locator | ✅ | Displays line, column, source excerpt, and caret (`^`) |
| **Unicode & Emojis** | Multilingual & multi-byte UTF-8 | ✅ | Column caret alignment accurately maps multi-byte characters |
| **Tab Alignment** | Tab expansion in excerpts | ✅ | Expands `\t` to spaces so carets stay visually aligned |
| **Truncation Banner** | Safe file limit notification | ✅ | Distinguishes between intentional limits and file errors |
| **Dark & Light Modes** | System appearance support | ✅ | Media query isolation; manual override in settings |
| **Configurable Sizes** | Small, Medium, Large typography | ✅ | Configured via Shared App Group UserDefaults |

---

## Contrast-Verified Color Roles (WCAG AA)

All color roles are measured on an HTML5 canvas composited over background layers (`Scripts/measure_contrast.html`), ensuring compliance with accessibility guidelines:

| Color Role | Light Theme (`#ffffff`) | Dark Theme (`#1e1e1e`) | WCAG Status |
| :--- | :--- | :--- | :---: |
| **Text (`--text`)** | `#1d1d1f` → **16.83:1** | `#f5f5f7` → **15.31:1** | ✅ Pass (> 4.5:1) |
| **Dimmed Text (`--text-dim`)** | `#5b5e69` → **6.46:1** | `#a1a1a6` → **6.48:1** | ✅ Pass (> 4.5:1) |
| **Object Key (`--key`)** | `#0b5fb0` → **6.41:1** | `#7ab8ff` → **8.04:1** | ✅ Pass (> 4.5:1) |
| **String Literal (`--str`)** | `#b3261e` → **6.54:1** | `#ff8170` → **6.85:1** | ✅ Pass (> 4.5:1) |
| **Number Literal (`--num`)** | `#1c00cf` → **10.77:1** | `#dabaff` → **9.88:1** | ✅ Pass (> 4.5:1) |
| **Boolean Literal (`--bool`)** | `#7a3ea3` → **6.90:1** | `#d8a0ff` → **8.25:1** | ✅ Pass (> 4.5:1) |
| **Null Literal (`--null`)** | `#5b5e69` → **6.46:1** | `#a1a1a6` → **6.48:1** | ✅ Pass (> 4.5:1) |
| **Count / Peek (`--count`)** | `#5b5e69` → **6.46:1** | `#a1a1a6` → **6.48:1** | ✅ Pass (> 4.5:1) |
| **Error Banner (`--err-fg`)** | `#a5251c` on `--err-bg` → **6.72:1** | `#ff8a80` on `--err-bg` → **6.64:1** | ✅ Pass (> 4.5:1) |
| **Notice Banner (`--note-fg`)** | `#0a5aa8` on `--note-bg` → **6.39:1** | `#7ab8ff` on `--note-bg` → **7.05:1** | ✅ Pass (> 4.5:1) |
| **Hover / Excerpt Box** | `#1d1d1f` on `#f6f8fa` → **15.81:1** | `#f5f5f7` on `#28282b` → **13.50:1** | ✅ Pass (> 4.5:1) |

*(Negative control probe: `#cccccc` on `#ffffff` produced 1.61:1, verifying that the measurement harness reliably catches under-contrast values).*

---

## Project Architecture

```text
Loupe
├── Loupe.app (Host Companion Application)
│   ├── Contents/MacOS/Loupe (AppKit host binary)
│   ├── Contents/Info.plist (Bundle metadata & registered UTTypes)
│   └── Contents/PlugIns/
│       └── LoupePreview.appex (Quick Look App Extension)
│           ├── Contents/MacOS/LoupePreview (QLPreviewProvider extension binary)
│           └── Contents/Info.plist (NSExtension & QLSupportedContentTypes)
│
├── LoupeCore (Shared Swift Package Library Target)
│   ├── JSON/
│   │   ├── JSONValue.swift (AST node types, Member, Diagnostic, ParseOutcome)
│   │   ├── JSONLexer.swift (Byte-oriented token scanner, UTF-8 surrogate decoding)
│   │   ├── JSONParser.swift (Order-preserving recursive descent parser, recovery)
│   │   └── SourceExcerpt.swift (Context window, tab expansion, UTF-8 caret alignment)
│   ├── Preview/
│   │   ├── PreviewRenderer.swift (PreviewInput, PreviewRenderer protocol)
│   │   ├── JSONPreviewRenderer.swift (End-to-end JSON preview coordinator)
│   │   ├── RendererRegistry.swift (UTType matching and renderer lookup)
│   │   └── HTMLDocument.swift (Single source of truth for CSP envelope)
│   ├── Render/
│   │   ├── JSONTreeRenderer.swift (Nested details/summary HTML emitter)
│   │   ├── ExpansionPolicy.swift (Breadth-first expansion planner within line budget)
│   │   └── HTMLEscape.swift (Single-pass character sanitization)
│   ├── Theme/
│   │   └── CSSGenerator.swift (WCAG AA light/dark stylesheets with media queries)
│   ├── Configuration/
│   │   └── LoupeSettings.swift (Appearance, font size, line budget, App Group Defaults)
│   └── Utilities/
│       └── ExtensionStatusChecker.swift (Pluginkit output parser and diagnostic checker)
│
└── LoupeTests (Automated Test Suite Target)
    ├── JSONValueTests.swift (Value model and ordering guarantees)
    ├── JSONLexerTests.swift (Tokenization, literals, surrogate pairs, positions)
    ├── JSONParserTests.swift (Recursive-descent grammar, limits, partial recovery)
    ├── SourceExcerptTests.swift (Clipping, multi-byte UTF-8, tab expansion carets)
    ├── HTMLEscapeTests.swift (XSS prevention, entity order safety)
    ├── SettingsTests.swift (Round-trip JSON encoding, App Groups)
    ├── CSSGeneratorTests.swift (Monospace rules, media query isolation, classes)
    ├── JSONTreeRendererTests.swift (Details structure, badges, banners, zero-JS)
    ├── ExpansionPolicyTests.swift (Queue ordering, budget constraints, breadth-first)
    ├── RegistryTests.swift (UTType resolution, CSP exact match, end-to-end render)
    ├── ExtensionStatusTests.swift (Pluginkit interpretation, diagnostic state)
    └── PerformanceTests.swift (50 KB in < 10 ms, 5 MB in < 170 ms benchmarks)
```

---

## Installation & Quick Look Activation

### 1. Download Pre-built Release (Recommended)

1. Download the latest `Loupe-v*.zip` from [GitHub Releases](https://github.com/pepperonas/loupe/releases).
2. Unzip and drag `Loupe.app` into your `/Applications` folder.
3. Open `Loupe.app` once to register the extension with LaunchServices and pluginkit.

### 2. Build & Install from Source

```bash
# Clone the repository
git clone https://github.com/pepperonas/loupe.git
cd loupe

# Build and install to /Applications/Loupe.app
./Scripts/install_app.sh
```

### 3. Enable in macOS System Settings

macOS requires one-time approval for third-party Quick Look extensions:

1. Open **System Settings** → **Privacy & Security** → **Extensions**.
2. Click **Quick Look**.
3. Toggle **Loupe QuickLook Preview** (or `io.celox.loupe.preview`) to **Enabled**.
4. If Finder still shows raw plain text, reload the generator cache:
   ```bash
   qlmanage -r && qlmanage -r cache && killall Finder
   ```

---

## Manual Verification in Finder

1. Open Finder and navigate to the fixtures folder inside the project:
   ```bash
   open Tests/Fixtures
   ```
2. Select any of the included verification files and press **Space**:
   - **`package.json`**: Healthy, deeply nested document. Opens cleanly within line budget; child containers can be clicked to toggle open/closed.
   - **`broken.json`**: Contains an intentional missing comma. Displays a red error banner with line 3, column 3, code excerpt, and caret (`^`), while still rendering the preceding valid key `"a": 1`.
   - **`unicode.json`**: Verifies German umlauts (`äöü`), emojis (`😀`), Japanese characters (`日本語`), and escaped backslashes (`C:\tmp`).

---

## Running the Automated Test Suite

Loupe comes with an integrated test runner and performance benchmark harness:

```bash
# Run the complete test suite (98 unit tests)
swift run LoupeTests

# Run in production Release configuration
swift run -c release LoupeTests
```

Output:
```text
Starting Loupe Test Suite...

--- Suite: JSONValue ---
  ✓ testObjectPreservesMemberOrder (0.02ms)
  ✓ testObjectKeepsDuplicateKeys (0.00ms)
  ✓ testNumberKeepsSourceSpelling (0.00ms)
  ✓ testPositionIsOneBased (0.00ms)
  ✓ testOutcomeDistinguishesTruncationFromFailure (0.00ms)

--- Suite: JSONLexer ---
  ✓ testStructuralTokens (0.02ms)
  ✓ testLiterals (0.02ms)
  ✓ testNumbersKeepSourceSpelling (0.00ms)
  ✓ testLeadingZeroIsInvalid (0.01ms)
  ✓ testStringEscapes (0.01ms)
  ✓ testUnicodeEscapeAndSurrogatePair (0.00ms)
  ✓ testLoneSurrogateDoesNotCrash (0.00ms)
  ✓ testPositionsAreOneBasedAndCountLines (0.00ms)
  ✓ testUnterminatedStringReportsPosition (0.00ms)
  ✓ testByteOrderMarkIsSkipped (0.00ms)

--- Suite: JSONParser ---
  ✓ testKeyOrderIsSourceOrder (0.01ms)
  ✓ testDuplicateKeysBothSurvive (0.00ms)
  ✓ testNestedStructure (0.01ms)
  ✓ testBareScalarIsValidJSON (0.00ms)
  ✓ testEmptyContainers (0.00ms)
  ✓ testEmptyInputFails (0.00ms)
  ✓ testMissingCommaReportsPosition (0.00ms)
  ✓ testPartialTreeSurvivesFailure (0.00ms)
  ✓ testTrailingContentHintsAtJSONLines (0.04ms)
  ✓ testLexErrorPreservesPartialTree (0.00ms)
  ✓ testAncestorSiblingsSurviveNestedFailure (0.01ms)
  ✓ testTruncatedMidTokenReportsTruncationNotFailure (0.02ms)
  ✓ testLexErrorInTopLevelArrayPreservesItems (0.00ms)
  ✓ testArrayNestedInObjectPreservesBothLevels (0.00ms)
  ✓ testDepthBombDoesNotCrash (3.56ms)
  ✓ testDepthLimitIsExactlySixtyFour (0.04ms)
  ✓ testChildrenLimitTruncatesAndCounts (0.22ms)
  ✓ testChildrenLimitTruncatesAndCountsObject (1.70ms)
  ✓ testChildrenLimitAppliesOnFailurePathForArray (0.26ms)
  ✓ testChildrenLimitAppliesOnFailurePathForObject (1.01ms)
  ✓ testNodeLimitStopsBuilding (0.10ms)
  ✓ testLongStringIsTruncatedForDisplay (0.01ms)
  ✓ testLongObjectKeyIsTruncatedForDisplay (0.40ms)
  ✓ testTruncationIsNotReportedAsFailure (0.01ms)
  ✓ testMissingCommaInNestedObjectNestsPartialUnderAncestorKey (0.01ms)

--- Suite: SourceExcerpt ---
  ✓ testExcerptShowsContextAndCaret (0.10ms)
  ✓ testExcerptAtFirstLineDoesNotUnderflow (0.01ms)
  ✓ testVeryLongLineIsClipped (0.44ms)
  ✓ testTabsBecomeSpacesSoCaretAligns (0.02ms)
  ✓ testTabsPin_TwoTabsAndX (0.01ms)
  ✓ testEmojiPin_FireAndX (0.01ms)
  ✓ testUmlautPin_GrueseAndX (0.01ms)
  ✓ testASCIIPin_ABCAndX (0.00ms)
  ✓ testErrorOnLastLineWithContext (0.01ms)
  ✓ testLongContextLineWithCentre1Clipping (0.02ms)

--- Suite: HTMLEscape ---
  ✓ testEscapesAllFiveDangerousCharacters (0.00ms)
  ✓ testAmpersandEscapedFirst (0.00ms)
  ✓ testScriptInJSONStringIsNeutralised (0.02ms)
  ✓ testUnicodeAndEmojiSurviveUnchanged (0.00ms)

--- Suite: LoupeSettings ---
  ✓ testDefaults (0.00ms)
  ✓ testRoundTripThroughJSON (0.23ms)
  ✓ testAppGroupConstants (0.00ms)
  ✓ testTextSizeFontSizes (0.00ms)

--- Suite: CSSGenerator ---
  ✓ testSystemAppearanceEmitsBothThemes (0.02ms)
  ✓ testFixedAppearanceOmitsMediaQuery (0.06ms)
  ✓ testAllRenderClassesArePresent (0.63ms)
  ✓ testTextSizeReachesTheCSS (0.03ms)
  ✓ testNoJavaScriptAnywhere (0.28ms)
  ✓ testTreeIsMonospace (0.04ms)

--- Suite: JSONTreeRenderer ---
  ✓ testContainersBecomeDetailsElements (0.03ms)
  ✓ testScalarsAreNotCollapsible (0.01ms)
  ✓ testKeyOrderSurvivesIntoHTML (0.02ms)
  ✓ testCollapsedSummaryCarriesCountAndPeek (0.05ms)
  ✓ testOpenPathsControlTheOpenAttribute (0.07ms)
  ✓ testValueTypesGetTheirClasses (0.06ms)
  ✓ testScriptTagInStringIsEscaped (0.02ms)
  ✓ testKeyWithAngleBracketsIsEscaped (0.01ms)
  ✓ testOmittedChildrenAreDeclared (3.37ms)
  ✓ testParseErrorRendersBannerWithExcerpt (0.07ms)
  ✓ testTruncationUsesNoticeNotError (0.02ms)
  ✓ testNoJavaScriptInOutput (0.10ms)

--- Suite: ExpansionPolicy ---
  ✓ testSmallDocumentOpensCompletely (0.03ms)
  ✓ testFlatArrayBeyondBudgetStaysClosed (0.30ms)
  ✓ testBreadthFirstPrefersUpperLevels (0.02ms)
  ✓ testBudgetIsRespected (0.11ms)
  ✓ testScalarRootYieldsEmptyPlan (0.00ms)
  ✓ testZeroBudgetOpensNothing (0.00ms)
  ✓ testSmallerSiblingOpensEvenIfEarlierSiblingExceedsBudget (0.01ms)
  ✓ testBreadthFirstPrefersUpperLevelsOverDeepDescent (0.01ms)

--- Suite: Registry & Document ---
  ✓ testJSONTypeResolvesToJSONRenderer (0.05ms)
  ✓ testUnknownTypeResolvesToNil (2.16ms)
  ✓ testDocumentCarriesTheExactCSP (0.02ms)
  ✓ testDocumentEscapesTheTitle (0.02ms)
  ✓ testEndToEndRenderOfRealFile (0.70ms)
  ✓ testInvalidUTF8DoesNotCrash (0.05ms)
  ✓ testEmptyFileRendersBannerNotBlankPage (0.11ms)
  ✓ testTruncatedInputRendersTruncationNotice (0.23ms)

--- Suite: ExtensionStatus ---
  ✓ testTitles (0.00ms)
  ✓ testIsOperational (0.00ms)
  ✓ testBundleIdConstant (0.00ms)
  ✓ testParsesPluginkitOutput (0.01ms)

--- Suite: Performance ---
  ✓ testSmallDocumentUnder50ms (11.39ms)
  ✓ testFiveMegabytesUnderOneSecond (162.32ms)

==================================================
TEST RESULT: SUCCESS
All 98 unit tests passed successfully!
==================================================
```

---

## Security Architecture

Developer files frequently originate from untrusted external sources (e.g. untrusted git repositories, public API downloads, unvetted payloads). Loupe enforces strict security and isolation guarantees:

- **App Sandbox**: Both the host application and the Quick Look App Extension operate within isolated App Sandboxes (`com.apple.security.app-sandbox`) with read-only file privileges (`com.apple.security.files.user-selected.read-only`).
- **Strict Content Security Policy (CSP)**: The HTML document envelope sets an uncompromising security policy:
  ```text
  default-src 'none'; style-src 'unsafe-inline'; img-src 'none'
  ```
- **Zero JavaScript Execution**: Unlike other Quick Look plugins that embed JavaScript highlighters, DOM builders, or tracking scripts, Loupe executes **zero bytes of JavaScript**. Interactive folding is powered exclusively by the system's native HTML `<details>` and `<summary>` rendering engine.
- **Single-Pass HTML Sanitization**: All object keys, string values, error messages, and window titles are processed through a single-pass escape function (`HTMLEscape`), neutralizing `&`, `<`, `>`, `"`, and `'` while preventing character order re-escaping vulnerabilities.
- **Strict Hard Limits (DoS Prevention)**:
  - **Depth Limit**: Maximum 64 nested levels. Protects against parser stack overflow caused by nested recursion bombs (e.g. `[[[[...]]]]`).
  - **Node Limit**: Stops AST allocation at 20,000 nodes to prevent unbounded memory growth.
  - **Child Limit**: Caps container display at 1,000 children, displaying an explicit omission counter for remaining elements.
  - **String Limit**: Strings exceeding 4 KB are clipped with an ellipsis for preview rendering.
  - **Byte Boundary**: Files over 20 MB are read only up to the limit and gracefully reported as truncated rather than broken.
- **Zero Network Access**: The sandbox strictly forbids inbound and outbound network sockets.
- **Zero Telemetry**: No analytics, no metrics collection, no crash telemetry. 100% offline.

---

## Support & Donation

Loupe is independent, open-source software licensed under the MIT License. If Loupe saves you time or enhances your workflow, consider supporting its development:

<div align="center">
  <a href="https://www.paypal.com/donate/?business=martin.pfeffer%40celox.io&item_name=Loupe&currency_code=EUR">
    <img src="https://img.shields.io/badge/Donate-PayPal-00457C?logo=paypal&logoColor=white&style=for-the-badge" alt="Donate via PayPal" />
  </a>
  <br>
  <strong>PayPal:</strong> <a href="mailto:martin.pfeffer@celox.io">martin.pfeffer@celox.io</a>
</div>

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

Developed with ❤️ by **Martin Pfeffer** ([celox.io](https://celox.io)) © 2026.
