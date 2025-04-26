import Foundation

struct UserProfile: Identifiable, Codable {
    var id: String = "primary" // Always "primary", we only have 1 user per device

    var name: String
    var age: Int
    var sex: String
    var height: Double // in centimeters
    var weight: Double // in kilograms

    var distanceUnit: String // "km" or "miles"
    var temperatureUnit: String // "°C" or "°F"
}

