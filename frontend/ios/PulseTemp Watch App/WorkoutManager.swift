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

    @Published var workoutId: UUID = UUID()
    @Published var workoutStartDate: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var showQuestionnaire: Bool = false
    @Published var coreTemp: Double = 0.0
    @Published var steps: Int = 0

    private var heartRateSamples: [Double] = []
    private var coreTempSamples: [Double] = []
    private var stepSamples: [Int] = []
  
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

  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
      DispatchQueue.main.async {
          if let hr = message["heartRate"] as? Double {
              self.heartRate = hr
              self.heartRateSamples.append(hr)
              print("❤️ Received heart rate from iPhone: \(hr) BPM")
          }
          if let temp = message["coreTemp"] as? Double {
              self.coreTemp = temp
              self.coreTempSamples.append(temp)
              print("🌡️ Received core temp from iPhone: \(temp) °C")
          }
          if let steps = message["steps"] as? Int {
              self.steps = steps
              self.stepSamples.append(steps)
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
    func startWorkout() {
        workoutId = UUID()

        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
            session?.delegate = self
            builder?.delegate = self
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

          workoutStartDate = Date()
          do{
            try session?.startActivity(with: workoutStartDate!)
            print("✅ Workout session started")}
          catch{print("🛑 Failed to start workout session: \(error.localizedDescription)")}
          builder?.beginCollection(withStart: workoutStartDate!) { success, error in
              if let error = error {
                  print("🛑 beginCollection failed: \(error.localizedDescription)")
              } else {
                  print("✅ beginCollection succeeded")
              }
          }

            startTimer()
            startQuestionnaireTimer()

        } catch {
            print("🛑 Failed to start workout: \(error.localizedDescription)")
        }
    }

    func endWorkout() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { _, _ in
            self.builder?.finishWorkout { _, _ in }
        }

        timerCancellable?.cancel()
        questionnaireTimer?.invalidate()
        notificationSent = false
        sendWorkoutSummaryToPhone() //To send data to iPhonw
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
      guard WCSession.default.isReachable else {
          print("📡 iPhone not reachable — cannot send workout summary.")
          return
      }

      let formatter = ISO8601DateFormatter()
      let startString = workoutStartDate.map { formatter.string(from: $0) } ?? ""
      let endString = formatter.string(from: Date())

      // ✅ Calculate actual stats
      let coreMin = coreTempSamples.min() ?? coreTemp
      let coreMax = coreTempSamples.max() ?? coreTemp
      let coreAvg = coreTempSamples.isEmpty ? coreTemp : coreTempSamples.reduce(0, +) / Double(coreTempSamples.count)

    let hrMin = heartRateSamples.min() ?? heartRate
    let hrMax = heartRateSamples.max() ?? heartRate
    let hrAvg = heartRateSamples.isEmpty
        ? heartRate
        : heartRateSamples.reduce(0, +) / Double(heartRateSamples.count)


      let totalSteps = stepSamples.last ?? Int((distance * 1000) / 0.762)

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

      WCSession.default.sendMessage(summary, replyHandler: nil) { error in
          print("🛑 Failed to send workout summary to iPhone: \(error.localizedDescription)")
      }

      print("✅ Workout summary sent to iPhone: \(summary)")
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
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = builder?.statistics(for: quantityType) else { continue }

          switch quantityType {
          case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
              activeEnergy = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            print("🔥 Active Energy: \(activeEnergy) kcal")
            
          case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
              let meters = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0
              distance = meters / 1000
            print("📏 Distance: \(distance) km")

          case HKQuantityType.quantityType(forIdentifier: .bodyTemperature):
              let temp = statistics.mostRecentQuantity()?.doubleValue(for: .degreeCelsius()) ?? 0
              if temp >= 37.8, !notificationSent {
                  sendCoreTempAlertNotification()
                  notificationSent = true
              }

          case HKQuantityType.quantityType(forIdentifier: .stepCount):
              let stepCount = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
              self.steps = Int(stepCount)
            print("👣 Steps: \(self.steps)")

          default:
              break
          }

        }
    }
}

