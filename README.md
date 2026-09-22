# Loupe

> Schnelle, native Quick-Look-Vorschau für Entwicklerdateien auf macOS — mit aufklappbaren Bäumen und **ohne ein einziges Byte JavaScript**.

Loupe ist der native macOS-Nachfolger von [MarkLook](https://github.com/pepperonas/marklook). In Version 0.1.0 startet Loupe mit erstklassiger Unterstützung für JSON-Dateien (`public.json`). Weitere Entwicklerformate (darunter Markdown) folgen in kommenden Versionen über eine modulare Renderer-Architektur.

<!-- Screenshot Placeholder: Loupe in Finder Quick Look -->
<!-- ![Loupe Quick Look Preview Screenshot](docs/screenshot.png) -->

---

## Funktionen (v0.1.0 JSON)

- **Aufklappbarer Baum ohne JavaScript:** Vollständig interaktive Baumstruktur über HTML5 `<details>`- und `<summary>`-Elemente. Kein Scripting, keine Script-Injection-Möglichkeit.
- **Ordnungserhaltender Parser:** Schlüsselreihenfolge, doppelte Schlüssel und Quelltext-Schreibweisen von Zahlen bleiben exakt wie in der Originaldatei erhalten.
- **Tolerante Fehleranzeige:** Syntaxfehler werden mit Zeile, Spalte, Quelltext-Ausschnitt und Zeiger (`^`) im roten Banner markiert. Der bis zum Fehler gültig geparste Teilbaum bleibt sichtbar.
- **Intelligente Vor-Aufklappung (BFS-Budget):** Dokumente werden bis zu einem sichtbaren Zeilenbudget (Standard: 120 Zeilen) in Breitensuche geöffnet — flache Riesen-Arrays sprengen die Ansicht nicht.
- **Robuster Schutz vor Grenzfällen:** Harte Obergrenzen (20 MB Dateigröße, 64 Tiefenstufen gegen Stack Overflow, 20.000 Knoten, 1.000 Kinder je Container, 4 KB String-Länge).
- **Dark & Light Mode:** Echte semantische Farbrollen mit gemessenem Kontrast > 4,5:1 (WCAG AA).
- **Begleit-App:** Schlanke macOS-App zur Statusprüfung der Quick-Look-Erweiterung und zur Konfiguration von Erscheinungsbild und Textgröße.

---

## Unterstützte Formate

- **JSON (`public.json`):** Volle Unterstützung inklusive `.json`, `package.json`, `tsconfig.json` etc.
- *Weitere Formate:* Markdown, YAML und weitere Entwicklerformate sind für kommende Versionen geplant.

---

## Installation

### Option 1: Release-Paket (empfohlen)
1. Lade `Loupe-v0.1.0-macOS.zip` von der [Releases-Seite](https://github.com/pepperonas/loupe/releases) herunter.
2. Entpacke das Archiv und ziehe `Loupe.app` in deinen `/Applications`-Ordner.
3. Öffne `Loupe.app` einmalig, um die Erweiterung bei macOS zu registrieren.

### Option 2: Aus dem Quelltext installieren
```bash
git clone https://github.com/pepperonas/loupe.git
cd loupe
./Scripts/install_app.sh
```

---

## Erweiterung in macOS aktivieren

Damit macOS Quick Look die Erweiterung verwendet, muss sie in den Systemeinstellungen aktiviert sein:

1. Öffne **Systemeinstellungen → Datenschutz & Sicherheit → Erweiterungen → Quick Look**.
2. Setze den Haken bei **„Loupe QuickLook Preview“** (bzw. `io.celox.loupe.preview`).
3. Starte den Quick-Look-Daemon im Terminal neu:
   ```bash
   qlmanage -r && qlmanage -r cache && killall Finder
   ```
4. Wähle im Finder eine beliebige `.json`-Datei aus und drücke die **Leertaste**.

---

## Tests & Architektur

Loupe hat **keine externen Abhängigkeiten** (Zero Dependencies) und nutzt ausschließlich die Swift-Standardbibliothek sowie Foundation, AppKit und QuickLookUI.

```bash
# Test-Suite ausführen (98 Tests)
swift run LoupeTests

# Im Release-Modus testen (Benchmarking)
swift run -c release LoupeTests
```

- **98 Unit-Tests** (inkl. Verifikations- und Mutations-Pins gegen subtile Regressionsfehler).
- **2.888 Zeilen Swift-Code** (Gesamtumfang inklusive Core-Bibliothek, App und Tests).
- **Performanz:** 50 KB JSON in < 10 ms, 5 MB JSON in < 170 ms (Release-Modus).

---

## Sicherheit & Datenschutz

- **App Sandbox:** Sowohl die Begleit-App als auch das Quick-Look-Plugin laufen in isolierten App-Sandboxes (`com.apple.security.app-sandbox`).
- **Strenge Content Security Policy (CSP):**
  ```text
  default-src 'none'; style-src 'unsafe-inline'; img-src 'none'
  ```
- **Zero JavaScript:** Im gesamten erzeugten HTML existiert kein `<script>`-Tag und kein Script-Code. Klickinteraktionen laufen nativ über den Browser-Renderer des Systems.
- **Kein Netzwerkzugriff:** Die Sandbox verbietet ein- und ausgehende Netzwerkverbindungen.
- **Keine Telemetrie / Analytics:** Loupe sammelt keinerlei Daten und sendet nichts ins Netz.

---

## Unterstützung & Spenden

Loupe ist freie Open-Source-Software unter der MIT-Lizenz. Wenn dir Loupe den Arbeitsalltag erleichtert, freue ich mich über einen Kaffee:

[![PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://paypal.me/celoxio)  
Spenden via PayPal an: `martin.pfeffer@celox.io`

---

## Lizenz

[MIT License](LICENSE) © 2026 Martin Pfeffer
