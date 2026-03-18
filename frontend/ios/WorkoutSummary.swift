import Foundation

struct WorkoutSummary: Codable, Identifiable {
    
    // MARK: - Core Identifiers
    let id: UUID
    let startTime: Date
    let endTime: Date
    
    // MARK: - Aggregate Metrics
    let calories: Double
    let steps: Int
    let distance: Double  // Stored in meters (recommended standard)
    
    // MARK: - Time-Series Data
    let heartRateSamples: [Int]
    let coreTempSamples: [Double]
    
    // MARK: - Derived Properties
    
    // Duration of workout in seconds
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    // MARK: - Heart Rate Stats
    
    var heartRateMin: Int {
        heartRateSamples.min() ?? 0
    }

    var heartRateMax: Int {
        heartRateSamples.max() ?? 0
    }

    var heartRateAverage: Double {
        guard !heartRateSamples.isEmpty else { return 0 }
        return Double(heartRateSamples.reduce(0, +)) / Double(heartRateSamples.count)
    }
    
    // MARK: - Core Temperature Stats
    
    var coreTempMin: Double {
        coreTempSamples.min() ?? 0.0
    }

    var coreTempMax: Double {
        coreTempSamples.max() ?? 0.0
    }

    var coreTempAverage: Double {
        guard !coreTempSamples.isEmpty else { return 0.0 }
        return coreTempSamples.reduce(0, +) / Double(coreTempSamples.count)
    }
}
