import SwiftUI

struct WorkoutSummaryTile: View {
    @State private var showWorkoutList = false
    let workouts: [WorkoutSession]

    var body: some View {
        Button(action: {
            showWorkoutList = true
        }) {
            HealthMetricCard(
                title: "Workout Summary",
                value: "Last \(workouts.count) workouts",
                icon: "figure.run",
                color: .green
            )
        }
        .sheet(isPresented: $showWorkoutList) {
            WorkoutListModal(workouts: workouts)
        }
    }
}

struct WorkoutListModal: View {
    let workouts: [WorkoutSession]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWorkout: WorkoutSession? = nil

    var body: some View {
        NavigationView {
            List(workouts) { workout in
                VStack(alignment: .leading, spacing: 8) {
                    Text(formattedDateRange(start: workout.startTime, end: workout.endTime))
                        .font(.headline)
                    HStack(spacing: 16) {
                        Label("\(workout.totalCalories, specifier: "%.0f") kcal", systemImage: "flame.fill")
                        Label("\(workout.totalSteps) steps", systemImage: "figure.walk")
                        Label("\(String(format: "%.2f", workout.totalDistance)) km", systemImage: "map")
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 8)
                .onTapGesture {
                    selectedWorkout = workout
                }
            }
            .navigationTitle("Last Workouts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutSummaryReportView(
                    totalTime: Int(workout.duration),
                    caloriesBurned: Int(workout.totalCalories),
                    stepsWalked: workout.totalSteps,
                    distance: workout.totalDistance,
                    coreTemps: workout.coreTempPoints.map { $0.temp },       // ❌ Will be empty
                    heartRates: workout.heartRatePoints.map { Int($0.bpm) }, // ❌ Will be empty
                    onDone: { selectedWorkout = nil }
                )
            }

        }
    }

    func formattedDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

