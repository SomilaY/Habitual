import SwiftUI

// One particle's random settings, decided once when the burst is created.
private struct Particle: Identifiable {
    let id = UUID()
    let angle = Double.random(in: 0..<(2 * .pi))     // direction (in radians)
    let distance = CGFloat.random(in: 90...170)      // how far it flies
    let size = CGFloat.random(in: 5...10)
    let colorIndex = Int.random(in: 0..<4)
}

struct CelebrationBurst: View {
    var accent: Color

    @State private var animate = false
    @State private var particles = (0..<28).map { _ in Particle() }

    var body: some View {
        // Pick from the brand colors plus the habit's own color
        let palette: [Color] = [accent, Theme.cyan, Theme.emerald, Theme.gold]

        ZStack {
            // An expanding ring, like a shockwave
            Circle()
                .stroke(accent.opacity(0.6), lineWidth: 3)
                .scaleEffect(animate ? 2.6 : 0.4)
                .opacity(animate ? 0 : 1)

            // The particles
            ForEach(particles) { p in
                Circle()
                    .fill(palette[p.colorIndex])
                    .frame(width: p.size, height: p.size)
                    // cos/sin turn an angle into x/y movement
                    .offset(x: animate ? cos(p.angle) * p.distance : 0,
                            y: animate ? sin(p.angle) * p.distance : 0)
                    .scaleEffect(animate ? 0.2 : 1)
                    .opacity(animate ? 0 : 1)
            }
        }
        .frame(width: 120, height: 120)
        .allowsHitTesting(false)   // don't block taps on things underneath
        .onAppear {
            // Flip the switch once; SwiftUI animates everything above.
            withAnimation(.easeOut(duration: 1.0)) {
                animate = true
            }
        }
    }
}
