import SwiftUI

struct ConsentView: View {
    var onConsentGiven: () -> Void

    var body: some View {
        ZStack {
            // Trust-focused Background
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.teal.opacity(0.1), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Illustration
                Image("privacy_illustration")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .shadow(color: .blue.opacity(0.2), radius: 20, x: 0, y: 10)

                VStack(spacing: 8) {
                    Text("Your Privacy First")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("We believe your health data should stay yours.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }

                // Glassmorphism Content Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ConsentSection(
                            icon: "doc.text.fill",
                            title: "Data Usage",
                            content: "SmartHeat Tracker uses heart rate, steps, and calories to estimate core temperature locally on your device."
                        )
                        
                        ConsentSection(
                            icon: "server.rack",
                            title: "On-Device Storage",
                            content: "Your data is stored securely in an encrypted on-device database and is never sent to external servers."
                        )
                        
                        ConsentSection(
                            icon: "hand.raised.fill",
                            title: "Full Control",
                            content: "Participation is voluntary. You can withdraw your consent and delete all data at any time from your profile."
                        )
                    }
                    .padding(24)
                }
                .background(.thinMaterial)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .frame(maxHeight: 350)

                Spacer()

                Button(action: {
                    onConsentGiven()
                }) {
                    Text("Grant Consent & Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.blue, .teal], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
}

struct ConsentSection: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.subheadline)
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
            }
            
            Text(content)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}

