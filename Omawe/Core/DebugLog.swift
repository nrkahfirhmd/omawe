import Foundation

/// Same call signature as `print()`, but compiled out of Release builds
/// instead of shipping to production logs.
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let message = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(message, terminator: terminator)
    #endif
}
