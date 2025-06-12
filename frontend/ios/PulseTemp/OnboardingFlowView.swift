import SwiftUI
import HealthKit

struct OnboardingFlowView: View {
    @AppStorage("isHealthKitAuthorized") private var isHealthKitAuthorized = false
    @AppStorage("didAcceptConsent") private var didAcceptConsent = false
    @AppStorage("didFinishSignUp") private var didFinishSignUp = false

    var body: some View {
        if !isHealthKitAuthorized {
            HealthKitAuthorizationView {
                isHealthKitAuthorized = true
            }
        } else if !didAcceptConsent {
            ConsentView {
                didAcceptConsent = true
            }
        } else if !didFinishSignUp {
            SignUpView {
                didFinishSignUp = true
            }
        } else {
            ContentView()
                .environmentObject(HealthKitManager.shared)
        }
    }
}

