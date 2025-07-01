// WorkoutManager.swift

import Foundation
import HealthKit
import Combine
import UserNotifications
import WatchConnectivity

class WorkoutManager: NSObject, ObservableObject, WCSessionDelegate {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var stepQuery: HKStatisticsCollectionQuery? // <-- ADD THIS LINE

    @Published var workoutId: UUID = UUID()
    @Published var workoutStartDate: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var showQuestionnaire: Bool = false
    @Published var coreTemp: Double = 0.0
    @Published var steps: Int = 0
    @Published var heartRateSamples: [Int] = []
    @Published var coreTempSamples: [Double] = []

  
    private var timerCancellable: AnyCancellable?
    private var questionnaireTimer: Timer?
    private var notificationSent = false

    override init() {
        super.init()
        print("WorkoutManager initialized ✅")
        setupWatchConnectivity()
        requestNotificationPermission()

        if let info = Bundle.main.infoDictionary {
            print("🚨 Info.plist keys: \(info.keys)")
            if let shareDesc = info["NSHealthShareUsageDescription"] as? String {
                print("✅ NSHealthShareUsageDescription: \(shareDesc)")
            } else {
                print("🛑 NSHealthShareUsageDescription missing at runtime")
            }
        }
    }

    // MARK: - Watch Connectivity Setup
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let wcSession = WCSession.default
            wcSession.delegate = self
            wcSession.activate()
            print("🔗 WCSession activated")
        } else {
            print("🛑 WatchConnectivity not supported")
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("🛑 WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ WCSession activation complete with state: \(activationState.rawValue)")
        }
    }

  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {DispatchQueue.main.async {
    if let hr = message["heartRate"] as? Double {
        let bpm = Int(hr) // ✅ convert to Int once
        self.heartRate = hr
        self.heartRateSamples.append(bpm) // ✅ store as Int
        print("❤️ Received heart rate from iPhone: \(bpm) BPM")
    }

    if let temp = message["coreTemp"] as? Double {
        self.coreTemp = temp
        self.coreTempSamples.append(temp)
        print("🌡️ Received core temp from iPhone: \(temp) °C")
    }
}
}

    // MARK: - Send Questionnaire to iPhone
    func sendQuestionnaireToPhone(exertion: Int, hydration: Int, thermal: Int) {
        guard WCSession.default.isReachable else {
            print("📡 iPhone not reachable — cannot send questionnaire.")
            return
        }

        let message: [String: Any] = [
            "type": "questionnaire",
            "exertion": exertion,
            "hydration": hydration,
            "thermal": thermal,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "workoutId": workoutId.uuidString
        ]

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("🛑 Failed to send questionnaire to iPhone: \(error.localizedDescription)")
        }
    }

    // MARK: - HealthKit Authorization
  func requestAuthorization() {
      let typesToShare: Set = [
          HKObjectType.workoutType() // 🔑 Required to start workouts
      ]

      let typesToRead: Set = [
          HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
          HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
          HKObjectType.quantityType(forIdentifier: .bodyTemperature)!, // optional if you're syncing temp
          HKObjectType.quantityType(forIdentifier: .stepCount)!,
          HKObjectType.quantityType(forIdentifier: .heartRate)!        // for completeness
      ]

      healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
          DispatchQueue.main.async {
              if success {
                  print("✅ HealthKit authorization successful")
              } else {
                  print("🛑 HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
              }
          }
      }
  }


    // MARK: - Workout Session Management
  
  // In WorkoutManager.swift

  func startWorkout() {
      workoutId = UUID()

      let config = HKWorkoutConfiguration()
      config.activityType = .walking
      config.locationType = .indoor

      do {
          session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
          builder = session?.associatedWorkoutBuilder()
          
          // Use the basic data source, as the builder isn't providing steps
          builder?.dataSource = HKLiveWorkoutDataSource(
              healthStore: healthStore,
              workoutConfiguration: config
          )
          
          session?.delegate = self
          builder?.delegate = self
          
          let startDate = Date()
          self.workoutStartDate = startDate
          
          session?.startActivity(with: startDate)
          builder?.beginCollection(withStart: startDate) { success, error in
              if let error = error {
                  print("🛑 beginCollection failed: \(error.localizedDescription)")
              } else {
                  print("✅ beginCollection succeeded")
              }
          }

          // --- ADD THIS LINE TO START OUR CUSTOM STEP QUERY ---
          startStepQuery(from: startDate)

          startTimer()
          startQuestionnaireTimer()

      } catch {
          print("🛑 Failed to start workout: \(error.localizedDescription)")
      }
  }
  
  // In WorkoutManager.swift, add this entire new function

  private func startStepQuery(from startDate: Date) {
      let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
      let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)

      stepQuery = HKStatisticsCollectionQuery(
          quantityType: stepType,
          quantitySamplePredicate: predicate,
          options: .cumulativeSum,
          anchorDate: startDate,
          intervalComponents: DateComponents(day: 1)
      )

      // Required initial handler
      stepQuery!.initialResultsHandler = { query, collection, error in
          guard let statistics = collection?.statistics().last,
                let sum = statistics.sumQuantity() else {
              return
          }

          DispatchQueue.main.async {
              let newSteps = sum.doubleValue(for: .count())
              self.steps = Int(newSteps)
              print("👣 Steps Initial Total via Query: \(self.steps)")
          }
      }

      // Live update handler
      stepQuery!.statisticsUpdateHandler = { query, statistics, collection, error in
          guard let statistics = statistics,
                let sum = statistics.sumQuantity() else {
              return
          }

          DispatchQueue.main.async {
              let newSteps = sum.doubleValue(for: .count())
              self.steps = Int(newSteps)
              print("👣 Steps Updated via Query: \(self.steps)")
          }
      }

      healthStore.execute(stepQuery!)
  }


  // In WorkoutManager.swift

  func endWorkout() {
      session?.end()
      builder?.endCollection(withEnd: Date()) { _, _ in
          self.builder?.finishWorkout { _, _ in }
      }

      // --- ADD THESE LINES TO STOP OUR CUSTOM STEP QUERY ---
      if let query = self.stepQuery {
          healthStore.stop(query)
      }

      timerCancellable?.cancel()
      questionnaireTimer?.invalidate()
      notificationSent = false
      sendWorkoutSummaryToPhone()
  }

    func pauseWorkout() {
        session?.pause()
        timerCancellable?.cancel()
        questionnaireTimer?.invalidate()
    }

    func resumeWorkout() {
        session?.resume()
        startTimer()
        startQuestionnaireTimer()
    }

    private func startTimer() {
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let start = self?.workoutStartDate else { return }
                self?.elapsedTime = Date().timeIntervalSince(start)
            }
    }

    // MARK: - Notifications
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("🛑 Notification permission error: \(error.localizedDescription)")
                return
            }
            print(granted ? "🔔 Notification permission granted" : "🚫 Notification permission denied")
        }
        center.delegate = self
    }

    private func sendCoreTempAlertNotification() {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ High Core Temp"
        content.body = "Your core body temperature is high. Please rest for 2 minutes."
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func startQuestionnaireTimer() {
        questionnaireTimer?.invalidate()
        questionnaireTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.sendQuestionnaireNotification()
        }
    }

    private func sendQuestionnaireNotification() {
        let content = UNMutableNotificationContent()
        content.title = "📝 Quick Check-In"
        content.body = """
        1. Perceived Exertion (6–20)
        2. Hydration Level (1–5)
        3. Thermal Sensation (1–5)
        """
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
  
  private func sendWorkoutSummaryToPhone() {
      print("⌚️ Workout ended at \(Date()), preparing to send summary to iPhone")

      let formatter = ISO8601DateFormatter()
      let startString = workoutStartDate.map { formatter.string(from: $0) } ?? ""
      let endString = formatter.string(from: Date())

      // ✅ Filter valid core temp values
      let validCoreTemps = coreTempSamples.filter { $0 > 0 }
      let coreMin = validCoreTemps.min() ?? 0
      let coreMax = validCoreTemps.max() ?? 0
      let coreAvg = validCoreTemps.isEmpty ? 0 : validCoreTemps.reduce(0, +) / Double(validCoreTemps.count)

      // ✅ Filter valid heart rates
      let validHeartRates = heartRateSamples.filter { $0 > 0 }
      let hrMin = validHeartRates.min() ?? 0
      let hrMax = validHeartRates.max() ?? 0
      let hrAvg = validHeartRates.isEmpty ? 0 : validHeartRates.reduce(0, +) / validHeartRates.count

      // ✅ Steps
    let totalSteps = self.steps

      // ✅ Prepare summary dictionary
      let summary: [String: Any] = [
          "type": "workout_summary",
          "workoutId": workoutId.uuidString,
          "startTime": startString,
          "endTime": endString,
          "calories": activeEnergy,
          "steps": totalSteps,
          "distance": distance,
          "coreTempMin": coreMin,
          "coreTempMax": coreMax,
          "coreTempAvg": coreAvg,
          "heartRateMin": hrMin,
          "heartRateMax": hrMax,
          "heartRateAvg": hrAvg
      ]

      // ✅ Use transferUserInfo instead of sendMessage
      WCSession.default.transferUserInfo(summary)
      print("📤 Workout summary queued for iPhone using transferUserInfo: \(summary)")
  }


}

