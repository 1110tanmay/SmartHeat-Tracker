import SwiftUI
import Charts

struct HealthMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isLarge: Bool = false
    var trailingView: AnyView? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                // Icon Circle with Premium Gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.15), color.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(.secondary)
                        .opacity(0.6)

                    Text(value)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.secondary.opacity(0.3))
            }

            // Optional Trailing View (Chart, etc.)
            if let trailingView = trailingView {
                trailingView
                    .frame(height: isLarge ? 80 : 60)
                    .transition(.opacity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: isLarge ? 160 : nil)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.03), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 10)
        .padding(.horizontal, 4)
    }
}

