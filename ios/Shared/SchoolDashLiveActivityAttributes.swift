import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct SchoolDashLiveActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    let situation: String
    let period: Int
    let subject: String
    let startAt: Date
    let endAt: Date
    let progress: Double
    let pictogramKey: String
    let nextPeriod: Int?
    let nextSubject: String?
  }
}
