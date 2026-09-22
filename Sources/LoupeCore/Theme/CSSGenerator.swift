import Foundation

public enum CSSGenerator {

    private static let lightVars = """
        --bg: #ffffff;
        --bg-alt: #f6f8fa;
        --text: #1d1d1f; /* 16.83:1 */
        --text-dim: #5b5e69; /* 6.46:1 */
        --border: #e5e5ea;
        --key:  #0b5fb0; /* 6.41:1 */
        --str:  #b3261e; /* 6.54:1 */
        --num:  #1c00cf; /* 10.77:1 */
        --bool: #7a3ea3; /* 6.90:1 */
        --null: #5b5e69; /* 6.46:1 */
        --count: #5b5e69; /* 6.46:1 */
        --err-bg: rgba(255, 59, 48, 0.06);
        --err-fg: #a5251c; /* 6.72:1 */
        --note-bg: rgba(0, 113, 227, 0.06);
        --note-fg: #0a5aa8; /* 6.39:1 */
    """

    private static let darkVars = """
        --bg: #1e1e1e;
        --bg-alt: #28282b;
        --text: #f5f5f7; /* 15.31:1 */
        --text-dim: #a1a1a6; /* 6.48:1 */
        --border: #38383a;
        --key:  #7ab8ff; /* 8.04:1 */
        --str:  #ff8170; /* 6.85:1 */
        --num:  #dabaff; /* 9.88:1 */
        --bool: #d8a0ff; /* 8.25:1 */
        --null: #a1a1a6; /* 6.48:1 */
        --count: #a1a1a6; /* 6.48:1 */
        --err-bg: rgba(255, 69, 58, 0.10);
        --err-fg: #ff8a80; /* 6.64:1 */
        --note-bg: rgba(10, 132, 255, 0.12);
        --note-fg: #7ab8ff; /* 7.05:1 */
    """

    private static let mdLightVars = """
        --bg-primary: #ffffff;
        --bg-secondary: #f5f5f7;
        --bg-code: #f6f8fa;
        --bg-code-header: #eceef1;
        --bg-table-alt: #fbfbfd;
        --text-primary: #1d1d1f;
        --text-secondary: #6e6e73;
        --text-muted: #86868b;
        --link-color: #0066cc;
        --border-color: #e5e5ea;
        --border-subtle: #f0f0f2;
        --blockquote-border: #0071e3;
        --blockquote-bg: rgba(0, 113, 227, 0.04);
        --table-border: #e0e0e5;
        --hl-kw: #af00db;
        --hl-type: #2b1378;
        --hl-str: #c41a16;
        --hl-num: #1c00cf;
        --hl-com: #6e6e73;
        --hl-attr: #835200;
        --hl-fn: #0f6f7b;
        --hl-prop: #3900a0;
        --hl-op: #434346;
        --hl-tag: #0066cc;
        --badge-bg: #e5e5ea;
        --badge-text: #48484a;
    """

    private static let mdDarkVars = """
        --bg-primary: #1e1e1e;
        --bg-secondary: #252528;
        --bg-code: #28282b;
        --bg-code-header: #323236;
        --bg-table-alt: #222225;
        --text-primary: #f5f5f7;
        --text-secondary: #a1a1a6;
        --text-muted: #86868b;
        --link-color: #2997ff;
        --border-color: #38383a;
        --border-subtle: #2c2c2e;
        --blockquote-border: #0a84ff;
        --blockquote-bg: rgba(10, 132, 255, 0.08);
        --table-border: #38383a;
        --hl-kw: #ff7ab2;
        --hl-type: #ac80ff;
        --hl-str: #ff8170;
        --hl-num: #dabaff;
        --hl-com: #7f8c98;
        --hl-attr: #ffd866;
        --hl-fn: #66c2cd;
        --hl-prop: #78c2b4;
        --hl-op: #e0e0e0;
        --hl-tag: #5ac8fa;
        --badge-bg: #3a3a3c;
        --badge-text: #aeaeb2;
    """

