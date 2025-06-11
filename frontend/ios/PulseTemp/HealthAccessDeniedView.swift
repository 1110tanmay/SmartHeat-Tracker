import SwiftUI

struct HealthAccessDeniedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Health Access Required")
                .font(.title)
                .fontWeight(.bold)
            Text("To use SmartHeat Tracker, please enable Health access in Settings > Privacy > Health.")
                .multilineTextAlignment(.center)
                .padding()

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

