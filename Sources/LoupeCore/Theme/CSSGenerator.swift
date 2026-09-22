import Foundation

public enum CSSGenerator {

    private static let lightVars = """
        --bg: #ffffff;
        --bg-alt: #f6f8fa;
        --text: #1d1d1f;
        --text-dim: #5b5e69;
        --border: #e5e5ea;
        --key:  #0b5fb0;
        --str:  #b3261e;
        --num:  #1c00cf;
        --bool: #7a3ea3;
        --null: #5b5e69;
        --count: #5b5e69;
        --err-bg: rgba(255, 59, 48, 0.06);
        --err-fg: #a5251c;
        --note-bg: rgba(0, 113, 227, 0.06);
        --note-fg: #0a5aa8;
    """

    private static let darkVars = """
        --bg: #1e1e1e;
        --bg-alt: #28282b;
        --text: #f5f5f7;
        --text-dim: #a1a1a6;
        --border: #38383a;
        --key:  #7ab8ff;
        --str:  #ff8170;
        --num:  #dabaff;
        --bool: #d8a0ff;
        --null: #a1a1a6;
        --count: #a1a1a6;
        --err-bg: rgba(255, 69, 58, 0.10);
        --err-fg: #ff8a80;
        --note-bg: rgba(10, 132, 255, 0.12);
        --note-fg: #7ab8ff;
    """

    public static func generateCSS(settings: LoupeSettings) -> String {
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
}
