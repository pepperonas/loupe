import Foundation
import LoupeCore

@MainActor
public enum ExpansionPolicyTests {

    static func parse(_ text: String) -> JSONValue {
        var p = JSONParser(bytes: Array(text.utf8))
        return p.parse().root ?? .null
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("ExpansionPolicy") {

            runner.runTest(name: "testSmallDocumentOpensCompletely") {
                // Eine package.json soll offen dastehen, nicht zugeklappt.
                let root = parse(#"{"a":{"b":{"c":1}},"d":[1,2]}"#)
                let open = ExpansionPolicy.plan(root: root, budget: 300)
                try assertTrue(open.contains([]),    "Wurzel zu")
                try assertTrue(open.contains([0]),   "a zu")
                try assertTrue(open.contains([0,0]), "b zu")
                try assertTrue(open.contains([1]),   "d zu")
            }

            runner.runTest(name: "testFlatArrayBeyondBudgetStaysClosed") {
                // Genau der Fall, an dem feste Tiefe scheitert: Ebene 1,
                // aber 2.000 Zeilen.
                let items = (0 ..< 2000).map(String.init).joined(separator: ",")
                let root = parse("[\(items)]")
                let open = ExpansionPolicy.plan(root: root, budget: 300)
                try assertFalse(open.contains([]), "Riesenarray haette zu bleiben muessen")
            }

            runner.runTest(name: "testBreadthFirstPrefersUpperLevels") {
                // Bei knappem Budget sind die oberen Ebenen wertvoller --
                // sie geben den Ueberblick.
                var deep = "1"
                for _ in 0 ..< 20 { deep = "{\"x\":\(deep)}" }
                let root = parse(deep)
                let open = ExpansionPolicy.plan(root: root, budget: 5)
                try assertTrue(open.contains([]), "Wurzel muss offen sein")
                try assertFalse(open.contains(Array(repeating: 0, count: 19)),
                                "tiefste Ebene darf nicht offen sein")
            }

            runner.runTest(name: "testBudgetIsRespected") {
                // Summe der Kinder aller geoeffneten Container = sichtbare Zeilen.
                let items = (0 ..< 40).map { "{\"k\($0)\":[1,2,3,4,5]}" }.joined(separator: ",")
                let root = parse("[\(items)]")
                let open = ExpansionPolicy.plan(root: root, budget: 60)
                var visible = 0
                func count(_ v: JSONValue, _ path: [Int]) {
                    guard open.contains(path) else { return }
                    switch v {
                    case .array(let xs, _):
                        visible += xs.count
                        for (i, x) in xs.enumerated() { count(x, path + [i]) }
                    case .object(let ms, _):
                        visible += ms.count
                        for (i, m) in ms.enumerated() { count(m.value, path + [i]) }
                    default: break
                    }
                }
                count(root, [])
                try assertTrue(visible <= 60, "Budget ueberschritten: \(visible)")
            }

            runner.runTest(name: "testScalarRootYieldsEmptyPlan") {
                try assertEqual(ExpansionPolicy.plan(root: parse("42"), budget: 300).count, 0)
            }

            runner.runTest(name: "testZeroBudgetOpensNothing") {
                let root = parse(#"{"a":1}"#)
                try assertEqual(ExpansionPolicy.plan(root: root, budget: 0).count, 0)
            }

            runner.runTest(name: "testSmallerSiblingOpensEvenIfEarlierSiblingExceedsBudget") {
                // Wenn ein Geschwisterknoten das Budget sprengt, darf ein kleinerer danach
                // trotzdem noch aufgehen (continue statt break).
                let root = parse(#"{"big":[1,2,3,4,5,6,7,8,9,10],"small":{"x":1}}"#)
                let open = ExpansionPolicy.plan(root: root, budget: 5)
                try assertTrue(open.contains([]), "Wurzel muss offen sein")
                try assertFalse(open.contains([0]), "big darf nicht offen sein")
                try assertTrue(open.contains([1]), "small muss offen sein")
            }

            runner.runTest(name: "testBreadthFirstPrefersUpperLevelsOverDeepDescent") {
                // BFS oeffnet Geschwister auf Ebene 1 (L und R), bevor es in die Tiefe abtaucht.
                // DFS wuerde in L -> LL abtauchen und R auf Ebene 1 verhungern lassen.
                let json = #"{"L":{"LL":{"a":1,"b":2},"LR":{"a":1,"b":2}},"R":{"RL":{"a":1,"b":2},"RR":{"a":1,"b":2}}}"#
                let root = parse(json)
                let open = ExpansionPolicy.plan(root: root, budget: 6)
                try assertTrue(open.contains([]), "Wurzel muss offen sein")
                try assertTrue(open.contains([0]), "Ebene 1 'L' muss offen sein")
                try assertTrue(open.contains([1]), "Ebene 1 'R' muss offen sein")
                try assertFalse(open.contains([0, 0]), "Ebene 2 'LL' darf bei Budget 6 noch nicht offen sein")
            }
        }
    }
}
