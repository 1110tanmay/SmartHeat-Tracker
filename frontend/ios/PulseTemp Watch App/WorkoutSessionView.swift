import SwiftUI

struct WorkoutSessionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var workoutManager: WorkoutManager

    @State private var isPaused = false
    @State private var showSummary = false
    @State private var showingQuestionnaire = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 1.0, green: 0.56, blue: 0.0), Color(red: 1.0, green: 0.27, blue: 0.0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                ScrollView {
                  VStack(spacing: 20) {

                    Text(String(format: "%02d:%02d",
                                Int(workoutManager.elapsedTime) / 60,
                                Int(workoutManager.elapsedTime) % 60))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    
                    VStack(alignment: .center, spacing: 6) {
                      HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "thermometer")
                          .foregroundColor(.orange)
                          .font(.system(size: 20))
                          .frame(width: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                          Text("Core Temp")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                          
                          Text(String(format: "%.2f°C", workoutManager.coreTemp))                            .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        }
                        
                        Spacer()
                      }
                      .padding()
                      .frame(maxWidth: .infinity, minHeight: 60)
                      .background(
                        RoundedRectangle(cornerRadius: 18)
                          .fill(Color.white.opacity(0.12))
                      )
                      .cornerRadius(18)
                      .shadow(color: Color.orange.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    HStack(alignment: .center, spacing: 12) {
                      Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                        .frame(width: 28)
                      
                      VStack(alignment: .leading, spacing: 2) {
                        Text("Heart Rate")
                          .font(.caption)
                          .foregroundColor(.white.opacity(0.8))
                          .lineLimit(1)
                          .minimumScaleFactor(0.6)
                        
                        Text("\(Int(workoutManager.heartRate)) BPM")
                          .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                          .foregroundColor(.white)
                          .lineLimit(1)
                          .minimumScaleFactor(0.5)
                      }
                      
                      Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                      RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.12))
                    )
                    .cornerRadius(18)
                    .shadow(color: Color.red.opacity(0.2), radius: 4, x: 0, y: 2)
                  

                        HStack(spacing: 16) {
                          metricRing(
                              title: "CAL",
                              value: workoutManager.activeEnergy,
                              color: Color(red: 1.0, green: 0.22, blue: 0.31)
                          )
                          metricRing(
                              title: "STEPS",
                              value: Double(workoutManager.steps),
                              color: Color(red: 0.0, green: 0.76, blue: 0.27)
                          )
                          metricRing(
                              title: "KM",
                              value: workoutManager.distance,
                              color: Color(red: 0.0, green: 0.48, blue: 1.0)
                          )
                        }
                        .padding(.horizontal)


                      VStack(spacing: 12)  {

                        Button(action: {
                            isPaused.toggle()
                            isPaused ? workoutManager.pauseWorkout() : workoutManager.resumeWorkout()
                        }) {
                            Label(isPaused ? "Resume" : "Pause", systemImage: "pause.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2)


                        Button(action: {
                            workoutManager.endWorkout()
                            showSummary = true
                        }) {
                            Label("End", systemImage: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                                .foregroundColor(Color(red: 0.85, green: 0.2, blue: 0.1)) // Match Start button red
                        }
                        .buttonStyle(PlainButtonStyle())
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                       // .padding(.horizontal)
                        //.padding(.bottom)
                    }
                }
            }
            .onChange(of: workoutManager.coreTemp) { newTemp in
                            print("🧊 WATCH LOG [3/3]: UI DETECTED a change in coreTemp. New value is: \(newTemp)")
                        }
            .onAppear {
                workoutManager.startWorkout()
            }
            .onReceive(workoutManager.$showQuestionnaire) { shouldShow in
                if shouldShow {
                    showingQuestionnaire = true
                    workoutManager.showQuestionnaire = false
                }
            }
            .sheet(isPresented: $showingQuestionnaire) {
                QuestionnaireView(onSubmit: { exertion, hydration, thermal in
                    workoutManager.sendQuestionnaireToPhone(
                        exertion: exertion,
                        hydration: hydration,
                        thermal: thermal
                    )
                    showingQuestionnaire = false
                })
            }
            .navigationDestination(isPresented: $showSummary) {
                WorkoutSummaryReportView(
                    totalTime: Int(workoutManager.elapsedTime),
                    caloriesBurned: Int(workoutManager.activeEnergy),
                    stepsWalked: workoutManager.steps,
                    distance: workoutManager.distance,
                    coreTemps: workoutManager.coreTempSamples,
                    heartRates: workoutManager.heartRateSamples,
                    onDone: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
  
    

  func metricRing(title: String, value: Double, color: Color) -> some View {
    let ringSize: CGFloat = 42
    let ringWidth: CGFloat = 6


      return VStack(spacing: 6) {
          ZStack {
              // Background Circle
              Circle()
                  .stroke(color.opacity(0.2), lineWidth: ringWidth)
                  .frame(width: ringSize, height: ringSize)

              // Foreground Gradient Stroke
              Circle()
                  .trim(from: 0, to: min(value / 100.0, 1.0))
                  .stroke(
                      AngularGradient(
                          gradient: Gradient(colors: [color.opacity(0.6), color]),
                          center: .center
                      ),
                      style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                  )
                  .rotationEffect(.degrees(-90))
                  .frame(width: ringSize, height: ringSize)
                  .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)

              // Metric Value
              Text(String(format: "%.0f", value))
                  .font(.footnote)
                  .foregroundColor(.white)
                  .monospacedDigit()
          }

          // Title Label
          Text(title)
              .font(.caption2)
              .foregroundColor(.white)
      }
  }

}

