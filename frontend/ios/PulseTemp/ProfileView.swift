import SwiftUI
import PhotosUI
import MessageUI

struct ProfileView: View {
    @State private var name: String = ""
    @State private var dob: Date = Date()
    @State private var sex: String = "Male"
    @State private var ethnicity: String = "White"
    @State private var profession: String = "Employed for wages"
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var activityLevel: Int = 0

    @State private var isEditing: Bool = false
    @State private var isDataShared: Bool = false

    @State private var selectedImage: UIImage? = nil
    @State private var isPickerPresented = false
    @State private var showResetAlert = false

    @State private var mailData: MailData?
    @State private var showMailSheet = false

    @AppStorage("temperatureUnit") private var temperatureUnit: String = "°C"
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"

    let sexOptions = ["Male", "Female", "Other"]
    let ethnicityOptions = [
        "American Indian/Alaska Native", "Asian", "Black", "Native Hawaiian/Pacific Islander",
        "White", "Hispanic/Latinx/Spanish", "Other"
    ]
    let professionOptions = [
        "Employed for wages", "Self-employed", "Out of work and looking for work",
        "Out of work but not currently looking for work", "A homemaker", "A student",
        "Military", "Retired", "Unable to work", "Other"
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
                                .overlay(Text("Add Photo").foregroundColor(.blue))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .onTapGesture { isPickerPresented = true }
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
                        ForEach(sexOptions, id: \.self) { Text($0).tag($0) }
                    }.pickerStyle(SegmentedPickerStyle()).disabled(!isEditing)

                    Picker("Ethnicity", selection: $ethnicity) {
                        ForEach(ethnicityOptions, id: \.self) { Text($0).tag($0) }
                    }.disabled(!isEditing)

                    Picker("Profession", selection: $profession) {
                        ForEach(professionOptions, id: \.self) { Text($0).tag($0) }
                    }.disabled(!isEditing)

