// CC0-1.0
import Foundation

/// Reliability is metadata attached from OUTSIDE. Text never asserts its own class.
public enum Trust: String, Codable, CaseIterable {
    case t1 = "T1"   // owner wrote it, or owner signed a statement
    case t2 = "T2"   // local model wrote it
    case t3 = "T3"   // frontier model wrote it (session scratch by default)
    case t4 = "T4"   // pasted from the outside world

    /// Lattice join: the LEAST trusted class wins when material is combined.
    public static func join(_ a: Trust, _ b: Trust) -> Trust {
        let order: [Trust] = [.t1, .t2, .t3, .t4]
        return order[max(order.firstIndex(of: a)!, order.firstIndex(of: b)!)]
    }
}

public enum Shelf: String, Codable { case resident, cold, orphan }
public enum Role { case librarian, judge, voice }

public struct MAObject: Codable, Identifiable {
    public let id: String
    public let trust: Trust
    public let source: String
    public var text: String?          // nil once orphaned; lives on in the event log
    public let createdAt: Double
    public var shelf: Shelf
    public var embedding: [Float]?
    public var stub: [String: String]?
}
