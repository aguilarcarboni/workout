import Foundation
import UserNotifications
import WorkoutKit

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    @Published var authorizationState: UNAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        notificationCenter.delegate = self
        // Check current authorization state on init
        Task {
            await checkCurrentAuthorizationStatus()
        }
    }
    
    private func checkCurrentAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        DispatchQueue.main.async {
            self.authorizationState = settings.authorizationStatus
        }
    }
    
    func requestAuthorization() async -> UNAuthorizationStatus {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            // Update the state on the main thread as it's a @Published property
            DispatchQueue.main.async {
                self.authorizationState = granted ? .authorized : .denied
            }
            return granted ? .authorized : .denied
        } catch {
            // Update the state on the main thread
            DispatchQueue.main.async {
                self.authorizationState = .denied // Or handle as appropriate
            }
            return .denied // Or handle as appropriate
        }
    }

    // MARK: - Generic Notification API
    /// Schedule a local notification with given content and trigger.
    /// - Parameters:
    ///   - title: Title shown in the banner/alert.
    ///   - body:  Body text shown below the title.
    ///   - trigger: When the notification should fire.
    @MainActor
    func sendNotification(title: String, body: String, trigger: UNNotificationTrigger) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    /// Convenience wrapper to send a banner after a delay (seconds from now). Default: 5s.
    @MainActor
    func sendNotification(title: String, body: String, after timeInterval: TimeInterval = 5) async {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        await sendNotification(title: title, body: body, trigger: trigger)
    }

    func getNotifications() async throws -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    func removeNotifications() async throws {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

} 
