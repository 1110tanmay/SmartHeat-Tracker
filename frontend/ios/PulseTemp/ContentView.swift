import SwiftUI

struct ContentView: View {
    @State private var hasRequestedHealthKit = false
    @State private var profileImageOpacity: Double = 0.0 // 📌 New for animation

    var body: some View {
        TabView {
            SummaryView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Summary")
                }

            TrendsView()
                .tabItem {
                    Image(systemName: "waveform.path.ecg")
                    Text("Trends")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
        .onAppear {
            #if !TARGET_INTERFACE_BUILDER
            guard !hasRequestedHealthKit else { return }
            hasRequestedHealthKit = true

            HealthKitManager.shared.requestAuthorization { success, error in
                if success {
                    print("✅ HealthKit authorization granted")
                } else {
                    print("❌ HealthKit authorization failed: \(String(describing: error))")
                }
            }
            #endif
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Group {
                    if let data = try? Data(contentsOf: getProfilePhotoURL()),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .opacity(profileImageOpacity)
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.6)) {
                                    profileImageOpacity = 1.0
                                }
                            }
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    func getProfilePhotoURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_photo.png")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

