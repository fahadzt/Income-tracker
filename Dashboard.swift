import SwiftUI

@main
struct IncomeTrackerDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView(viewModel: DashboardViewModel())
                .preferredColorScheme(.dark)
        }
    }
}

final class DashboardViewModel: ObservableObject {
    @Published var totalBalance: Double
    @Published var monthlySpent: Double
    @Published var monthlyBudget: Double
    @Published var monthName: String

    var remainingBudget: Double {
        max(monthlyBudget - monthlySpent, 0)
    }

    var usageProgress: Double {
        guard monthlyBudget > 0 else { return 0 }
        return min(monthlySpent / monthlyBudget, 1)
    }

    init() {
        // Placeholder realistic data
        self.totalBalance = 18_452.37
        self.monthlySpent = 2_310.42
        self.monthlyBudget = 3_200.00
        self.monthName = "February"
    }

    func simulateUpdate() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
            let spentDelta = Double.random(in: 50...220)
            let newSpent = min(monthlyBudget * 1.1, monthlySpent + spentDelta)
            monthlySpent = newSpent

            let balanceDelta = Double.random(in: -300...150)
            totalBalance = max(2_500, totalBalance + balanceDelta)
        }
    }
}

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel

    @State private var animatedTotal: Double = 0
    @State private var animatedSpent: Double = 0
    @State private var animatedRemaining: Double = 0
    @State private var animatedProgress: Double = 0
    @State private var hasAppeared: Bool = false

    private enum Layout {
        static let cornerRadius: CGFloat = 24
        static let cardSpacing: CGFloat = 16
        static let cardPadding: CGFloat = 20
        static let largeNumberSize: CGFloat = 34
        static let mediumNumberSize: CGFloat = 22
        static let labelSize: CGFloat = 13
        static let sectionSpacing: CGFloat = 18
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 8/255, green: 8/255, blue: 12/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    header
                    totalBalanceCard

                    HStack(spacing: Layout.cardSpacing) {
                        budgetCard
                        spentCard
                    }

                    usageProgressCard

                    Spacer(minLength: 24)
                    refreshHint
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            animateInitialValues()
        }
        .onChange(of: viewModel.totalBalance) { _ in animateNumbers() }
        .onChange(of: viewModel.monthlySpent) { _ in animateNumbers() }
        .onChange(of: viewModel.monthlyBudget) { _ in animateNumbers() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.simulateUpdate()
                } label: {
                    Text("Update")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dashboard")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.96))

            Text("\(viewModel.monthName) overview")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private var totalBalanceCard: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 28/255, green: 35/255, blue: 58/255).opacity(0.95),
                        Color(red: 16/255, green: 18/255, blue: 28/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                ZStack(alignment: .topLeading) {
                    angularAccent

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Total balance")
                                    .font(.system(size: Layout.labelSize, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.55))
                                Text(formattedCurrency(animatedTotal))
                                    .font(.system(size: Layout.largeNumberSize, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .contentTransition(.numericText())
                                    .animation(.spring(response: 0.7, dampingFraction: 0.9), value: animatedTotal)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("Available")
                                    .font(.system(size: Layout.labelSize, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.55))
                                Text(formattedShort(animatedTotal - animatedSpent))
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.88))
                                    .contentTransition(.numericText())
                                    .animation(.spring(response: 0.7, dampingFraction: 0.9), value: animatedSpent)
                            }
                        }

                        Divider()
                            .background(Color.white.opacity(0.06))

                        HStack(spacing: 16) {
                            miniPill(
                                title: "Monthly spent",
                                value: formattedShort(animatedSpent),
                                accent: .red
                            )
                            miniPill(
                                title: "Remaining",
                                value: formattedShort(animatedRemaining),
                                accent: .green
                            )
                        }
                    }
                    .padding(Layout.cardPadding)
                }
            )
            .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 20)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .animation(.spring(response: 0.8, dampingFraction: 0.9), value: animatedTotal)
    }

    private var budgetCard: some View {
        cardBackground {
            VStack(alignment: .leading, spacing: 12) {
                Text("Monthly budget")
                    .font(.system(size: Layout.labelSize, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))

                Text(formattedCurrency(viewModel.monthlyBudget))
                    .font(.system(size: Layout.mediumNumberSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.96))

                Spacer(minLength: 4)

                let usage = viewModel.usageProgress
                let percentage = Int(usage * 100)

                Text("\(percentage)% used")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(progressColor(for: usage).opacity(0.9))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(progressColor(for: usage).opacity(0.14))
                    )
            }
        }
    }

    private var spentCard: some View {
        cardBackground {
            VStack(alignment: .leading, spacing: 12) {
                Text("This month spent")
                    .font(.system(size: Layout.labelSize, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))

                Text(formattedCurrency(animatedSpent))
                    .font(.system(size: Layout.mediumNumberSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.96))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.6, dampingFraction: 0.9), value: animatedSpent)

                Spacer(minLength: 4)

                Text("Last 30 days")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                Text("Average \(formattedShort(animatedSpent / 30)) / day")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var usageProgressCard: some View {
        cardBackground {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly usage")
                            .font(.system(size: Layout.labelSize, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))

                        Text("\(Int(animatedProgress * 100))% of budget")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.7, dampingFraction: 0.9), value: animatedProgress)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Remaining")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))

                        Text(formattedShort(animatedRemaining))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.green.opacity(0.9))
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.7, dampingFraction: 0.9), value: animatedRemaining)
                    }
                }

                progressBar(progress: animatedProgress)
                    .frame(height: 10)

                HStack {
                    Text("0")
                    Spacer()
                    Text(formattedShort(viewModel.monthlyBudget))
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.9), value: animatedProgress)
    }

    private var refreshHint: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                )

            Text("Tap \"Update\" to simulate new activity.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))

            Spacer()
        }
        .padding(.horizontal, 2)
    }

    private var angularAccent: some View {
        AngularGradient(
            gradient: Gradient(colors: [
                Color(red: 0.50, green: 0.80, blue: 1.00).opacity(0.7),
                Color(red: 0.55, green: 0.70, blue: 1.00).opacity(0.4),
                Color(red: 0.40, green: 0.90, blue: 0.90).opacity(0.6),
                Color(red: 0.50, green: 0.80, blue: 1.00).opacity(0.7)
            ]),
            center: .topLeading
        )
        .mask(
            RoundedRectangle(cornerRadius: Layout.cornerRadius * 1.2, style: .continuous)
                .stroke(lineWidth: 1.1)
        )
        .blur(radius: 18)
        .opacity(0.9)
        .padding(-30)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func cardBackground<Content: View>(_ content: () -> Content) -> some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.04),
                        Color.white.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.7)
            )
            .background(
                RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.01))
                    .blur(radius: 6)
            )
            .overlay(
                content()
                    .padding(Layout.cardPadding)
            )
    }

    private func miniPill(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.16),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private func progressBar(progress: Double) -> some View {
        let clamped = min(max(progress, 0), 1)
        let color = progressColor(for: clamped)

        return GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(Color.white.opacity(0.10))

                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.95),
                                color.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * clamped)
                    .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 6)
                    .animation(.spring(response: 0.7, dampingFraction: 0.85), value: clamped)

                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .shadow(color: color.opacity(0.8), radius: 10, x: 0, y: 4)
                    .offset(x: max(min(width * clamped - 4, width - 8), 0))
                    .animation(.spring(response: 0.7, dampingFraction: 0.85), value: clamped)
            }
        }
    }

    // MARK: - Animations

    private func animateInitialValues() {
        animatedTotal = 0
        animatedSpent = 0
        animatedRemaining = 0
        animatedProgress = 0

        withAnimation(.spring(response: 1.0, dampingFraction: 0.9).delay(0.05)) {
            animatedTotal = viewModel.totalBalance
        }
        withAnimation(.spring(response: 1.0, dampingFraction: 0.9).delay(0.12)) {
            animatedSpent = viewModel.monthlySpent
            animatedRemaining = viewModel.remainingBudget
            animatedProgress = viewModel.usageProgress
        }
    }

    private func animateNumbers() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
            animatedTotal = viewModel.totalBalance
            animatedSpent = viewModel.monthlySpent
            animatedRemaining = viewModel.remainingBudget
            animatedProgress = viewModel.usageProgress
        }
    }

    // MARK: - Helpers

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formattedShort(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0

        let suffix: String
        let scaled: Double

        if absValue >= 1_000_000 {
            scaled = absValue / 1_000_000
            suffix = "M"
        } else if absValue >= 1_000 {
            scaled = absValue / 1_000
            suffix = "k"
        } else {
            return formatter.string(from: NSNumber(value: value)) ?? "$0"
        }

        let shortFormatter = NumberFormatter()
        shortFormatter.numberStyle = .decimal
        shortFormatter.maximumFractionDigits = scaled < 10 ? 1 : 0
        shortFormatter.minimumFractionDigits = 0

        let number = shortFormatter.string(from: NSNumber(value: scaled)) ?? "\(scaled)"
        return "\(sign)$\(number)\(suffix)"
    }

    private func progressColor(for progress: Double) -> Color {
        switch progress {
        case 0..<0.5:
            return Color.green
        case 0.5..<0.85:
            return Color.yellow
        default:
            return Color.red
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DashboardView(viewModel: DashboardViewModel())
                .preferredColorScheme(.dark)
        }
    }
}

