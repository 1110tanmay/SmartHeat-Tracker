import Foundation
import HealthKit
import Combine
import UserNotifications
import WatchConnectivity

// MARK: - Alert State
private enum CoreTempAlertType {
    case high
    case recovered
}

private enum CoreTempAlertState {
    case normal
    case alerting
}

class WorkoutManager: NSObject, ObservableObject, WCSessionDelegate {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var stepQuery: HKStatisticsCollectionQuery?

    @Published var workoutId: UUID = UUID()
    @Published var workoutStartDate: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var showQuestionnaire: Bool = false
    @Published var steps: Int = 0
    @Published var heartRateSamples: [Int] = []
    @Published var coreTempSamples: [Double] = []
    @Published var heartRate: Double = 0
    @Published var coreTemp: Double = 0
  
    private let ecTempCalculator = ECTempCalculator()
    private var timerCancellable: AnyCancellable?
    private var questionnaireTimer: Timer?
    private var notificationSent = false

    // MARK: - Core Temp Alert Thresholds
    private let coreTempHighThreshold: Double = 38.5
    private let coreTempRecoveryThreshold: Double = 37.5
    private var coreTempAlertState: CoreTempAlertState = .normal
    
    override init() {
        super.init()
        setupWatchConnectivity()
        requestNotificationPermission()
        startBackgroundWorkoutSession()
    }
  
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let wcSession = WCSession.default
            wcSession.delegate = self
            wcSession.activate()
        }
    }

    func sendQuestionnaireToPhone(exertion: Int, hydration: Int, thermal: Int) {
        guard WCSession.default.isReachable else { return }
        let message: [String: Any] = [
            "type": "questionnaire", "exertion": exertion, "hydration": hydration, "thermal": thermal,
            "timestamp": ISO8601DateFormatter().string(from: Date()), "workoutId": workoutId.uuidString
        ]
        WCSession.default.sendMessage(message, replyHandler: nil)
    }

  func fetchLatestHealthData() {
      // 1. Define the type of data we want to read (heart rate)
      guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
          print("🛑 Heart rate type is unavailable for summary fetch.")
          return
      }

      // 2. Create a sort descriptor to get the most recent sample first
      let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

      // 3. Create the query to fetch just the single most recent sample
      let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
          guard let self = self, let sample = samples?.first as? HKQuantitySample, error == nil else {
              // This is a common case if no HR data has been recorded yet.
              print("⚠️ Could not fetch a recent heart rate sample for the summary view.")
              return
          }

          // 4. Extract the heart rate value (BPM)
          let latestBPM = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))

          // 5. Calculate core temp locally using the fetched BPM
          let calculatedTemp = self.ecTempCalculator.updateCoreTemp(with: latestBPM)

          // 6. IMPORTANT: Update the UI properties on the main thread
          Task { @MainActor in
              self.heartRate = latestBPM
              self.coreTemp = calculatedTemp
              print("✅ Fetched latest data for summary: \(latestBPM) BPM, \(calculatedTemp)°C")
          }
      }

      healthStore.execute(query)
  }

  private func sendWorkoutSummaryToPhone() {
      
      guard WCSession.default.activationState == .activated else {
          print("🛑 WATCH: WCSession not activated. Cannot send file.")
          return
      }
      
      let summary = WorkoutSummary(
          id: self.workoutId,
          startTime: self.workoutStartDate ?? Date(),
          endTime: Date(),
          calories: self.activeEnergy,
          steps: self.steps,
          distance: self.distance,
          heartRateSamples: self.heartRateSamples,
          coreTempSamples: self.coreTempSamples
      )

      guard WCSession.isSupported() else {
          print("🛑 WATCH: WCSession not supported on this device. Cannot send workout summary.")
          return
      }

      guard WCSession.default.activationState == .activated else {
          print("🛑 WATCH: WCSession not activated. Cannot send workout summary file right now.")
          return
      }

      guard let data = try? JSONEncoder().encode(summary) else {
          print("🛑 WATCH: Failed to encode workout summary.")
          return
      }

      let tempDir = FileManager.default.temporaryDirectory
      let fileURL = tempDir.appendingPathComponent("\(summary.id.uuidString).json")

      do {
          try data.write(to: fileURL, options: [.atomic])

          WCSession.default.transferFile(fileURL, metadata: ["workoutID": summary.id.uuidString])

          print("📤 WATCH: Queued workout summary file for sending: \(fileURL.lastPathComponent)")

      } catch {
          print("🛑 WATCH: Error writing or transferring the summary file: \(error.localizedDescription)")
      }
  }

  func requestAuthorization() {
      let typesToShare: Set = [HKObjectType.workoutType()]
      let typesToRead: Set = [
          HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
          HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
          HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
          HKObjectType.quantityType(forIdentifier: .stepCount)!,
          HKObjectType.quantityType(forIdentifier: .heartRate)!
      ]
      
      healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
          if success {
              print("✅ Watch HealthKit authorization successful")
              self.fetchLatestHealthData()
          } else {
              if let error = error {
                  print("🛑 Watch HealthKit authorization failed: \(error.localizedDescription)")
              }
          }
      }
  }
  
    private func startBackgroundWorkoutSession() {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .indoor
        do {
            let backgroundSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            backgroundSession.startActivity(with: Date())
        } catch {}
    }

    func startWorkout() {
        workoutId = UUID()
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .indoor
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            session?.delegate = self
            builder?.delegate = self
            let startDate = Date()
            self.workoutStartDate = startDate
            session?.startActivity(with: startDate)
          
            session?.startMirroringToCompanionDevice(completion: { success, error in
              print("🔁 Mirroring started: \(success), error: \(String(describing: error))")
          })
            builder?.beginCollection(withStart: startDate) { _, _ in }
            startStepQuery(from: startDate)
            startTimer()
            startQuestionnaireTimer()
        } catch {}
    }

    private func startStepQuery(from startDate: Date) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        stepQuery = HKStatisticsCollectionQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: startDate, intervalComponents: DateComponents(day: 1))
        stepQuery!.initialResultsHandler = { _, collection, _ in
            let sum = collection?.statistics().last?.sumQuantity()
            DispatchQueue.main.async { self.steps = Int(sum?.doubleValue(for: .count()) ?? 0) }
        }
        stepQuery!.statisticsUpdateHandler = { _, statistics, _, _ in
            let sum = statistics?.sumQuantity()
            DispatchQueue.main.async { self.steps = Int(sum?.doubleValue(for: .count()) ?? 0) }
        }
        healthStore.execute(stepQuery!)
    }

    func endWorkout() {
      print("🛑 WATCH: endWorkout() called")
        session?.end()
        builder?.endCollection(withEnd: Date()) { _, error in
            if let error = error {
                print("🛑 WATCH: endCollection failed: \(error.localizedDescription)")
            }
            self.builder?.finishWorkout { _, finishError in
                if let finishError = finishError {
                    print("🛑 WATCH: finishWorkout failed: \(finishError.localizedDescription)")
                } else {
                    print("✅ WATCH: finishWorkout completed. Sending summary.")
                }
                self.sendWorkoutSummaryToPhone()
            }
        }
        if let query = self.stepQuery { healthStore.stop(query) }
        timerCancellable?.cancel()
        questionnaireTimer?.invalidate()
        notificationSent = false
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
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let start = self?.workoutStartDate else { return }
            self?.elapsedTime = Date().timeIntervalSince(start)
        }
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        center.delegate = self
    }
    private func sendCoreTempAlertNotification(type: CoreTempAlertType) {
        let content = UNMutableNotificationContent()
        switch type {
        case .high:
            content.title = "🌡️ High Core Temp"
            content.body = "Your core temperature is elevated. Rest and hydrate now."
        case .recovered:
            content.title = "✅ Temp Normalised"
            content.body = "Core temperature is back to normal. You can resume intensity."
        }
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "coreTempAlert-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func startQuestionnaireTimer() {
        questionnaireTimer?.invalidate()
        // Fires every 30 minutes to prompt a check-in
        questionnaireTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            self?.sendQuestionnaireNotification()
        }
    }

    private func sendQuestionnaireNotification() {
        let content = UNMutableNotificationContent()
        content.title = "📝 Quick Check-In"
        content.body = "How are you feeling? Tap to log your exertion, hydration & thermal comfort."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "questionnaire-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if error == nil {
                // Surface the questionnaire sheet via the published flag
                DispatchQueue.main.async {
                    self?.showQuestionnaire = true
                }
            }
        }
    }
}