    private static let csvLightVars = """
        --bg: #ffffff;
        --bg-secondary: #f5f5f7;
        --bg-alt: #f8f9fa;
        --bg-hover: #eef3fd;
        --text: #1d1d1f;
        --text-dim: #6e6e73;
        --border: #e5e5ea;
        --border-strong: #d1d1d6;
        --num: #1c00cf;
        --badge-bg: #f2f2f7;
        --badge-text: #48484a;
        --note-bg: rgba(0, 113, 227, 0.06);
        --note-fg: #0a5aa8;
        --err-bg: rgba(255, 59, 48, 0.06);
        --err-fg: #a5251c;
    """

    private static let csvDarkVars = """
        --bg: #1e1e1e;
        --bg-secondary: #26262a;
        --bg-alt: #232326;
        --bg-hover: #2a313d;
        --text: #f5f5f7;
        --text-dim: #98989d;
        --border: #38383a;
        --border-strong: #48484a;
        --num: #7ab8ff;
        --badge-bg: #2c2c2e;
        --badge-text: #aeaeb2;
        --note-bg: rgba(10, 132, 255, 0.12);
        --note-fg: #7ab8ff;
        --err-bg: rgba(255, 69, 58, 0.10);
        --err-fg: #ff8a80;
    """

    public static func generateCSS(settings: LoupeSettings) -> String {
        generateJSONCSS(settings: settings)
    }

    public static func generateJSONCSS(settings: LoupeSettings) -> String {
        let size = settings.textSize.baseFontSizePx
        let vars: String
        switch settings.appearance {
        case .light:
            vars = ":root {\n\(lightVars)\n}"
        case .dark:
            vars = ":root {\n\(darkVars)\n}"
        case .system:
            // Nur im System-Modus darf die OS-Einstellung mitreden.
            vars = """
            :root {
            \(lightVars)
            }
            @media (prefers-color-scheme: dark) {
                :root {
                \(darkVars)
                }
            }
            """
        }

        return """
        \(vars)

        * { box-sizing: border-box; }
        body {
            margin: 0;
            padding: 20px 24px;
            background: var(--bg);
            color: var(--text);
            font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace;
            font-size: \(size)px;
            line-height: 1.55;
            -webkit-font-smoothing: antialiased;
        }

        .lp-tree { white-space: nowrap; }
        .lp-node { padding-left: 1.35em; }
        .lp-tree > .lp-node { padding-left: 0; }

        details > summary {
            cursor: default;
            list-style: none;
            border-radius: 5px;
            padding: 1px 4px;
            margin-left: -4px;
        }
        details > summary::-webkit-details-marker { display: none; }
        details > summary::before {
            content: "\\25B8";
            display: inline-block;
            width: 1em;
            color: var(--text-dim);
            transition: transform 120ms ease;
        }
        details[open] > summary::before { transform: rotate(90deg); }
        details > summary:hover { background: var(--bg-alt); }
        details > summary:focus-visible {
            outline: 2px solid var(--key);
            outline-offset: 1px;
        }

        .lp-key  { color: var(--key); }
        .lp-str  { color: var(--str); }
        .lp-num  { color: var(--num); }
        .lp-bool { color: var(--bool); }
        .lp-null { color: var(--null); font-style: italic; }

        .lp-count, .lp-peek { color: var(--count); }
        .lp-peek::before { content: " · "; }

        .lp-omitted {
            color: var(--text-dim);
            font-style: italic;
            padding-left: 1.35em;
        }

        .lp-banner {
            border-radius: 8px;
            padding: 12px 14px;
            margin-bottom: 16px;
            border: 1px solid var(--border);
            white-space: normal;
        }
        .lp-banner-error  { background: var(--err-bg);  color: var(--err-fg); }
        .lp-banner-notice { background: var(--note-bg); color: var(--note-fg); }

        .lp-excerpt {
            margin: 10px 0 0;
            padding: 8px 10px;
            background: var(--bg-alt);
            border-radius: 6px;
            color: var(--text);
            overflow-x: auto;
            white-space: pre;
        }
        .lp-caret { color: var(--err-fg); font-weight: 700; }

        @media (prefers-reduced-motion: reduce) {
            details > summary::before { transition: none; }
        }
        """
    }

