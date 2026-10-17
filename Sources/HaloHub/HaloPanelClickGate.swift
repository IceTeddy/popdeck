import Foundation

/// One pointer press/release is handled once, before nested AppKit glass views.
struct HaloPanelClickGate {
    private var tracking = false
    mutating func begin(inside: Bool, groupExpanded: Bool) -> Bool {
        tracking = inside && !groupExpanded
        return tracking
    }
    mutating func finish() -> Bool {
        defer { tracking = false }
        return tracking
    }
    mutating func reset() { tracking = false }
}
