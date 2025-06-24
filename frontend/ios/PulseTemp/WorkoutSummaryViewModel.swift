import Foundation
import Combine

class WorkoutSummaryViewModel: ObservableObject {
    @Published var workouts: [WorkoutSession] = []

    init() {
        loadWorkouts()
    }

    func loadWorkouts() {
        DispatchQueue.global(qos: .background).async {
            let fetched = DatabaseManager.shared.fetchRecentWorkouts(limit: 3)
            DispatchQueue.main.async {
                self.workouts = fetched
            }
        }
    }
}

