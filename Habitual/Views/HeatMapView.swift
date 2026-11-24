import SwiftUI

// The color scale, kept in one place (also reused by the legend).
// Five levels, from "nothing" up to "perfect day".
enum HeatMapPalette {
    static func color(for intensity: Double) -> Color {
        if intensity <= 0    { return Color.white.opacity(0.06) }   // nothing done
        if intensity < 0.34  { return Theme.indigo.opacity(0.35) }  // a little
        if intensity < 0.67  { return Theme.indigo }                // about half
        if intensity < 1     { return Theme.cyan }                  // most
        return Theme.emerald                                        // everything!
    }

    // Used by the legend: one sample color per level
    static let legend: [Double] = [0, 0.2, 0.5, 0.8, 1]
}

// MARK: - A single day box
private struct HeatCell: View {
    let day: Date
    let index: Int              // position in the grid, used to stagger the pop-in
    let intensity: Double
    let isSelected: Bool
    let isToday: Bool
    let isFuture: Bool

    // Starts false (small + invisible). Flips to true on appear, which triggers the pop-in.
    @State private var appeared = false

    var body: some View {
        Text("\(Calendar.current.component(.day, from: day))")
            .font(.caption2.weight(.medium))
            // Dark text on bright cells, light text on dim ones, so it's always readable
            .foregroundStyle(intensity >= 0.67 ? Color.black.opacity(0.7) : Color.white.opacity(0.75))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)           // keep every box square
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(HeatMapPalette.color(for: intensity))
                    // A "perfect day" gets a soft glow
                    .shadow(color: intensity >= 1 ? Theme.emerald.opacity(0.5) : .clear, radius: 6)
            }
            .overlay {
                // White ring = selected. Cyan ring = today.
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.white : (isToday ? Theme.cyan : Color.clear),
                                  lineWidth: 1.5)
            }
            .scaleEffect(appeared ? (isSelected ? 1.12 : 1) : 0.3)
            .opacity(appeared ? (isFuture ? 0.3 : 1) : 0)
            // When the color changes (you complete a habit), fade smoothly to the new color
            .animation(.easeInOut(duration: 0.3), value: intensity)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            .onAppear {
                // Each cell waits a tiny bit longer than the one before it -> a ripple effect
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.012)) {
                    appeared = true
                }
            }
    }
}

// MARK: - The full heat map card
struct HeatMapView: View {
    // The habits to include. One habit = on/off days. Several = shades by how many were done.
    let habits: [Habit]

    @State private var viewModel = HeatMapViewModel()

    // 7 equal columns, one per weekday
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        // Work out the scoreboard once per redraw, not once per cell
        let counts = viewModel.counts(for: habits)

        GlassCard {
            VStack(spacing: 14) {
                monthHeader
                weekdayRow

                // The grid itself.
                // .id(monthStart): when the month changes, SwiftUI throws away the old cells
                // and builds new ones, so every cell runs its pop-in animation again.
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(viewModel.gridDays.enumerated()), id: \.offset) { index, day in
                        if let day {
                            HeatCell(
                                day: day,
                                index: index,
                                intensity: viewModel.intensity(on: day, counts: counts, habitCount: habits.count),
                                isSelected: viewModel.selectedDate == day,
                                isToday: viewModel.isToday(day),
                                isFuture: viewModel.isFuture(day)
                            )
                            .onTapGesture {
                                guard !viewModel.isFuture(day) else { return }
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    // Tap again to deselect
                                    viewModel.selectedDate = (viewModel.selectedDate == day) ? nil : day
                                }
                            }
                        } else {
                            Color.clear.aspectRatio(1, contentMode: .fit)  // empty spacer box
                        }
                    }
                }
                .id(viewModel.monthStart)

                legend

                // The "tooltip": details for the tapped day
                if let selected = viewModel.selectedDate {
                    tooltip(for: selected)
                }
            }
        }
        // Light tick feedback whenever the selection changes
        .sensoryFeedback(.selection, trigger: viewModel.selectedDate)
    }

    // MARK: - Pieces

    private var monthHeader: some View {
        HStack {
            Button { viewModel.changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left").frame(width: 36, height: 36)
            }

            Spacer()
            Text(viewModel.monthTitle)
                .font(.headline)
            Spacer()

            Button { viewModel.changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right").frame(width: 36, height: 36)
            }
            // Greyed out when you're already on the current month
            .disabled(!viewModel.canGoForward)
            .opacity(viewModel.canGoForward ? 1 : 0.3)
        }
        .foregroundStyle(.primary)
    }

    private var weekdayRow: some View {
        HStack(spacing: 6) {
            // enumerated() because letters repeat (S, T), so they can't be their own ID
            ForEach(Array(viewModel.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 6) {
            Spacer()
            Text("Less").font(.caption2).foregroundStyle(.secondary)
            ForEach(HeatMapPalette.legend, id: \.self) { level in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(HeatMapPalette.color(for: level))
                    .frame(width: 14, height: 14)
            }
            Text("More").font(.caption2).foregroundStyle(.secondary)
        }
    }

    // A small info panel: which date, and which habits were done that day
    private func tooltip(for day: Date) -> some View {
        let done = habits.filter { $0.isCompleted(on: day) }

        return VStack(alignment: .leading, spacing: 8) {
            Text(day.formatted(date: .complete, time: .omitted))
                .font(.subheadline.weight(.semibold))

            if done.isEmpty {
                Text("Nothing completed")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(done.count) of \(habits.count) completed")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ForEach(done) { habit in
                    Label(habit.name, systemImage: habit.iconName)
                        .font(.footnote)
                        .foregroundStyle(Color(hex: habit.colorHex))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.06)))
        // Slides up from the bottom while fading in
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
