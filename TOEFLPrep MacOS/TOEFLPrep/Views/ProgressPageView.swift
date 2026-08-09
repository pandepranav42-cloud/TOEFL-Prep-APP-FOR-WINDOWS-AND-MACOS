import SwiftUI

struct ProgressPageView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(eyebrow: "ALL TIME",
                             title: L10n.t("Progress", app.language),
                             theme: app.theme)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4),
                          spacing: 14) {
                    StatCard(value: "\(app.learnedCount)", label: "Words learned", theme: app.theme)
                    StatCard(value: "\(app.remainingCount)", label: "Remaining", theme: app.theme)
                    StatCard(value: "\(app.accuracyPercent)%", label: "Quiz accuracy", theme: app.theme)
                    StatCard(value: "\(app.currentStreak)", label: "Current streak", theme: app.theme)

                    StatCard(value: "\(app.bestStreak)", label: "Longest streak", theme: app.theme)
                    StatCard(value: "\(app.studyMinutes)m", label: "Study time", theme: app.theme)
                    StatCard(value: "\(app.reviewsThisWeek)", label: "Reviews this week", theme: app.theme)
                    StatCard(value: "\(app.reviewsThisMonth)", label: "Reviews this month", theme: app.theme)
                }

                dailyReviewsCard

                leitnerDistribution

                Text("Box 1 words come back every session. Words reach box 4 after repeated correct recall and count as learned.")
                    .font(.system(size: 12))
                    .foregroundStyle(app.theme.ink3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 26)
        }
    }

    // MARK: - Daily reviews chart

    private var dailyReviewsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text("DAILY REVIEWS")
                    .font(.system(size: 10, weight: .medium)).tracking(1.6)
                    .foregroundStyle(app.theme.ink3)
                Rectangle().fill(app.theme.hairlineSoft).frame(height: 1)
            }
            let data = app.weekReviews
            let maxV = max(data.map { $0.count }.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 24) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, entry in
                    VStack(spacing: 8) {
                        Text(entry.count > 0 ? "\(entry.count)" : "")
                            .font(AppFont.mono(10))
                            .foregroundStyle(app.theme.ink3)
                        Capsule()
                            .fill(LinearGradient(colors: [app.theme.accent, app.theme.accentAlt],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: 30,
                                   height: max(4, CGFloat(entry.count) / CGFloat(maxV) * 140))
                        Text(entry.day)
                            .font(AppFont.mono(10, weight: .medium))
                            .foregroundStyle(app.theme.ink3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 190)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(app.theme, .panel, radius: 16)
    }

    // MARK: - Leitner distribution row

    private var leitnerDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("LEITNER DISTRIBUTION")
                    .font(.system(size: 10, weight: .medium)).tracking(1.6)
                    .foregroundStyle(app.theme.ink3)
                Rectangle().fill(app.theme.hairlineSoft).frame(height: 1)
            }
            HStack(spacing: 12) {
                let counts = app.leitnerDistribution
                ForEach(0..<5, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text("\(counts[i])")
                            .font(AppFont.mono(24, weight: .semibold))
                            .foregroundStyle(boxColor(i + 1))
                        Text("BOX \(i + 1)")
                            .font(.system(size: 10, weight: .medium)).tracking(1.4)
                            .foregroundStyle(app.theme.ink3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .glass(app.theme, .card, radius: 14)
                }
            }
        }
    }

    private func boxColor(_ box: Int) -> Color {
        switch box {
        case 1: return Color(hex: "FB7185")
        case 2: return Color(hex: "FB923C")
        case 3: return Color(hex: "FBBF24")
        case 4: return Color(hex: "22D3EE")
        default: return Color(hex: "4ADE80")
        }
    }
}
