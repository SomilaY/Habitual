import SwiftUI
import Charts

// MARK: - The "draw-on" effect
// Analogy: a curtain being pulled aside. The chart is already complete behind it,
// and we reveal it from left to right by growing a mask.
extension View {
    func drawOn(_ progress: Double) -> some View {
        self.mask {
            Rectangle()
                .scaleEffect(x: progress, anchor: .leading)   // 0 = fully hidden, 1 = fully shown
        }
    }
}

// MARK: - Shared card frame
// Every chart sits in the same glass card with an icon and a title.
struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(tint.opacity(0.18)))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title).font(.headline)
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                content()
            }
        }
    }
}

// MARK: - Small metric tile ("goal performance")
struct MetricTile: View {
    let title: String
    let value: Double          // the number to display (we pass it already scaled by the animation)
    var suffix: String = ""
    let icon: String
    let tint: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).foregroundStyle(tint)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    CountingText(value: value)          // the odometer from Step 3
                        .font(.title.bold())
                    if !suffix.isEmpty {
                        Text(suffix)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Consistency chart
struct ConsistencyCard: View {
    let daily: [DayPoint]      // the jumpy raw line
    let trend: [DayPoint]      // the smooth 7-day average
    let progress: Double       // 0...1, drives the draw-on animation

    // Set automatically by Charts while the finger is dragging across the chart
    @State private var selectedDate: Date?

    // Which point is closest to the finger?
    private var selectedIndex: Int? {
        guard let selected = selectedDate else { return nil }
        return trend.indices.min {
            abs(trend[$0].date.timeIntervalSince(selected)) < abs(trend[$1].date.timeIntervalSince(selected))
        }
    }

    var body: some View {
        ChartCard(title: "Consistency",
                  subtitle: "Daily completion with 7-day trend",
                  icon: "chart.line.uptrend.xyaxis",
                  tint: Theme.cyan) {

            Chart {
                // Faint raw daily line
                ForEach(daily) { point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Daily", point.value),
                        series: .value("Series", "Daily")   // keeps this line separate from the trend line
                    )
                    .foregroundStyle(Color.white.opacity(0.25))
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }

                // Bold trend line with a gradient fill underneath
                ForEach(trend) { point in
                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Trend", point.value),
                        series: .value("Series", "Trend")
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.indigo.opacity(0.35), .clear],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .interpolationMethod(.catmullRom)       // smooth curve

                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Trend", point.value),
                        series: .value("Series", "Trend")
                    )
                    .foregroundStyle(Theme.primaryGradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                // The "scrubber": a vertical line, a dot, and a floating label
                if let i = selectedIndex, daily.indices.contains(i) {
                    RuleMark(x: .value("Selected", trend[i].date, unit: .day))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .annotation(position: .top, spacing: 6,
                                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                            tooltip(date: trend[i].date,
                                    headline: "\(Int(trend[i].value))% avg",
                                    detail: "That day: \(Int(daily[i].value))%")
                        }

                    PointMark(x: .value("Selected", trend[i].date, unit: .day),
                              y: .value("Trend", trend[i].value))
                        .foregroundStyle(Theme.cyan)
                        .symbolSize(80)
                }
            }
            .chartYScale(domain: 0...100)
            .chartXSelection(value: $selectedDate)           // enables drag-to-explore
            .chartXAxis { dateAxis }
            .chartYAxis { percentAxis }
            .frame(height: 210)
            .drawOn(progress)
            .sensoryFeedback(.selection, trigger: selectedIndex)
        }
    }
}

// MARK: - Streak growth chart
struct StreakCard: View {
    let points: [DayPoint]
    let progress: Double

    @State private var selectedDate: Date?

    private var selectedIndex: Int? {
        guard let selected = selectedDate else { return nil }
        return points.indices.min {
            abs(points[$0].date.timeIntervalSince(selected)) < abs(points[$1].date.timeIntervalSince(selected))
        }
    }

    // Leave a little headroom above the tallest streak
    private var yMax: Double { max(5, (points.map(\.value).max() ?? 0) + 1) }

    var body: some View {
        ChartCard(title: "Streak growth",
                  subtitle: "Your best running streak over time",
                  icon: "flame.fill",
                  tint: Theme.gold) {

            Chart {
                ForEach(points) { point in
                    AreaMark(x: .value("Day", point.date, unit: .day),
                             y: .value("Streak", point.value))
                        .foregroundStyle(
                            LinearGradient(colors: [Theme.emerald.opacity(0.4), .clear],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        // stepEnd = the line moves in clean steps (a streak is whole days, not a slope)
                        .interpolationMethod(.stepEnd)

                    LineMark(x: .value("Day", point.date, unit: .day),
                             y: .value("Streak", point.value))
                        .foregroundStyle(Theme.successGradient)
                        .interpolationMethod(.stepEnd)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                if let i = selectedIndex {
                    RuleMark(x: .value("Selected", points[i].date, unit: .day))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .annotation(position: .top, spacing: 6,
                                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                            tooltip(date: points[i].date,
                                    headline: "\(Int(points[i].value)) day streak",
                                    detail: nil)
                        }
                }
            }
            .chartYScale(domain: 0...yMax)
            .chartXSelection(value: $selectedDate)
            .chartXAxis { dateAxis }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel().foregroundStyle(.secondary)
                }
            }
            .frame(height: 180)
            .drawOn(progress)
            .sensoryFeedback(.selection, trigger: selectedIndex)
        }
    }
}

// MARK: - Completion rates (one bar per habit)
struct RatesCard: View {
    let rates: [HabitRate]
    let progress: Double

    var body: some View {
        ChartCard(title: "Completion rates",
                  subtitle: "How often you showed up for each habit",
                  icon: "target",
                  tint: Theme.indigo) {

            Chart(rates) { item in
                BarMark(
                    // Multiplying by progress makes each bar GROW from zero
                    x: .value("Rate", item.rate * progress),
                    y: .value("Habit", item.name)
                )
                .foregroundStyle(Color(hex: item.colorHex).gradient)
                .cornerRadius(6)
                .annotation(position: .trailing) {
                    Text("\(Int(item.rate))%")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .opacity(progress)
                }
            }
            // Domain goes past 100 so the "100%" label has room and doesn't get clipped
            .chartXScale(domain: 0...125)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { AxisValueLabel().foregroundStyle(.primary) }
            }
            // Height grows with the number of habits
            .frame(height: CGFloat(max(1, rates.count)) * 44 + 8)
        }
    }
}

// MARK: - Shared chart bits

// The floating bubble shown while dragging across a chart
private func tooltip(date: Date, headline: String, detail: String?) -> some View {
    VStack(spacing: 2) {
        Text(date.formatted(.dateTime.day().month(.abbreviated)))
            .font(.caption2)
            .foregroundStyle(.secondary)
        Text(headline)
            .font(.caption.weight(.bold))
        if let detail {
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
}

// Bottom axis: a few date labels, no heavy gridlines
private var dateAxis: some AxisContent {
    AxisMarks(values: .automatic(desiredCount: 4)) {
        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            .foregroundStyle(.secondary)
    }
}

// Left axis: 0%, 50%, 100% with faint gridlines
private var percentAxis: some AxisContent {
    AxisMarks(position: .leading, values: [0, 50, 100]) { value in
        AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
        AxisValueLabel {
            if let v = value.as(Int.self) {
                Text("\(v)%").foregroundStyle(.secondary)
            }
        }
    }
}