    public static func generateMarkdownCSS(settings: LoupeSettings) -> String {
        let baseFontSize = settings.textSize.markdownBaseFontSizePx
        let codeFontSize = settings.textSize.codeFontSizePx
        let maxWidth = settings.contentWidth.cssMaxWidth
        
        let rootBlock: String
        switch settings.appearance {
        case .light:
            rootBlock = ":root { \(mdLightVars) }"
        case .dark:
            rootBlock = ":root { \(mdDarkVars) }"
        case .system:
            rootBlock = """
            :root {
                \(mdLightVars)
            }
            @media (prefers-color-scheme: dark) {
                :root {
                    \(mdDarkVars)
                }
            }
            """
        }
        
        return """
        \(rootBlock)
        
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        
        html {
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", "Helvetica Neue", Helvetica, Arial, sans-serif;
            font-size: \(baseFontSize)px;
            line-height: 1.6;
            color: var(--text-primary);
            background-color: var(--bg-primary);
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
            text-rendering: optimizeLegibility;
        }
        
        body {
            background-color: var(--bg-primary);
            color: var(--text-primary);
            padding: 32px 24px 64px 24px;
            display: flex;
            justify-content: center;
        }
        
        .loupe-markdown-container {
            width: 100%;
            max-width: \(maxWidth);
            margin: 0 auto;
        }
        
        /* Typography */
        h1, h2, h3, h4, h5, h6 {
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", sans-serif;
            color: var(--text-primary);
            font-weight: 600;
            line-height: 1.25;
            margin-top: 1.5em;
            margin-bottom: 0.6em;
            letter-spacing: -0.015em;
        }
        
        h1:first-child, h2:first-child, h3:first-child {
            margin-top: 0;
        }
        
        h1 {
            font-size: 2.1em;
            font-weight: 700;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 0.3em;
            margin-top: 0.5em;
        }
        
        h2 {
            font-size: 1.55em;
            border-bottom: 1px solid var(--border-subtle);
            padding-bottom: 0.25em;
        }
        
        h3 { font-size: 1.25em; }
        h4 { font-size: 1.05em; }
        h5 { font-size: 0.9em; font-weight: 600; text-transform: uppercase; color: var(--text-secondary); }
        h6 { font-size: 0.8em; font-weight: 600; text-transform: uppercase; color: var(--text-muted); }
        
        p {
            margin-bottom: 1.1em;
            color: var(--text-primary);
            word-break: break-word;
        }
        
        strong { font-weight: 600; }
        em { font-style: italic; }
        del { text-decoration: line-through; color: var(--text-secondary); }
        
        /* Links */
        a {
            color: var(--link-color);
            text-decoration: none;
            transition: color 0.15s ease;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        /* Lists */
        ul, ol {
            margin-top: 0.4em;
            margin-bottom: 1.2em;
            padding-left: 1.8em;
        }
        
        li {
            margin-bottom: 0.35em;
        }
        
        li > ul, li > ol {
            margin-top: 0.2em;
            margin-bottom: 0.2em;
        }
        
        /* Task Lists */
        ul.task-list {
            list-style-type: none;
            padding-left: 0.3em;
        }
        
        li.task-list-item {
            display: flex;
            align-items: flex-start;
            margin-bottom: 0.45em;
            list-style-type: none;
        }
        
        li.task-list-item input[type="checkbox"] {
            margin-right: 0.6em;
            margin-top: 0.35em;
            cursor: default;
            accent-color: var(--link-color);
            transform: scale(1.15);
        }
        
        li.task-list-item.checked {
            color: var(--text-secondary);
        }
        
        /* Blockquotes */
        blockquote {
            margin: 1.2em 0;
            padding: 0.6em 1.2em;
            border-left: 3px solid var(--blockquote-border);
            background-color: var(--blockquote-bg);
            border-radius: 0 6px 6px 0;
            color: var(--text-secondary);
        }
        
        blockquote > p:last-child {
            margin-bottom: 0;
        }
        
        /* Horizontal Rule */
        hr {
            height: 1px;
            background-color: var(--border-color);
            border: none;
            margin: 2em 0;
        }
        
        /* Tables */
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 1.4em 0;
            font-size: 0.95em;
            border-radius: 6px;
            overflow: hidden;
            border: 1px solid var(--table-border);
        }
        
        th, td {
            padding: 9px 14px;
            text-align: left;
            border-bottom: 1px solid var(--table-border);
        }
        
        th {
            background-color: var(--bg-secondary);
            font-weight: 600;
            color: var(--text-primary);
        }
        
        tr:nth-child(even) td {
            background-color: var(--bg-table-alt);
        }
        
        tr:last-child td {
            border-bottom: none;
        }
        
        /* Code */
        code {
            font-family: ui-monospace, "SF Mono", Menlo, Monaco, Consolas, monospace;
            font-size: \(codeFontSize)px;
            background-color: var(--bg-secondary);
            color: var(--text-primary);
            padding: 0.2em 0.4em;
            border-radius: 4px;
            border: 1px solid var(--border-color);
        }
        
        pre {
            margin: 1.3em 0;
            border-radius: 8px;
            background-color: var(--bg-code);
            border: 1px solid var(--border-color);
            overflow: hidden;
            position: relative;
        }
        
        .code-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            background-color: var(--bg-code-header);
            padding: 5px 14px;
            font-size: 11px;
            font-weight: 500;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 0.05em;
            border-bottom: 1px solid var(--border-subtle);
        }
        
        pre code {
            display: block;
            padding: 14px 16px;
            overflow-x: auto;
            border: none;
            background: transparent;
            font-size: \(codeFontSize)px;
            line-height: 1.55;
            tab-size: 4;
            white-space: pre;
        }
        
        /* Syntax highlighting tokens */
        .hl-kw { color: var(--hl-kw); font-weight: 500; }
        .hl-type { color: var(--hl-type); }
        .hl-str { color: var(--hl-str); }
        .hl-num { color: var(--hl-num); }
        .hl-com { color: var(--hl-com); font-style: italic; }
        .hl-attr { color: var(--hl-attr); }
        .hl-fn { color: var(--hl-fn); }
        .hl-prop { color: var(--hl-prop); }
        .hl-op { color: var(--hl-op); }
        .hl-punct { color: var(--text-muted); }
        .hl-tag { color: var(--hl-tag); font-weight: 500; }
        
        /* Images */
        img {
            max-width: 100%;
            height: auto;
            border-radius: 6px;
            margin: 0.8em 0;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
        }
        
        .image-blocked, .image-error {
            display: inline-flex;
            align-items: center;
            padding: 6px 12px;
            font-size: 0.85em;
            color: var(--text-secondary);
            background-color: var(--bg-secondary);
            border: 1px dashed var(--border-color);
            border-radius: 4px;
            margin: 0.5em 0;
        }
        
        /* Large file warning banner */
        .loupe-warning-banner {
            background-color: rgba(255, 149, 0, 0.12);
            border-left: 4px solid #ff9500;
            padding: 12px 16px;
            border-radius: 4px;
            margin-bottom: 24px;
            font-size: 0.9em;
            color: var(--text-primary);
        }
        """
    }