// MARK: - UNUserNotificationCenterDelegate
extension WorkoutManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.title == "📝 Quick Check-In" {
            DispatchQueue.main.async {
                self.showQuestionnaire = true
            }
        }
        completionHandler()
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {}

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        print("🛑 Workout session failed: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
// ✅ FINAL AND CORRECT VERSION ✅
// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        
        // You can use this to see what data HealthKit is giving you
        print("HKLiveWorkoutBuilderDelegate received data for types: \(collectedTypes.map { $0.identifier })")

        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = builder?.statistics(for: quantityType) else { continue }

            switch quantityType {
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let newEnergy = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                DispatchQueue.main.async {
                    self.activeEnergy = newEnergy
                    print("🔥 Active Energy: \(self.activeEnergy) kcal")
                }
                
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                let meters = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                DispatchQueue.main.async {
                    self.distance = meters / 1000
                    print("📏 Distance: \(self.distance) km")
                }

            case HKQuantityType.quantityType(forIdentifier: .bodyTemperature):
                let temp = statistics.mostRecentQuantity()?.doubleValue(for: .degreeCelsius()) ?? 0
                if temp >= 37.8, !notificationSent {
                    sendCoreTempAlertNotification()
                    notificationSent = true
                }

            // Correctly positioned as its own case
            case HKQuantityType.quantityType(forIdentifier: .stepCount):
                let newSteps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                DispatchQueue.main.async {
                    self.steps = Int(newSteps)
                    print("👣 Steps: \(self.steps)")
                }

            default:
                break
            }
        }
    }
}

