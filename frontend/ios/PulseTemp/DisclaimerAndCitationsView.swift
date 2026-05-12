import SwiftUI

struct DisclaimerAndCitationsView: View {
    private static let healthKitDocURL = URL(string: "https://developer.apple.com/documentation/healthkit")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Disclaimer")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)

                    Text(
                        "Smart Heat Tracker is not a medical device and is not intended to diagnose, treat, cure, or prevent any disease. Values shown are estimates for informational and wellness tracking purposes only."
                    )
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("References")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                  
                  citationBlock(number: 1, 
                                text: "Looney DP, Buller MJ, Gribok A, et al. Validation of an algorithm for non-invasive estimation of core body temperature from heart rate in firefighters. Physiological Measurement. 2018."
                  )

                    citationBlock(
                        number: 2,
                        text: "Buller MJ, Tharion WJ, Cheuvront SN, Montain SJ, Kenefick RW, Castellani J, et al. Estimation of human core temperature from sequential heart rate observations. Physiological Measurement. 2013."
                    )

                    citationBlock(
                        number: 3,
                        text: "ISO 9886: Ergonomics — Evaluation of thermal strain by physiological measurements."
                    )

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("4.")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                        Link("Apple HealthKit Documentation", destination: Self.healthKitDocURL)
                            .font(.system(.subheadline, design: .rounded))
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Disclaimer & References")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func citationBlock(number: Int, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(number).")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
            Text(text)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}
