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
    guard call.method == "showOrUpdate" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard #available(iOS 16.1, *) else {
      result(FlutterError(code: "unsupported", message: "Live Activities require iOS 16.1 or later.", details: nil))
      return
    }
    guard let state = Self.contentState(from: call.arguments) else {
      result(FlutterError(code: "invalid_payload", message: "A current-class payload is required.", details: nil))
      return
    }

    Task {
      do {
        if let activity {
          await activity.update(using: state)
        } else {
          activity = try Activity.request(
            attributes: SchoolDashLiveActivityAttributes(),
            contentState: state
          )
        }
        result(nil)
      } catch {
        result(FlutterError(code: "activity_error", message: error.localizedDescription, details: nil))
      }
    }
  }

  private static func contentState(from value: Any?) -> SchoolDashLiveActivityAttributes.ContentState? {
    guard
      let payload = value as? [String: Any],
      let situation = payload["situation"] as? String,
      let period = payload["period"] as? Int,
      let subject = payload["subject"] as? String,
      let startAt = date(payload["startAt"]),
      let endAt = date(payload["endAt"]),
      let progress = payload["progress"] as? Double,
      let pictogramKey = payload["pictogramKey"] as? String
    else { return nil }

    return SchoolDashLiveActivityAttributes.ContentState(
      situation: situation,
      period: period,
      subject: subject,
      startAt: startAt,
      endAt: endAt,
      progress: progress,
      pictogramKey: pictogramKey,
      nextPeriod: payload["nextPeriod"] as? Int,
      nextSubject: payload["nextSubject"] as? String
    )
  }

  private static func date(_ value: Any?) -> Date? {
    guard let value = value as? String else { return nil }
    return ISO8601DateFormatter().date(from: value)
  }
}
