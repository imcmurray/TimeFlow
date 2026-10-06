import Flutter
import UIKit
// For FlutterLocalNotificationsPlugin.setPluginRegistrantCallback.
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var reminderActions: ReminderActionDelegate?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets task reminders show while the app is in the foreground and routes
    // taps and Done/Snooze buttons to the plugin.
    let actions = ReminderActionDelegate(forwardingTo: self as UNUserNotificationCenterDelegate)
    reminderActions = actions  // the notification center holds its delegate weakly
    UNUserNotificationCenter.current().delegate = actions
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Done/Snooze pressed while the app isn't running run in a background
    // isolate, which needs plugins registered too.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

/// Sits in front of Flutter's notification delegate and buys background time
/// for Done/Snooze.
///
/// flutter_local_notifications starts a background engine for an action
/// button and then calls iOS's completion handler straight away, so iOS
/// suspends the app before the Dart handler has saved anything; the task was
/// only marked done the next time the app opened. Holding a background task
/// for a few seconds lets the handler finish.
final class ReminderActionDelegate: NSObject, UNUserNotificationCenterDelegate {
  private weak var inner: UNUserNotificationCenterDelegate?
  private static let actionTime: TimeInterval = 15

  init(forwardingTo inner: UNUserNotificationCenterDelegate) {
    self.inner = inner
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if inner?.userNotificationCenter?(
      center, willPresent: notification, withCompletionHandler: completionHandler) == nil
    {
      completionHandler([.banner, .list, .sound])
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let id = response.actionIdentifier
    if id != UNNotificationDefaultActionIdentifier && id != UNNotificationDismissActionIdentifier {
      keepRunning(for: Self.actionTime)
    }
    if inner?.userNotificationCenter?(
      center, didReceive: response, withCompletionHandler: completionHandler) == nil
    {
      completionHandler()
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?
  ) {
    inner?.userNotificationCenter?(center, openSettingsFor: notification)
  }

  private func keepRunning(for seconds: TimeInterval) {
    let app = UIApplication.shared
    var task = UIBackgroundTaskIdentifier.invalid
    let end = {
      guard task != .invalid else { return }
      app.endBackgroundTask(task)
      task = .invalid
    }
    task = app.beginBackgroundTask(withName: "TimeFlow reminder action", expirationHandler: end)
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: end)
  }
}
