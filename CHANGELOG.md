# Changelog

Alle nennenswerten Änderungen an **Loupe** stehen in dieser Datei.

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
Versionierung nach [Semantic Versioning](https://semver.org/lang/de/).

## [0.1.0] - 2026-09-22

### Hinzugefügt
- Quick-Look-Erweiterung `io.celox.loupe.preview` für `public.json`
- Aufklappbarer JSON-Baum aus verschachtelten `<details>` — **ohne JavaScript**
- Ordnungserhaltender Parser: Schlüsselreihenfolge, doppelte Schlüssel und
  Zahlen-Schreibweise bleiben wie in der Datei
- Fehlerbanner mit Zeile, Spalte und Quelltext-Ausschnitt; der bis dahin
  gelesene Teilbaum bleibt sichtbar
- Grenzen gegen große und bösartige Dateien, darunter eine Tiefenbremse
  gegen den Stapelüberlauf durch tief verschachtelte Arrays
- Voreingestellte Klappstellung nach Zeilenbudget statt fester Tiefe
- Begleit-App mit Erweiterungs-Status und Einstellungen
