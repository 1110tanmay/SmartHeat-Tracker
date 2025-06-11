import Foundation
import HealthKit
import Combine
import UserNotifications
import WatchConnectivity

class WorkoutManager: NSObject, ObservableObject, WCSessionDelegate {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    @Published var workoutId: UUID = UUID()  // ✅ New: Unique ID per workout
    @Published var workoutStartDate: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var showQuestionnaire: Bool = false

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
                print("❤️ Received heart rate from iPhone: \(hr) BPM")
            }
        }
    }

    // MARK: - Send Questionnaire to iPhone ✅
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
            "workoutId": workoutId.uuidString  // ✅ include ID
        ]

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("🛑 Failed to send questionnaire to iPhone: \(error.localizedDescription)")
        }
    }

    // MARK: - HealthKit Authorization
    func requestAuthorization() {
        let typesToShare: Set<HKSampleType> = []

        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!
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
        workoutId = UUID()  // ✅ Generate a new ID at the start

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
            session?.startActivity(with: workoutStartDate!)
            builder?.beginCollection(withStart: workoutStartDate!) { _, _ in }

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

            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                let meters = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                distance = meters / 1000

            case HKQuantityType.quantityType(forIdentifier: .bodyTemperature):
                let temp = statistics.mostRecentQuantity()?.doubleValue(for: .degreeCelsius()) ?? 0
                if temp >= 37.8, !notificationSent {
                    sendCoreTempAlertNotification()
                    notificationSent = true
                }

            default:
                break
            }
        }
    }
}

