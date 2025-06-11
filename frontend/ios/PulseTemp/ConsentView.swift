import SwiftUI

struct ConsentView: View {
    var onConsentGiven: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to SmartHeat Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("📋 How We Use Your Data")
                        .font(.headline)

                    Text("""
SmartHeat Tracker uses your health data from Apple HealthKit — including heart rate, steps walked, calories burned, and distance — to estimate your core body temperature using scientifically validated methods.

We securely store this data on-device using SQLite. Your data is never sent to external servers and is only used to personalize your experience and enable research participation if you opt-in.
""")

                    Text("🔐 Your Privacy Matters")
                        .font(.headline)

                    Text("""
Participation in any research study is completely voluntary. You can withdraw your consent at any time from the Profile tab. We comply with all institutional and ethical standards, including PII/PHI handling rules.
""")
                }
                .padding()
            }

            Button(action: {
                onConsentGiven()
            }) {
                Text("I Agree")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