                    EditableField(label: "Weight (kg)", value: $weight, keyboardType: .numberPad, isEditing: isEditing)
                    EditableField(label: "Height (cm)", value: $height, keyboardType: .numberPad, isEditing: isEditing)
                }

                // 📌 Units Section
                Section(header: Text("Unit Preferences")) {
                    Picker("Temperature Unit", selection: $temperatureUnit) {
                        ForEach(tempUnits, id: \.self) { Text($0).tag($0) }
                    }.pickerStyle(SegmentedPickerStyle()).disabled(!isEditing)

                    Picker("Distance Unit", selection: $distanceUnit) {
                        ForEach(distanceUnits, id: \.self) { Text($0).tag($0) }
                    }.pickerStyle(SegmentedPickerStyle()).disabled(!isEditing)
                }

                // 📌 Data Sharing Section
                Section(header: Text("Data Sharing")) {
                  Button("📤 Share My Data for Research") {
                      let profile = DatabaseManager.shared.fetchUserProfile()
                      let workouts = DatabaseManager.shared.fetchRecentWorkouts()

                      print("✅ Profile loaded: \(String(describing: profile))")
                      print("✅ Workouts loaded: \(workouts.count) entries")

                      guard let profile = profile,
                            let fileURL = ResearchExportManager.shared.exportToCSV(userProfile: profile, workouts: workouts) else {
                          print("❌ Export failed or profile missing")
                          return
                      }

                      print("✅ Saved XLSX to: \(fileURL.path)")

                      // ⏱ Check if file exists and log size
                      do {
                          let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                          if let fileSize = attributes[.size] as? UInt64 {
                              print("✅ File exists with size: \(fileSize) bytes")
                          } else {
                              print("⚠️ Could not get file size.")
                          }
                      } catch {
                          print("❌ Error getting file attributes: \(error.localizedDescription)")
                      }

                      // Try loading file data
                    DispatchQueue.global().async {
                        do {
                            let fileData = try Data(contentsOf: fileURL)
                            let mail = MailData(
                                recipients: ["tshelar@asu.edu"],
                                subject: "Smart Heat Tracker Research Data",
                                message: "Attached is the anonymized data for research.",
                                attachments: [
                                    .init(data: fileData, mimeType: "text/csv", fileName: fileURL.lastPathComponent)
                                ]
                            )

                            DispatchQueue.main.async {
                                self.mailData = mail
                            }
                        } catch {
                            print("❌ Could not read CSV file data. Error: \(error.localizedDescription)")
                        }
                    }

                  }

.foregroundColor(.blue)

                    Button("Reset Profile", role: .destructive) {
                        showResetAlert = true
                    }
                }

                if isEditing {
                    Button("Save") {
                        saveProfile()
                        isEditing = false
                    }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                Button(isEditing ? "Cancel" : "Edit") { isEditing.toggle() }
            }
            .onAppear { loadProfile() }
            .sheet(isPresented: $isPickerPresented) {
                PhotoPicker(selectedImage: $selectedImage)
            }
            .sheet(item: $mailData) { mailItem in
                MailView(data: mailItem) { result in
                    switch result {
                    case .success: print("✅ Mail sent")
                    case .failure(let error): print("❌ Mail failed: \(error.localizedDescription)")
                    }
                }
            }
            .alert("Reset Profile", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) { resetProfile() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to reset your profile?")
            }
        }
    }

    // MARK: - Save/Load/Reset

    func saveProfile() {
        guard let weightDouble = Double(weight), let heightDouble = Double(height) else {
            print("Invalid input, could not save profile.")
            return
        }

        let profile = UserProfile(
            name: name, dob: dob, sex: sex, ethnicity: ethnicity,
            profession: profession, height: heightDouble, weight: weightDouble,
            distanceUnit: distanceUnit, temperatureUnit: temperatureUnit,
            activityLevel: activityLevel
        )

        DatabaseManager.shared.insertOrUpdateUserProfile(profile)
        saveProfileImage()
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
            activityLevel = profile.activityLevel
        }
        loadProfileImage()
    }

    func resetProfile() {
        name = ""; dob = Date(); sex = "Male"; ethnicity = "White"; profession = "Employed for wages"
        weight = ""; height = ""; temperatureUnit = "°C"; distanceUnit = "km"
        isDataShared = false; activityLevel = 0; selectedImage = nil
        saveProfile(); deleteProfileImage()
    }

    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func saveProfileImage() {
        guard let selectedImage = selectedImage else { return }
        if let data = selectedImage.jpegData(compressionQuality: 0.8) {
            try? data.write(to: getDocumentsDirectory().appendingPathComponent("profile_photo.png"))
        }
    }

    func loadProfileImage() {
        let url = getDocumentsDirectory().appendingPathComponent("profile_photo.png")
        if FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url) {
            selectedImage = UIImage(data: data)
        }
    }

    func deleteProfileImage() {
        let url = getDocumentsDirectory().appendingPathComponent("profile_photo.png")
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - EditableField
struct EditableField: View {
    let label: String
    @Binding var value: String
    var keyboardType: UIKeyboardType = .default
    var isEditing: Bool

    var body: some View {
        HStack {
            Text(label).font(.headline)
            TextField(label, text: $value)
                .keyboardType(keyboardType)
                .disabled(!isEditing)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Photo Picker
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
        init(_ parent: PhotoPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
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

// MARK: - MailData + MailView
struct MailData: Identifiable {
    let id = UUID() // Required for .sheet(item:)
    var recipients: [String]
    var subject: String
    var message: String
    var attachments: [Attachment] = []

    struct Attachment {
        let data: Data
        let mimeType: String
        let fileName: String
    }
}

struct MailView: UIViewControllerRepresentable {
    var data: MailData
    var onComplete: (Result<Void, Error>) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView

        init(_ parent: MailView) { self.parent = parent }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true)
            if let error = error {
                parent.onComplete(.failure(error))
            } else {
                parent.onComplete(.success(()))
            }
        }
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(data.recipients)
        vc.setSubject(data.subject)
        vc.setMessageBody(data.message, isHTML: false)
        for attachment in data.attachments {
            vc.addAttachmentData(attachment.data, mimeType: attachment.mimeType, fileName: attachment.fileName)
        }
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

