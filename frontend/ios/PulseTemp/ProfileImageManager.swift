import SwiftUI
import UIKit

class ProfileImageManager: ObservableObject {
    static let shared = ProfileImageManager()

    @Published private(set) var profileImage: UIImage? = nil

    private let fileName = "profile_photo.png"

    private init() {
        loadProfileImage()
    }

    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }

    // MARK: - Save Image
    func save(image: UIImage) {
        guard let url = fileURL else { return }
        if let data = image.pngData() {
            do {
                try data.write(to: url)
                DispatchQueue.main.async {
                    self.profileImage = image
                }
                print("✅ Profile image saved successfully")
            } catch {
                print("❌ Failed to save profile image: \(error)")
            }
        }
    }

    // MARK: - Load Image
    func loadProfileImage() {
        guard let url = fileURL else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
                print("✅ Profile image loaded from disk")
            }
        }
    }

    // MARK: - Delete Image
    func deleteProfileImage() {
        guard let url = fileURL else { return }
        do {
            try FileManager.default.removeItem(at: url)
            DispatchQueue.main.async {
                self.profileImage = nil
            }
            print("✅ Profile image deleted")
        } catch {
            print("❌ Failed to delete profile image: \(error)")
        }
    }
}