    public static func generateCSVCSS(settings: LoupeSettings) -> String {
        let size = settings.textSize.baseFontSizePx
        let rootBlock: String
        switch settings.appearance {
        case .light:
            rootBlock = ":root {\n\(csvLightVars)\n}"
        case .dark:
            rootBlock = ":root {\n\(csvDarkVars)\n}"
        case .system:
            rootBlock = """
            :root {
            \(csvLightVars)
            }
            @media (prefers-color-scheme: dark) {
                :root {
                \(csvDarkVars)
                }
            }
            """
        }

        return """
        \(rootBlock)

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        html, body {
            height: 100%;
            margin: 0;
            background-color: var(--bg);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", Helvetica, Arial, sans-serif;
            font-size: \(size)px;
            line-height: 1.45;
            -webkit-font-smoothing: antialiased;
        }

        body {
            padding: 14px 18px;
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }

        .lp-csv-container {
            display: flex;
            flex-direction: column;
            height: 100%;
            min-height: 0;
            gap: 10px;
        }

        .lp-csv-toolbar {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 11.5px;
            color: var(--text-dim);
            flex-shrink: 0;
        }

        .lp-csv-badge {
            display: inline-flex;
            align-items: center;
            padding: 2px 7px;
            border-radius: 4px;
            background-color: var(--badge-bg);
            color: var(--badge-text);
            font-weight: 500;
        }

        .lp-csv-table-wrapper {
            flex: 1 1 auto;
            min-height: 0;
            overflow: auto;
            border: 1px solid var(--border);
            border-radius: 6px;
            background-color: var(--bg);
        }

        .lp-csv-table {
            border-collapse: separate;
            border-spacing: 0;
            width: 100%;
            min-width: 100%;
            font-size: \(size)px;
        }

        .lp-csv-table thead {
            position: sticky;
            top: 0;
            z-index: 10;
        }

        .lp-csv-table th {
            position: sticky;
            top: 0;
            background-color: var(--bg-secondary);
            color: var(--text);
            font-weight: 600;
            padding: 7px 12px;
            text-align: left;
            border-bottom: 2px solid var(--border-strong);
            border-right: 1px solid var(--border);
            white-space: nowrap;
            user-select: none;
            z-index: 10;
        }

        .lp-csv-table th:last-child {
            border-right: none;
        }

        .lp-csv-table td {
            padding: 6px 12px;
            border-bottom: 1px solid var(--border);
            border-right: 1px solid var(--border);
            text-align: left;
            vertical-align: top;
            white-space: pre-wrap;
            word-break: break-word;
            max-width: 420px;
        }

        .lp-csv-table td:last-child {
            border-right: none;
        }

        .lp-csv-table tr:last-child td {
            border-bottom: none;
        }

        .lp-csv-table tbody tr:nth-child(even) {
            background-color: var(--bg-alt);
        }

        .lp-csv-table tbody tr:hover {
            background-color: var(--bg-hover);
        }

        .lp-csv-table th.lp-csv-row-num {
            position: sticky;
            top: 0;
            left: 0;
            z-index: 20;
            width: 1%;
            white-space: nowrap;
            text-align: right;
            color: var(--text-dim);
            font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace;
            font-size: 11px;
            padding-left: 10px;
            padding-right: 10px;
            user-select: none;
            background-color: var(--bg-secondary);
            border-right: 1px solid var(--border-strong);
        }

        .lp-csv-table td.lp-csv-row-num {
            position: sticky;
            left: 0;
            z-index: 5;
            width: 1%;
            white-space: nowrap;
            text-align: right;
            color: var(--text-dim);
            font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace;
            font-size: 11px;
            padding-left: 10px;
            padding-right: 10px;
            user-select: none;
            background-color: var(--bg-secondary);
            border-right: 1px solid var(--border-strong);
        }

        .lp-csv-table tbody tr:nth-child(even) td.lp-csv-row-num {
            background-color: var(--bg-secondary);
        }

        .lp-csv-table tbody tr:hover td.lp-csv-row-num {
            background-color: var(--bg-secondary);
        }

        .lp-csv-table th.lp-csv-num,
        .lp-csv-table td.lp-csv-num {
            text-align: right;
            font-variant-numeric: tabular-nums;
            white-space: nowrap;
        }

        .lp-csv-table td.lp-csv-num {
            color: var(--num);
        }

        .lp-banner {
            border-radius: 6px;
            padding: 10px 14px;
            border: 1px solid var(--border);
            white-space: normal;
            font-size: 12.5px;
            flex-shrink: 0;
        }
        .lp-banner-error  { background: var(--err-bg);  color: var(--err-fg); }
        .lp-banner-notice { background: var(--note-bg); color: var(--note-fg); }

        .lp-csv-empty {
            padding: 36px 20px;
            text-align: center;
            color: var(--text-dim);
            font-style: italic;
        }
        """
    }
}
