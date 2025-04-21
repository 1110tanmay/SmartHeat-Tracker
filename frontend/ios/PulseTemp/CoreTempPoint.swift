import Foundation

struct CoreTempPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let temperature: Double
}

