import SwiftUI
import SwiftData

struct HeatMapScreen: View {
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Environment(\.modelContext) private var context

    // nil = "All habits". Otherwise the id of the one habit to focus on.
    @State private var selectedHabitID: UUID?

    // Which habits to feed into the heat map, based on the chip chosen
    private var visibleHabits: [Habit] {
        guard let id = selectedHabitID else { return habits }
        return habits.filter { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        filterChips

                        if habits.isEmpty {
                            GlassCard {
                                Text("Add a habit first, then your history will light up here.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        } else {
                            // .id(selectedHabitID): switching chips rebuilds the map with a fresh animation
                            HeatMapView(habits: visibleHabits)
                                .id(selectedHabitID)
                        }

                        #if DEBUG
                        // Testing helper: only exists in debug builds, never ships to the App Store
                        Button("Fill sample history (debug)") {
                            SampleData.fillHistory(for: habits, context: context)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        #endif
                    }
                    .padding()
                }
            }
            .navigationTitle("Consistency")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // A horizontal row of pill buttons: "All", then one per habit
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                chip(title: "All", icon: "square.grid.2x2.fill", tint: Theme.indigo, isOn: selectedHabitID == nil) {
                    selectedHabitID = nil
                }
                ForEach(habits) { habit in
                    chip(title: habit.name,
                         icon: habit.iconName,
                         tint: Color(hex: habit.colorHex),
                         isOn: selectedHabitID == habit.id) {
                        selectedHabitID = habit.id
                    }
                }
            }
        }
    }

    private func chip(title: String, icon: String, tint: Color, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { action() }
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(isOn ? tint.opacity(0.3) : Color.white.opacity(0.06)))
                .overlay(Capsule().stroke(isOn ? tint : Color.white.opacity(0.1), lineWidth: 1))
                .foregroundStyle(isOn ? tint : .secondary)
        }
        .buttonStyle(.plain)
    }
}
