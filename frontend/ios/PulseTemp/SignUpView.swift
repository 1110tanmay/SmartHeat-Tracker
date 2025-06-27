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
      print("👀 SignUpView appeared")
       return NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Name", text: $name)

                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)

                    TextField("Height (cm)", text: $height)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Activity Questionnaire")) {
                    Picker("General Activity Level", selection: $selectedActivityLevel) {
                        ForEach(0..<activityLevels.count, id: \.self) { index in
                            Text(activityLevels[index]).tag(index)
                        }
                    }
                }

              Section {
                HStack {
                  Spacer()
                  Button(action: {
                    if isFormValid() {
                      saveData()
                      showAlert = true
                    } else {
                      showValidationError = true
                    }
                  }) {
                    Text("Submit")
                      .font(.headline)
                      .foregroundColor(.white)
                      .frame(maxWidth: .infinity)
                      .padding()
                      .background(Color.accentColor)
                      .cornerRadius(12)
                      .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                  }
                  .padding(.horizontal, 16)
                  Spacer()
                }
                .listRowBackground(Color.clear)
              }

            }
            .navigationTitle("Sign Up")
            .alert("Success", isPresented: $showAlert) {
                Button("Continue") {
                  print("✅ Continue tapped, calling onSubmit")
                    onSubmit()  // ✅ Transition onboarding after alert is dismissed
                    dismiss()
                }
            } message: {
                Text("Your data has been saved successfully.")
            }
            .alert("Please fill all required fields.", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            }
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

