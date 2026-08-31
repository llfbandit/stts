import Foundation

// Accepts "en_us", "en-us"... as "en-US".
func isSameLanguageTag(_ a: String, _ b: String) -> Bool {
  let a = a.replacingOccurrences(of: "_", with: "-")
  let b = b.replacingOccurrences(of: "_", with: "-")
  return a.caseInsensitiveCompare(b) == .orderedSame
}
