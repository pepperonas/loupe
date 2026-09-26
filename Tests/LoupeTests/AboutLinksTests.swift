import Foundation
import LoupeCore

/// Der Bereich „Über Loupe“ darf nie eine erfundene Adresse zeigen.
@MainActor
public enum AboutLinksTests {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("AboutLinks") {

            runner.runTest(name: "testAuthorSiteRepoAndLicenseAreTheRealOnes") {
                try assertEqual(AboutLinks.author, "Martin Pfeffer")
                try assertEqual(AboutLinks.websiteURL.absoluteString, "https://celox.io")
                try assertEqual(AboutLinks.productURL.absoluteString, "https://loupe.celox.io")
                try assertEqual(AboutLinks.repoURL.absoluteString, "https://github.com/pepperonas/loupe")
                try assertTrue(AboutLinks.licenseURL.absoluteString.hasPrefix(AboutLinks.repoURL.absoluteString))
                try assertTrue(AboutLinks.licenseURL.absoluteString.hasSuffix("/LICENSE"))
            }

            runner.runTest(name: "testLicenseNameMatchesTheLicenseFile") {
                let text = try String(contentsOf: root.appendingPathComponent("LICENSE"), encoding: .utf8)
                try assertTrue(text.hasPrefix("MIT License"), "LICENSE ist keine MIT-Lizenz mehr")
                try assertTrue(text.contains(AboutLinks.author), "Autor steht nicht im LICENSE")
                try assertEqual(L10n(.de).licenseName, "MIT-Lizenz")
                try assertEqual(L10n(.en).licenseName, "MIT License")
            }

            runner.runTest(name: "testDonateGoesToTheAuthorsPayPalWithTheAppAsNote") {
                let url = AboutLinks.donateURL().absoluteString
                try assertTrue(url.hasPrefix("https://www.paypal.com/donate/?"), url)
                try assertTrue(url.contains("business=martin.pfeffer@celox.io"), url)
                try assertTrue(url.contains("currency_code=EUR"), url)
                try assertTrue(url.hasSuffix("item_name=Loupe"), url)
            }

            runner.runTest(name: "testSpacesInTheNoteAreEncodedNotPlus") {
                let url = AboutLinks.donateURL(item: "Loupe Pro").absoluteString
                try assertTrue(url.hasSuffix("item_name=Loupe%20Pro"), url)
                try assertFalse(url.contains("+"), url)
            }

            runner.runTest(name: "testEveryLinkIsHTTPS") {
                for u in [AboutLinks.websiteURL, AboutLinks.productURL, AboutLinks.repoURL,
                          AboutLinks.licenseURL, AboutLinks.donateURL()] {
                    try assertEqual(u.scheme, "https", u.absoluteString)
                }
            }

            runner.runTest(name: "testTheBusinessMatchesTheOtherProjects") {
                // Dieselbe Empfaengeradresse wie in termstats und Flipper the Ripper.
                let readme = try String(contentsOf: root.appendingPathComponent("README.md"), encoding: .utf8)
                try assertTrue(readme.contains("martin.pfeffer") && readme.contains("paypal.com/donate"),
                               "README soll denselben PayPal-Link fuehren wie die App")
            }
        }
    }
}
