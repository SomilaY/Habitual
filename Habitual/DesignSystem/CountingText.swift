import SwiftUI

// Normally SwiftUI can't animate the *text* of a number, only its position or color.
// Conforming to Animatable teaches SwiftUI to feed us every in-between value (0.0, 0.3, 1.8 ...),
// and we simply show each one as a whole number.
struct CountingText: View, Animatable {
    var value: Double

    // This is the property SwiftUI changes frame-by-frame during an animation.
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("\(Int(value.rounded()))")
            .monospacedDigit()   // equal-width digits so the number doesn't wobble
    }
}
