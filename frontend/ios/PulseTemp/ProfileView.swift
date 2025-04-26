import SwiftUI

struct ProfileView: View {
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var sex: String = "Male"
    @State private var weight: String = ""
    @State private var height: String = ""

    @AppStorage("temperatureUnit") private var temperatureUnit: String = "°C"
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"

    @State private var isEditing: Bool = false
    @State private var isDataShared: Bool = false

    let sexOptions = ["Male", "Female", "Other"]
    let tempUnits = ["°C", "°F"]
    let distanceUnits = ["km", "miles"]

    var body: some View {
        NavigationView {
            Form {
                // 📌 Personal Information Section
                Section(header: Text("Personal Information")) {
                    EditableField(label: "Name", value: $name, isEditing: isEditing)
                    EditableField(label: "Age", value: $age, keyboardType: .numberPad, isEditing: isEditing)

                    Picker("Sex", selection: $sex) {
                        ForEach(sexOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(!isEditing) // 📌 Disable picker too

                    EditableField(label: "Weight (kg)", value: $weight, keyboardType: .numberPad, isEditing: isEditing)
                    EditableField(label: "Height (cm)", value: $height, keyboardType: .numberPad, isEditing: isEditing)
                }

                // 📌 Unit Preferences Section
                Section(header: Text("Unit Preferences")) {
                    Picker("Temperature Unit", selection: $temperatureUnit) {
                        ForEach(tempUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(!isEditing)

                    Picker("Distance Unit", selection: $distanceUnit) {
                        ForEach(distanceUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(!isEditing)
                }

                // 📌 Data Sharing Section
                Section(header: Text("Data Sharing")) {
                    Button(action: {
                        isDataShared.toggle()
                    }) {
                        Text(isDataShared ? "Data Shared for Research" : "Share My Data for Research")
                            .foregroundColor(.blue)
                    }
                    .disabled(!isEditing)

                    Button(action: {
                        resetProfile()
                    }) {
                        Text("Reset Data")
                            .foregroundColor(.red)
                    }
                    .disabled(!isEditing)
                }

                // 📌 Save Button
                if isEditing {
                    Button(action: {
                        saveProfile()
                        isEditing = false
                    }) {
                        Text("Save")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                Button(isEditing ? "Cancel" : "Edit") {
                    isEditing.toggle()
                    dismissKeyboard()
                }
            }
            .onAppear {
                loadProfile()
            }
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    dismissKeyboard()
                }
            ) // 📌 Tap anywhere to dismiss keyboard
        }
    }

    // 📌 Save Profile to Database
    func saveProfile() {
        guard let ageInt = Int(age),
              let weightDouble = Double(weight),
              let heightDouble = Double(height) else {
            print("Invalid input, could not save profile.")
            return
        }

        let profile = UserProfile(
            name: name,
            age: ageInt,
            sex: sex,
            height: heightDouble,
            weight: weightDouble,
            distanceUnit: distanceUnit,
            temperatureUnit: temperatureUnit
        )

        DatabaseManager.shared.insertOrUpdateUserProfile(profile)
        print("Profile Saved to Database: \(profile)")

        dismissKeyboard()
    }

    // 📌 Load Profile from Database
    func loadProfile() {
        if let profile = DatabaseManager.shared.fetchUserProfile() {
            name = profile.name
            age = "\(profile.age)"
            sex = profile.sex
            weight = "\(profile.weight)"
            height = "\(profile.height)"
            distanceUnit = profile.distanceUnit
            temperatureUnit = profile.temperatureUnit
            print("Profile Loaded from Database: \(profile)")
        } else {
            print("No saved profile found, using defaults.")
        }
    }

    // 📌 Reset Profile to Defaults
    func resetProfile() {
        name = "John Doe"
        age = "25"
        sex = "Male"
        weight = "70"
        height = "175"
        temperatureUnit = "°C"
        distanceUnit = "km"
        isDataShared = false
        saveProfile()
        print("Profile Reset to Defaults and Saved.")
    }

    // 📌 Helper to Dismiss Keyboard
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 📌 Reusable Editable Field Component
struct EditableField: View {
    let label: String
    @Binding var value: String
    var keyboardType: UIKeyboardType = .default
    var isEditing: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
            TextField(label, text: $value)
                .keyboardType(keyboardType)
                .multilineTextAlignment(.trailing)
                .disabled(!isEditing) // 📌 Disable textfield unless editing
        }
    }
}

// 📌 Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

