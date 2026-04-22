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
            ZStack {
                // Premium Background
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        
                        // 📸 HERO Profile Section
                        VStack(spacing: 16) {
                            ZStack {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 140)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                                } else {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 140, height: 140)
                                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 60))
                                                .foregroundColor(.gray.opacity(0.3))
                                        )
                                }
                                
                                // Edit Badge
                                Circle()
                                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                    )
                                    .offset(x: 45, y: 45)
                            }
                            .onTapGesture { isPickerPresented = true }
                            
                            Text(name.isEmpty ? "Anonymous User" : name)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                        }
                        .padding(.top, 20)

                        // 📌 Personal Info Card
                        VStack(alignment: .leading, spacing: 20) {
                            ProfileSectionHeader(title: "Personal Information", icon: "person.text.rectangle")
                            
                            VStack(spacing: 16) {
                                PremiumProfileField(label: "Name", value: $name, isEditing: isEditing, icon: "pencil")
                                
                                HStack {
                                    Label("Date of Birth", systemImage: "calendar")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if isEditing {
                                        DatePicker("", selection: $dob, displayedComponents: .date)
                                            .labelsHidden()
                                    } else {
                                        Text(dateFormatter.string(from: dob))
                                            .font(.system(.body, design: .rounded))
                                    }
                                }
                                
                                Divider().opacity(0.5)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("BIOLOGY & ETHNICITY")
                                        .font(.system(.caption2, design: .rounded))
                                        .fontWeight(.black)
                                        .foregroundColor(.secondary)
                                    
                                    Picker("Sex", selection: $sex) {
                                        ForEach(sexOptions, id: \.self) { Text($0).tag($0) }
                                    }
                                    .pickerStyle(.segmented)
                                    .disabled(!isEditing)
                                    
                                    Picker("Ethnicity", selection: $ethnicity) {
                                        ForEach(ethnicityOptions, id: \.self) { Text($0).tag($0) }
                                    }
                                    .disabled(!isEditing)
                                }
                                
                                Divider().opacity(0.5)
                                
                                HStack(spacing: 16) {
                                    PremiumProfileField(label: "Weight", value: $weight, isEditing: isEditing, icon: "scalemass", keyboardType: .numberPad)
                                    PremiumProfileField(label: "Height", value: $height, isEditing: isEditing, icon: "ruler", keyboardType: .numberPad)
                                }
                            }
                            .padding(20)
                            .background(.thinMaterial)
                            .cornerRadius(24)
                        }
                        .padding(.horizontal)

                        // 📌 Units Section
                        VStack(alignment: .leading, spacing: 12) {
                            ProfileSectionHeader(title: "Unit Preferences", icon: "slider.horizontal.3")
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Temperature")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Picker("Temp", selection: $temperatureUnit) {
                                        ForEach(tempUnits, id: \.self) { Text($0).tag($0) }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 120)
                                    .disabled(!isEditing)
                                }
                                
                                HStack {
                                    Text("Distance")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Picker("Dist", selection: $distanceUnit) {
                                        ForEach(distanceUnits, id: \.self) { Text($0).tag($0) }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 120)
                                    .disabled(!isEditing)
                                }
                            }
                            .padding(20)
                            .background(.thinMaterial)
                            .cornerRadius(24)
                        }
                        .padding(.horizontal)

                        // 📌 Actions
                        VStack(spacing: 16) {
                            if isEditing {
                                Button(action: {
                                    saveProfile()
                                    isEditing = false
                                }) {
                                    Text("Save Profile Changes")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                                        .cornerRadius(16)
                                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                            }

                            Button(action: {
                                exportAndEmailData()
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export Research Data")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(16)
                            }

                            Button(action: {
                                showResetAlert = true
                            }) {
                                Text("Reset All App Data")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .padding(.top, 10)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)

                        // 🏷️ Attribution Footer
                        VStack(spacing: 4) {
                            Text("Built with ❤️!")
                            Text("A Tanmay Shelar Production.")
                                .fontWeight(.bold)
                        }
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.bottom, 40)
                        .frame(maxWidth: .infinity)
                    }
                }
                .navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditing ? "Cancel" : "Edit") { isEditing.toggle() }
                    }
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
                    Text("Are you sure you want to reset your profile? This cannot be undone.")
                }
            }
        }
    }

    // MARK: - Logic Refactor
    private func exportAndEmailData() {
        // ✅ Keep your full export & email logic here
        let profile = DatabaseManager.shared.fetchUserProfile()
        let workouts = DatabaseManager.shared.fetchRecentWorkouts()

        guard let profile = profile,
              let fileURL = ResearchExportManager.shared.exportToCSV(userProfile: profile, workouts: workouts) else {
            return
        }

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
                print("❌ Could not read CSV file data.")
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
        ProfileImageManager.shared.save(image: selectedImage)
    }

    func loadProfileImage() {
        if let image = ProfileImageManager.shared.profileImage {
            selectedImage = image
        } else {
            // Fallback load if needed
            ProfileImageManager.shared.loadProfileImage()
            selectedImage = ProfileImageManager.shared.profileImage
        }
    }

    func deleteProfileImage() {
        ProfileImageManager.shared.deleteProfileImage()
        selectedImage = nil
    }
}

// MARK: - Premium UI Components

struct ProfileSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .font(.footnote)
            Text(title)
                .font(.system(.footnote, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .padding(.leading, 8)
    }
}

struct PremiumProfileField: View {
    let label: String
    @Binding var value: String
    var isEditing: Bool
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.purple.opacity(0.7))
                Text(label)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            
            TextField(label, text: $value)
                .font(.system(.body, design: .rounded))
                .keyboardType(keyboardType)
                .disabled(!isEditing)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(isEditing ? 1 : 0.5))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(isEditing ? 0.1 : 0), lineWidth: 1)
                )
        }
    }
}

// MARK: - Photo Picker (unchanged)
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


