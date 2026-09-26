import Foundation

/// Texte der Begleit-App in Englisch und Deutsch (die Texte selbst: L10n+App.swift).
/// Die Quick-Look-Vorschau wird bewusst NICHT uebersetzt -- sie bleibt, wie sie ist.
public struct L10n: Sendable {
    public let lang: LoupeLanguage
    public init(_ lang: LoupeLanguage) { self.lang = lang }
}
