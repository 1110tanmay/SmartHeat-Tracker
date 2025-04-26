import Foundation

struct CoreTempPoint: Identifiable, Codable {
    var id = UUID()
    var timestamp: Date
    var temp: Double // (NOT temperature + heartRate separately!)
}

