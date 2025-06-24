import SwiftUI

struct WorkoutSummaryTile: View {
    @State private var showWorkoutList = false
    @ObservedObject var viewModel: WorkoutSummaryViewModel

    var body: some View {
        Button(action: {
            viewModel.loadWorkouts() // Force refresh on tap
            showWorkoutList = true
        }) {
            HealthMetricCard(
                title: "Workout Summary",
                value: "Last \(viewModel.workouts.count) workouts", // ✅ Updated to use viewModel
                icon: "figure.run",
                color: .green
            )
        }
        .sheet(isPresented: $showWorkoutList) {
            WorkoutListModal(viewModel: viewModel) // ✅ Pass viewModel
        }
    }
}

struct WorkoutListModal: View {
    @ObservedObject var viewModel: WorkoutSummaryViewModel // ✅ Use view model instead of static list
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWorkout: WorkoutSession? = nil

    var body: some View {
        NavigationView {
            List(viewModel.workouts) { workout in // ✅ Access workouts via viewModel
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
                    workout: workout,
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

