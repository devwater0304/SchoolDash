import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct SchoolDashLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: SchoolDashLiveActivityAttributes.self) { context in
      SchoolDashLiveActivityView(state: context.state)
        .activityBackgroundTint(Color(red: 0.90, green: 0.96, blue: 1.0))
        .activitySystemActionForegroundColor(.blue)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text("\(context.state.period)교시")
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(context.state.remainingMinutes)분")
        }
        DynamicIslandExpandedRegion(.bottom) {
          SchoolDashLiveActivityView(state: context.state)
        }
      } compactLeading: {
        Text("\(context.state.period)")
      } compactTrailing: {
        Text("\(context.state.remainingMinutes)분")
      } minimal: {
        Image(systemName: "book.closed.fill")
      }
    }
  }
}

@available(iOS 16.1, *)
private struct SchoolDashLiveActivityView: View {
  let state: SchoolDashLiveActivityAttributes.ContentState

  var body: some View {
    ZStack(alignment: .bottom) {
      RoundedRectangle(cornerRadius: 18)
        .fill(Color(red: 0.95, green: 0.98, blue: 1.0))
      GeometryReader { proxy in
        SchoolDashWater(progress: state.progress)
          .fill(Color(red: 0.30, green: 0.67, blue: 0.97).opacity(0.32))
          .frame(height: proxy.size.height)
      }
      HStack(spacing: 12) {
        Image(systemName: "book.closed.fill")
          .frame(width: 34, height: 34)
          .background(Color.white, in: Circle())
        VStack(alignment: .leading, spacing: 3) {
          Text("수업 중")
            .font(.caption.weight(.bold))
            .foregroundStyle(.blue)
          Text("\(state.period)교시 \(state.subject)")
            .font(.headline.weight(.bold))
            .lineLimit(1)
          Text("종료까지 \(state.remainingMinutes)분")
            .font(.caption.weight(.semibold))
          if let nextPeriod = state.nextPeriod, let nextSubject = state.nextSubject {
            Text("다음 \(nextPeriod)교시 \(nextSubject)")
              .font(.caption2)
              .lineLimit(1)
          }
        }
        Spacer()
      }
      .padding(14)
    }
  }
}

@available(iOS 16.1, *)
private struct SchoolDashWater: Shape {
  let progress: Double

  func path(in rect: CGRect) -> Path {
    let top = rect.height * (1 - min(max(progress, 0), 1))
    var path = Path()
    path.move(to: CGPoint(x: 0, y: top))
    for x in stride(from: 0.0, through: rect.width, by: 2) {
      let y = top + sin((x / 52) * .pi * 2 + 0.28 * .pi * 2) * 2.5
      path.addLine(to: CGPoint(x: x, y: y))
    }
    path.addLine(to: CGPoint(x: rect.width, y: rect.height))
    path.addLine(to: CGPoint(x: 0, y: rect.height))
    path.closeSubpath()
    return path
  }
}

@main
struct SchoolDashLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    SchoolDashLiveActivity()
  }
}
