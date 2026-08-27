import ActivityKit

@available(iOS 16.1, *)
struct SchoolDashLiveActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    let period: Int
    let subject: String
    let remainingMinutes: Int
    let progress: Double
    let nextPeriod: Int?
    let nextSubject: String?
  }
}
