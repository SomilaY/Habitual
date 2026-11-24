import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query private var unlocked: [UnlockedAchievement]

    // Tapping an unlocked medal replays its unlock sequence (handy for testing, fun to show off)
    @State private var replaying: Achievement?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    // id -> date it was unlocked
    private var unlockDates: [String: Date] {
        Dictionary(uniqueKeysWithValues: unlocked.map { ($0.achievementID, $0.unlockedAt) })
    }

    // Unlocked achievements, rarest first, then newest first. Used for the showcase.
    private var showcase: [Achievement] {
        let dates = unlockDates
        return AchievementCatalog.all
            .filter { dates[$0.id] != nil }
            .sorted {
                if $0.tier != $1.tier { return $0.tier > $1.tier }
                return (dates[$0.id] ?? .distantPast) > (dates[$1.id] ?? .distantPast)
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        summaryCard

                        if !showcase.isEmpty {
                            showcaseRow
                        }

                        // One section per tier, rarest at the top
                        ForEach(AchievementTier.allCases.reversed(), id: \.self) { tier in
                            tierSection(tier)
                        }

                        Text("Tap an unlocked medal to replay its unlock.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Trophies")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(item: $replaying) { achievement in
            AchievementUnlockOverlay(achievement: achievement) {
                replaying = nil
            }
        }
    }

    // MARK: - Summary
    private var summaryCard: some View {
        let total = AchievementCatalog.all.count
        let count = unlocked.count
        let dates = unlockDates

        return GlassCard {
            HStack(spacing: 20) {
                ZStack {
                    ProgressRing(progress: total == 0 ? 0 : Double(count) / Double(total),
                                 lineWidth: 8,
                                 colors: [Theme.gold, Theme.cyan])
                    Text("\(count)/\(total)")
                        .font(.subheadline.weight(.bold))
                }
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your collection")
                        .font(.headline)
                    // Small count per tier, e.g. "Gold 3/4"
                    ForEach(AchievementTier.allCases, id: \.self) { tier in
                        let all = AchievementCatalog.all.filter { $0.tier == tier }
                        let got = all.filter { dates[$0.id] != nil }.count
                        HStack(spacing: 6) {
                            Circle().fill(tier.glow).frame(width: 8, height: 8)
                            Text("\(tier.title) \(got)/\(all.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Showcase (big shiny row)
    private var showcaseRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Showcase")
                .font(.title3.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(showcase.prefix(6)) { achievement in
                        VStack(spacing: 10) {
                            MedalView(tier: achievement.tier, icon: achievement.icon, size: 110, shine: true)
                            Text(achievement.title)
                                .font(.caption.weight(.semibold))
                        }
                        .onTapGesture { replaying = achievement }
                    }
                }
                .padding(.vertical, 16)   // room for the glow
                .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Tier section
    private func tierSection(_ tier: AchievementTier) -> some View {
        let items = AchievementCatalog.all.filter { $0.tier == tier }
        let dates = unlockDates

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle().fill(tier.glow).frame(width: 10, height: 10)
                Text(tier.title)
                    .font(.title3.bold())
            }

            GlassCard {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(items) { achievement in
                        cell(achievement, unlockedOn: dates[achievement.id])
                    }
                }
            }
        }
    }

    private func cell(_ achievement: Achievement, unlockedOn date: Date?) -> some View {
        let isUnlocked = date != nil
        let value = achievement.measure(habits)
        let progress = min(1, Double(value) / Double(achievement.target))

        return VStack(spacing: 8) {
            MedalView(tier: achievement.tier,
                      icon: achievement.icon,
                      size: 76,
                      locked: !isUnlocked,
                      progress: progress)

            Text(achievement.title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(isUnlocked
                 ? (date ?? Date()).formatted(date: .abbreviated, time: .omitted)
                 : "\(min(value, achievement.target))/\(achievement.target)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            if isUnlocked { replaying = achievement }
        }
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, UnlockedAchievement.self], inMemory: true)
        .preferredColorScheme(.dark)
}
