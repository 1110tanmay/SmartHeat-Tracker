import SwiftUI

struct SignUpView: View {
    var onSubmit: () -> Void // added to include onboarding flow
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var selectedActivityLevel = 0
    @State private var showAlert = false
    @State private var showValidationError = false

    let activityLevels = [
        "0 - No physical activity",
        "1 - Avoid exertion (elevator, car)",
        "2 - Light recreational activity",
        "3 - 10–60 min/week",
        "4 - >1 hour/week",
        "5 - <30 min/week of intense activity",
        "6 - 1–5 miles/week or 30–60 min",
        "7 - >10 miles/week or >3 hours"
    ]

    var body: some View {
        ZStack {
            // Energized Background
            LinearGradient(
                colors: [Color.orange.opacity(0.15), Color.pink.opacity(0.1), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Illustration
                    Image("profile_illustration")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .scaleEffect(1.1)
                        .padding(.top, 40)
                    
                    VStack(spacing: 12) {
                        Text("Create Your Profile")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                        
                        Text("Tell us a bit about yourself to personalize your heat tracking.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Input Fields Card
                    VStack(spacing: 20) {
                        CustomSignUpField(label: "FULL NAME", placeholder: "Enter your name", text: $name, icon: "person.fill")
                        
                        HStack(spacing: 16) {
                            CustomSignUpField(label: "WEIGHT (kg)", placeholder: "0", text: $weight, icon: "scalemass.fill", keyboardType: .decimalPad)
                            CustomSignUpField(label: "HEIGHT (cm)", placeholder: "0", text: $height, icon: "ruler.fill", keyboardType: .decimalPad)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GENERAL ACTIVITY LEVEL")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                            
                            Picker("Activity Level", selection: $selectedActivityLevel) {
                                ForEach(0..<activityLevels.count, id: \.self) { index in
                                    Text(activityLevels[index].prefix(2)).tag(index)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Text(activityLevels[selectedActivityLevel])
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    Button(action: {
                        if isFormValid() {
                            saveData()
                            showAlert = true
                        } else {
                            showValidationError = true
                        }
                    }) {
                        Text("Complete Setup")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(20)
                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Success", isPresented: $showAlert) {
            Button("Let's Start") {
                onSubmit()
                dismiss()
            }
        } message: {
            Text("Your profile is ready! Welcome to Smart Heat Tracker.")
        }
        .alert("Missing Information", isPresented: $showValidationError) {
            Button("Fix it", role: .cancel) { }
        } message: {
            Text("Please ensure your name, weight, and height are entered correctly.")
        }
    }
    // MARK: - Helpers

    func isFormValid() -> Bool {
        !name.isEmpty && !weight.isEmpty && !height.isEmpty
    }

    func saveData() {
        let profile = UserProfile(
            name: name,
            dob: Date(),  // Can be set later in ProfileView
            sex: "Male",
            ethnicity: "White",
            profession: "Employed for wages",
            height: Double(height) ?? 0,
            weight: Double(weight) ?? 0,
            distanceUnit: "km",
            temperatureUnit: "°C",
            activityLevel: selectedActivityLevel
        )
        DatabaseManager.shared.insertOrUpdateUserProfile(profile)
        print("✅ Profile saved with activity level: \(selectedActivityLevel)")
    }
}

struct CustomSignUpField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .font(.subheadline)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(.system(.body, design: .rounded))
                    .keyboardType(keyboardType)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
    }
}

