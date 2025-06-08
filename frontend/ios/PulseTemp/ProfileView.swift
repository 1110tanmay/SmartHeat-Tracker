import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var name: String = ""
    @State private var dob: Date = Date()
    @State private var sex: String = "Male"
    @State private var ethnicity: String = "White"
    @State private var profession: String = "Employed for wages"
    @State private var weight: String = ""
    @State private var height: String = ""

    @State private var isEditing: Bool = false
    @State private var isDataShared: Bool = false

    @State private var selectedImage: UIImage? = nil
    @State private var isPickerPresented = false
    @State private var showResetAlert = false

    @AppStorage("temperatureUnit") private var temperatureUnit: String = "°C"
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"

    let sexOptions = ["Male", "Female", "Other"]
    let ethnicityOptions = [
        "American Indian/Alaska Native",
        "Asian",
        "Black",
        "Native Hawaiian/Pacific Islander",
        "White",
        "Hispanic/Latinx/Spanish",
        "Other"
    ]
    let professionOptions = [
        "Employed for wages",
        "Self-employed",
        "Out of work and looking for work",
        "Out of work but not currently looking for work",
        "A homemaker",
        "A student",
        "Military",
        "Retired",
        "Unable to work",
        "Other"
    ]
    let tempUnits = ["°C", "°F"]
    let distanceUnits = ["km", "miles"]

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    var body: some View {
        NavigationView {
            Form {
                // 📸 Profile Photo Section
                Section {
                    VStack {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Text("Add Photo")
                                        .foregroundColor(.blue)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .onTapGesture {
                        isPickerPresented = true
                    }
                }

                // 📌 Personal Info Section
                Section(header: Text("Personal Information")) {
                    EditableField(label: "Name", value: $name, isEditing: isEditing)

                    if isEditing {
                        DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                    } else {
                        HStack {
                            Text("Date of Birth").font(.headline)
                            Spacer()
                            Text(dateFormatter.string(from: dob))
                        }
                    }

                    Picker("Sex", selection: $sex) {
                        ForEach(sexOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(!isEditing)

                    Picker("Ethnicity", selection: $ethnicity) {
                        ForEach(ethnicityOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .disabled(!isEditing)

                    Picker("Profession", selection: $profession) {
                        ForEach(professionOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .disabled(!isEditing)

                    EditableField(label: "Weight (kg)", value: $weight, keyboardType: .numberPad, isEditing: isEditing)
                    EditableField(label: "Height (cm)", value: $height, keyboardType: .numberPad, isEditing: isEditing)
                }

                // 📌 Units Section
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
                    Toggle("Share My Data for Research", isOn: $isDataShared)
                        .disabled(!isEditing)

                    Button(action: {
                        showResetAlert = true
                    }) {
                        Text("Reset Profile")
                            .foregroundColor(.red)
                    }
                }

                if isEditing {
                    Button(action: {
                        saveProfile()
                        isEditing = false
                    }) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                Button(isEditing ? "Cancel" : "Edit") {
                    isEditing.toggle()
                }
            }
            .onAppear {
                loadProfile()
            }
            .sheet(isPresented: $isPickerPresented) {
                PhotoPicker(selectedImage: $selectedImage)
            }
            .alert(isPresented: $showResetAlert) {
                Alert(
                    title: Text("Reset Profile"),
                    message: Text("Are you sure you want to reset your profile?"),
                    primaryButton: .destructive(Text("Reset")) {
                        resetProfile()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: Save, Load, Reset Functions

    func saveProfile() {
        guard let weightDouble = Double(weight),
              let heightDouble = Double(height) else {
            print("Invalid input, could not save profile.")
            return
        }

        let profile = UserProfile(
            name: name,
            dob: dob,
            sex: sex,
            ethnicity: ethnicity,
            profession: profession,
            height: heightDouble,
            weight: weightDouble,
            distanceUnit: distanceUnit,
            temperatureUnit: temperatureUnit
        )

        DatabaseManager.shared.insertOrUpdateUserProfile(profile)
        saveProfileImage()
        print("Profile Saved to Database: \(profile)")
    }

    func loadProfile() {
        if let profile = DatabaseManager.shared.fetchUserProfile() {
            name = profile.name
            dob = profile.dob
            sex = profile.sex
            ethnicity = profile.ethnicity
            profession = profile.profession
            weight = "\(profile.weight)"
            height = "\(profile.height)"
            distanceUnit = profile.distanceUnit
            temperatureUnit = profile.temperatureUnit
        }
        loadProfileImage()
    }

    func resetProfile() {
        name = ""
        dob = Date()
        sex = "Male"
        ethnicity = "White"
        profession = "Employed for wages"
        weight = ""
        height = ""
        temperatureUnit = "°C"
        distanceUnit = "km"
        isDataShared = false
        selectedImage = nil
        saveProfile()
        deleteProfileImage()
    }

    // MARK: - Image Saving/Loading Helpers

    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func saveProfileImage() {
        guard let selectedImage = selectedImage else { return }
        if let data = selectedImage.jpegData(compressionQuality: 0.8) {
            let url = getDocumentsDirectory().appendingPathComponent("profile_photo.png")
            try? data.write(to: url)
            print("Profile photo saved.")
        }
    }

    func loadProfileImage() {
        let url = getDocumentsDirectory().appendingPathComponent("profile_photo.png")
        if FileManager.default.fileExists(atPath: url.path) {
            if let data = try? Data(contentsOf: url) {
                selectedImage = UIImage(data: data)
                print("Profile photo loaded.")
            }
        }
    }

    func deleteProfileImage() {
        let url = getDocumentsDirectory().appendingPathComponent("profile_photo.png")
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
            print("Profile photo deleted.")
        }
    }
}

// MARK: Reusable Editable Field
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
                .disabled(!isEditing)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: Photo Picker using PHPickerViewController
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self.parent.selectedImage = uiImage
                        ProfileImageManager.shared.save(image: uiImage)
                    }
                }
            }
        }
    }
}

