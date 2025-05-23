import Foundation
import UserNotifications
import WorkoutKit

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    @Published var isAuthorized = false
    
    func requestAuthorization() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        } catch {
        }
    }

    func sendWorkoutNotification(scheduledWorkoutPlan: ScheduledWorkoutPlan) {
        Task {

            let content = UNMutableNotificationContent()
            content.title = "Workout Scheduled for today"
            content.body = "It's time to do your \(scheduledWorkoutPlan.plan.workout.activity.name) workout!"
            content.sound = .default
            
            // Schedule the notification for 30 seconds in the future
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger // Use the time interval trigger
            )
            
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Failed to send workout notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notification Management
    func getNotifications() async throws -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    func removeNotifications() async throws {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
