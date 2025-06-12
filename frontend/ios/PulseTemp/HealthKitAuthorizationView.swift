import SwiftUI
import HealthKit

struct HealthKitAuthorizationView: View {
    var onAuthorizationSuccess: () -> Void

    @State private var isAccessDenied = false

    var body: some View {
        if isAccessDenied {
            HealthAccessDeniedView()
        } else {
            VStack(spacing: 20) {
                Text("SmartHeat Tracker Needs Health Access")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("We use your heart rate and activity data to estimate your core body temperature and improve your health insights.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Allow Health Access") {
                    requestHealthKitAccess()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
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

