import SwiftUI

// MARK: - Color from Hex
// Lets us write Color(hex: "#6E6BFF") instead of fiddling with RGB numbers.
extension Color {
    init(hex: String) {
        // Strip "#" and any spaces
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)   // Convert hex text to a number

        // Split the number into red, green, blue parts (each 0-255)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - App Theme
// One place that holds every color and style.
// Analogy: the brand style guide. Change it here, the whole app updates.
enum Theme {
    // Brand colors from the spec
    static let indigo   = Color(hex: "#6E6BFF")  // Primary
    static let cyan     = Color(hex: "#00E5FF")  // Accent
    static let emerald  = Color(hex: "#00D68F")  // Success
    static let gold     = Color(hex: "#FFD700")  // Achievements
    static let charcoal = Color(hex: "#0A0A0F")  // Dark background
    static let violet   = Color(hex: "#9B6BFF")  // Used in gradients

    // The signature gradient: indigo -> cyan, used for rings and highlights
    static let primaryGradient = LinearGradient(
        colors: [indigo, cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Success gradient: emerald -> cyan, used for completed states
    static let successGradient = LinearGradient(
        colors: [emerald, cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Spacing and corner sizes, so every screen feels consistent
    static let cornerRadius: CGFloat = 24
    static let padding: CGFloat = 16
}
