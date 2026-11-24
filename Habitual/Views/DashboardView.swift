import SwiftUI
import SwiftData

struct DashboardView: View {
    // @Query = "keep me updated with all Habits in the database".
    // Add or remove one anywhere and this list refreshes by itself.
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @Environment(\.modelContext) private var context
    @State private var viewModel = DashboardViewModel()
    @State private var showingAddHabit = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        heroCard
                        habitsSection
                    }
                    .padding()
                }
            }
            // We draw our own header, so hide the system navigation bar
            .toolbar(.hidden, for: .navigationBar)
            // "When someone taps a Habit link, show this screen"
            .navigationDestination(for: Habit.self) { habit in
                HabitDetailView(habit: habit)
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
    }

    // MARK: - Header (greeting + actions)
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Today")
                    .font(.largeTitle.bold())
            }
            Spacer()
            HStack(spacing: 12) {
                circleButton(icon: "plus") { showingAddHabit = true }
            }
        }
    }

    // A round glass button with an icon (reused by both header buttons)
    private func circleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Hero card (ring + stats)
    private var heroCard: some View {
        let progress = viewModel.todayProgress(for: habits)

        return GlassCard {
            HStack(spacing: 24) {
                // Ring with the percentage in the middle
                ZStack {
                    ProgressRing(progress: progress)
                    Text("\(Int(progress * 100))%")
                        .font(.title.bold())
                        // numericText makes digits roll over like an odometer
                        .contentTransition(.numericText())
                        .animation(.spring, value: progress)
                }
                .frame(width: 120, height: 120)

                // Stats on the right
                VStack(alignment: .leading, spacing: 14) {
                    statRow(icon: "checkmark.circle.fill",
                            tint: Theme.emerald,
                            title: "\(viewModel.completedCount(for: habits)) of \(habits.count)",
                            subtitle: "done today")
                    statRow(icon: "flame.fill",
                            tint: Theme.gold,
                            title: "\(viewModel.bestCurrentStreak(for: habits)) days",
                            subtitle: "best streak")
                    statRow(icon: "chart.line.uptrend.xyaxis",
                            tint: Theme.cyan,
                            title: "\(viewModel.weeklyConsistency(for: habits))%",
                            subtitle: "this week")
                }
                Spacer(minLength: 0)
            }
        }
    }

    // A small reusable row: icon + bold number + faint label
    private func statRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.numericText())
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Habit list
    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your habits")
                .font(.title3.bold())

            if habits.isEmpty {
                // Friendly empty state
                GlassCard {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(Theme.primaryGradient)
                        Text("Plant your first habit")
                            .font(.headline)
                        Text("Tap + to start growing.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(habits) { habit in
                    HabitCardView(habit: habit) {
                        // withAnimation makes the ring and numbers animate smoothly
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            viewModel.toggleToday(habit, context: context)
                        }
                    }
                    // Cards fade and shrink slightly as they scroll off-screen,
                    // giving a sense of depth (a light "parallax" feel).
                    .scrollTransition { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.5)
                            .scaleEffect(phase.isIdentity ? 1 : 0.94)
                    }
                    // Long-press a card to delete it
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.delete(habit, context: context)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
        .preferredColorScheme(.dark)
}
