import ActivityKit
import Flutter

final class SchoolDashLiveActivityPlugin: NSObject, FlutterPlugin {
  private var activity: Activity<SchoolDashLiveActivityAttributes>?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "school_dash/live_activity",
      binaryMessenger: registrar.messenger()
    )
    let instance = SchoolDashLiveActivityPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "show" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard #available(iOS 16.1, *) else {
      result(FlutterError(code: "unsupported", message: "Live Activities require iOS 16.1 or later.", details: nil))
      return
    }
    guard
      let arguments = call.arguments as? [String: Any],
      let period = arguments["period"] as? Int,
      let subject = arguments["subject"] as? String,
      let remainingMinutes = arguments["remainingMinutes"] as? Int,
      let progress = arguments["progress"] as? Double
    else {
      result(FlutterError(code: "invalid_snapshot", message: "A current-class snapshot is required.", details: nil))
      return
    }

    let state = SchoolDashLiveActivityAttributes.ContentState(
      period: period,
      subject: subject,
      remainingMinutes: remainingMinutes,
      progress: progress,
      nextPeriod: arguments["nextPeriod"] as? Int,
      nextSubject: arguments["nextSubject"] as? String
    )
    let attributes = SchoolDashLiveActivityAttributes()
    do {
      if let activity {
        Task {
          await activity.update(using: state)
          result(nil)
        }
      } else {
        activity = try Activity.request(attributes: attributes, contentState: state)
        result(nil)
      }
    } catch {
      result(FlutterError(code: "activity_error", message: error.localizedDescription, details: nil))
    }
  }
}
