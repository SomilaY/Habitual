import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit

    @Environment(\.modelContext) private var context
    @State private var viewModel: HabitDetailViewModel

    // Used to make the numbers count up from 0 when the screen appears
    @State private var hasAppeared = false
    // Used for the slow "breathing" glow behind the icon
    @State private var pulse = false

    // Custom init so we can build the ViewModel from the habit we're given.
    init(habit: Habit) {
        self.habit = habit
        _viewModel = State(initialValue: HabitDetailViewModel(habit: habit))
    }

    private var accent: Color { Color(hex: habit.colorHex) }
    private var isDone: Bool { habit.isCompleted() }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 20) {
                    heroIcon
                    streakCard
                    statsRow
                    HeatMapView(habits: [habit])
                    milestoneCard
                    ReminderCard(habit: habit)
                    Spacer(minLength: 90)   // room so the bottom button doesn't cover content
                }
                .padding()
            }
        }
        // The big button floats at the bottom of the screen
        .safeAreaInset(edge: .bottom) { completeButton }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            hasAppeared = true
            pulse = true
        }
    }

    // MARK: - Hero icon
    private var heroIcon: some View {
        VStack(spacing: 12) {
            ZStack {
                // Breathing glow behind the icon
                Circle()
                    .fill(accent.opacity(0.35))
                    .frame(width: 150, height: 150)
                    .blur(radius: 30)
                    .scaleEffect(pulse ? 1.15 : 0.9)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: pulse)

                // The icon itself in a glass disc
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 110, height: 110)
                    .overlay(Circle().stroke(accent.opacity(0.6), lineWidth: 1.5))

                Image(systemName: habit.iconName)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(accent)
                    // The icon does a little bounce whenever the done-state changes
                    .symbolEffect(.bounce, value: isDone)

                // The celebration burst appears on top, only while showCelebration is true
                if viewModel.showCelebration {
                    CelebrationBurst(accent: accent)
                }
            }
            .frame(height: 170)

            Text(habit.name)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("Started \(habit.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Streak card
    private var streakCard: some View {
        // Before the screen appears, show 0; afterwards the real streak.
        // The .animation below makes the number roll up between the two.
        let streak = hasAppeared ? habit.currentStreak : 0

        return GlassCard {
            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    CountingText(value: Double(streak))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryGradient)
                    Text("day streak")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.gold)
                        // Glow gets stronger when you have an active streak
                        .shadow(color: Theme.gold.opacity(streak > 0 ? 0.7 : 0), radius: 12)
                }
                .animation(.easeOut(duration: 1.0), value: streak)

                // Last 7 days, one circle each
                HStack {
                    ForEach(habit.lastDays(7)) { day in
                        VStack(spacing: 6) {
                            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            ZStack {
                                Circle()
                                    .fill(day.done ? AnyShapeStyle(Theme.successGradient)
                                                   : AnyShapeStyle(Color.white.opacity(0.08)))
                                    .frame(width: 30, height: 30)
                                if day.done {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Divider().overlay(Color.white.opacity(0.1))

                HStack {
                    Image(systemName: "trophy.fill").foregroundStyle(Theme.gold)
                    Text("Longest streak: \(habit.longestStreak) days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Stats row (3 small cards)
    private var statsRow: some View {
        let trend = habit.monthlyTrend
        let trendText = trend == 0 ? "same as last month"
                                   : "\(abs(trend)) \(trend > 0 ? "more" : "fewer") than last month"

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                miniStat(title: "Total", value: "\(habit.completions.count)", icon: "checkmark.seal.fill", tint: Theme.emerald)
                miniStat(title: "Success rate", value: "\(habit.completionRate)%", icon: "target", tint: Theme.cyan)
            }
            // Monthly trend: arrow up/down, green/orange
            GlassCard {
                HStack {
                    Image(systemName: trend >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(trend >= 0 ? Theme.emerald : .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(habit.completions(inMonthOffset: 0)) times this month")
                            .font(.subheadline.weight(.semibold))
                        Text(trendText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    private func miniStat(title: String, value: String, icon: String, tint: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(value)
                    .font(.title.bold())
                    .contentTransition(.numericText())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Milestone tracker
    // Analogy: stamps on a passport. Reach 7 days, get the 7 stamp.
    private var milestoneCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Milestones")
                    .font(.headline)

                HStack {
                    ForEach(Habit.milestones, id: \.self) { m in
                        milestoneBadge(m)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Message about what's next
                if let next = habit.nextMilestone {
                    Text("\(next - habit.currentStreak) more \(next - habit.currentStreak == 1 ? "day" : "days") to your \(next)-day milestone")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Every milestone unlocked. Legendary.")
                        .font(.footnote)
                        .foregroundStyle(Theme.gold)
                }
            }
        }
    }

    private func milestoneBadge(_ days: Int) -> some View {
        // "Reached" if your best-ever streak got this far
        let reached = habit.longestStreak >= days
        // Is this the one you're currently working toward?
        let isNext = habit.nextMilestone == days

        return VStack(spacing: 6) {
            ZStack {
                if reached {
                    // Gold, glowing
                    Circle()
                        .fill(LinearGradient(colors: [Theme.gold, .orange],
                                             startPoint: .top, endPoint: .bottom))
                        .shadow(color: Theme.gold.opacity(0.5), radius: 8)
                } else {
                    Circle().fill(Color.white.opacity(0.06))
                }

                // Progress ring on the one you're chasing
                if isNext {
                    ProgressRing(progress: Double(habit.currentStreak) / Double(days),
                                 lineWidth: 3,
                                 colors: [Theme.cyan, Theme.indigo])
                }

                Text("\(days)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(reached ? .black : .secondary)
            }
            .frame(width: 40, height: 40)

            Text("days")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Complete button
    private var completeButton: some View {
        Button {
            // Animate so the streak number rolls and the card updates smoothly
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                viewModel.toggleToday(context: context)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                Text(isDone ? "Done today. Tap to undo" : "Mark as done")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundStyle(isDone ? .primary : Color.black)
            .background(
                Capsule().fill(isDone ? AnyShapeStyle(.ultraThinMaterial)
                                      : AnyShapeStyle(Theme.successGradient))
            )
            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
            .shadow(color: isDone ? .clear : Theme.emerald.opacity(0.5), radius: 16, y: 6)
        }
        .buttonStyle(TiltPressStyle())
        .padding(.horizontal)
        .padding(.bottom, 8)
        // Haptic buzz only when going from not-done to done
        .sensoryFeedback(.success, trigger: isDone) { _, newValue in newValue }
    }
}

#Preview {
    // Build a throwaway in-memory database with one sample habit
    let container = try! ModelContainer(
        for: Habit.self, HabitCompletion.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let habit = Habit(name: "Read 20 minutes", iconName: "book.fill")
    container.mainContext.insert(habit)

    return NavigationStack { HabitDetailView(habit: habit) }
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
