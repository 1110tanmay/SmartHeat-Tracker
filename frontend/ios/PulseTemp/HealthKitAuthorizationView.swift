import SwiftUI
import HealthKit

struct HealthKitAuthorizationView: View {
    var onAuthorizationSuccess: () -> Void

    @State private var isAccessDenied = false

    var body: some View {
        if isAccessDenied {
            HealthAccessDeniedView()
        } else {
            ZStack {
                // Premium Background
                LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Illustration
                    Image("health_illustration")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 220)
                        .shadow(color: .red.opacity(0.2), radius: 20, x: 0, y: 10)

                    VStack(spacing: 12) {
                        Text("Health Connectivity")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                        
                        Text("Smart Heat Tracker syncs with Apple Health to provide real-time core temperature estimates.")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Value Props
                    VStack(alignment: .leading, spacing: 20) {
                        OnboardingFeatureRow(icon: "heart.fill", title: "Heart Rate", subtitle: "Essential for core body temp estimation.", color: .red)
                        OnboardingFeatureRow(icon: "figure.walk", title: "Activity", subtitle: "Tracking exertion levels automatically.", color: .orange)
                        OnboardingFeatureRow(icon: "lock.shield.fill", title: "Private", subtitle: "Data stays securely on your device.", color: .blue)
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    Button(action: {
                        requestHealthKitAccess()
                    }) {
                        Text("Allow Health Access")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(16)
                            .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    private func requestHealthKitAccess() {
        let healthStore = HKHealthStore()

        guard HKHealthStore.isHealthDataAvailable() else {
            isAccessDenied = true
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]

        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            DispatchQueue.main.async {
                if success {
                    onAuthorizationSuccess()
                } else {
                    isAccessDenied = true
                }
            }
        }
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}

