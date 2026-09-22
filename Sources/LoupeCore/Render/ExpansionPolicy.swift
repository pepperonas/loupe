import Foundation

public enum ExpansionPolicy {

    /// Liefert die Pfade der Container, die beim Oeffnen aufgeklappt sein
    /// sollen. Ein Pfad ist die Folge der Kindindizes ab der Wurzel;
    /// die Wurzel selbst ist der leere Pfad.
    ///
    /// Breitensuche statt fester Tiefe: bei knappem Budget sind die oberen
    /// Ebenen wertvoller, und ein flaches Riesenarray bleibt zu, obwohl es
    /// auf Ebene 1 liegt.
    public static func plan(root: JSONValue, budget: Int) -> Set<[Int]> {
        var open: Set<[Int]> = []
        var spent = 0
        var queue: [(path: [Int], value: JSONValue)] = [([], root)]
        var head = 0

        while head < queue.count {
            let (path, value) = queue[head]
            head += 1

            let children: [(Int, JSONValue)]
            switch value {
            case .array(let items, _):
                children = Array(items.enumerated())
            case .object(let members, _):
                children = members.enumerated().map { ($0.offset, $0.element.value) }
            default:
                continue                     // Skalare kosten nichts und sind nie "offen"
            }

            // Ein geoeffneter Container zeigt eine Zeile je Kind.
            let cost = children.count
            guard spent + cost <= budget else { continue }

            open.insert(path)
            spent += cost
            for (index, child) in children {
                queue.append((path + [index], child))
            }
        }
        return open
    }
}