extension WorkoutManager {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

    }

  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
      DispatchQueue.main.async {
          if let type = message["type"] as? String, type == "questionnaire" {
              // If in the future the iPhone needs to send a questionnaire TO the watch,
              // you would handle it here. For now, this can be empty.
          } else {
              print("⚠️ WATCH: Received an unhandled message: \(message)")
          }
      }
  }
  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    print("⌚️ WATCH LOG [1/3]: RECEIVED raw context: \(applicationContext)")
    
    DispatchQueue.main.async {
      
      if let receivedHeartRate = applicationContext["heartRate"] as? Double {
        self.heartRate = receivedHeartRate
      }
      
      if let receivedCoreTemp = applicationContext["coreTemp"] as? Double {
        self.coreTemp = receivedCoreTemp
        print("⌚️ WATCH LOG [2/3]: UPDATED state. self.coreTemp is now: \(self.coreTemp)")

        if receivedCoreTemp > 0 {
          self.coreTempSamples.append(receivedCoreTemp)
        }

        // MARK: Core Temp Threshold Alerting
        if receivedCoreTemp >= self.coreTempHighThreshold && self.coreTempAlertState == .normal {
          self.coreTempAlertState = .alerting
          self.sendCoreTempAlertNotification(type: .high)
        } else if receivedCoreTemp < self.coreTempRecoveryThreshold && self.coreTempAlertState == .alerting {
          self.coreTempAlertState = .normal
          self.sendCoreTempAlertNotification(type: .recovered)
        }
      }
      print("📥 WATCH: Received synchronized pair - HR: \(self.heartRate), Temp: \(self.coreTemp)")
    }
  }
}
extension WorkoutManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.title == "📝 Quick Check-In" {
            DispatchQueue.main.async { self.showQuestionnaire = true }
        }
        completionHandler()
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}


extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            // Get the statistics for the workout so far
            let statistics = workoutBuilder.statistics(for: quantityType)

            DispatchQueue.main.async {
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    self.activeEnergy = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    
                case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                    self.distance = (statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0) / 1000
                    
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    // --- THIS IS THE NEW CORE LOGIC ---
                    // 1. Get the most recent heart rate value
                    let latestBpm = statistics?.mostRecentQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())) ?? 0
                    if latestBpm > 0 {
                        self.heartRate = latestBpm
                        self.heartRateSamples.append(Int(latestBpm))
                        
                        // 2. Calculate core temp LOCALLY using the new heart rate
                        let calculatedTemp = self.ecTempCalculator.updateCoreTemp(with: latestBpm)
                        self.coreTemp = calculatedTemp
                        
                        if calculatedTemp > 0 {
                            self.coreTempSamples.append(calculatedTemp)
                        }
                    }
                    
                default:
                    // Handle other types if needed
                    break
                }
            }
        }
    }
}

