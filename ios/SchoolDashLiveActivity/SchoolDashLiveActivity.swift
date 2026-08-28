import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct SchoolDashLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: SchoolDashLiveActivityAttributes.self) { context in
      SchoolDashActivityView(state: context.state)
        .activityBackgroundTint(Color(red: 0.90, green: 0.96, blue: 1.0))
        .activitySystemActionForegroundColor(.blue)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          SchoolDashPictogram(key: context.state.pictogramKey)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(context.state.period)교시")
        }
        DynamicIslandExpandedRegion(.bottom) {
          SchoolDashActivityView(state: context.state)
        }
      } compactLeading: {
        SchoolDashPictogram(key: context.state.pictogramKey)
      } compactTrailing: {
        Text("\(context.state.period)교시")
      } minimal: {
        SchoolDashPictogram(key: context.state.pictogramKey)
      }
    }
  }
}

@available(iOS 16.1, *)
private struct SchoolDashActivityView: View {
  let state: SchoolDashLiveActivityAttributes.ContentState

  var body: some View {
    ZStack(alignment: .bottom) {
      RoundedRectangle(cornerRadius: 18)
        .fill(Color(red: 0.95, green: 0.98, blue: 1.0))
      GeometryReader { proxy in
        SchoolDashWave(progress: state.progress)
          .fill(Color(red: 0.30, green: 0.67, blue: 0.97).opacity(0.36))
          .frame(height: proxy.size.height)
      }
      HStack(spacing: 12) {
        SchoolDashPictogram(key: state.pictogramKey)
          .frame(width: 38, height: 38)
          .background(Color.white, in: Circle())
        VStack(alignment: .leading, spacing: 3) {
          Text("수업 중")
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.blue)
          Text("\(state.period)교시 \(state.subject)")
            .font(.headline.weight(.bold))
            .lineLimit(1)
          Text(timerInterval: state.startAt...state.endAt, countsDown: true)
            .font(.caption.weight(.semibold))
          if let period = state.nextPeriod, let subject = state.nextSubject {
            Text("다음 \(period)교시 \(subject)")
              .font(.caption2)
              .lineLimit(1)
          }
        }
        Spacer(minLength: 0)
      }
      .padding(14)
    }
  }
}

@available(iOS 16.1, *)
private struct SchoolDashPictogram: View {
  let key: String

  var body: some View {
    Image(systemName: switch key {
      case "math": "function"
      case "language": "book.closed.fill"
      case "english": "character.book.closed"
      case "science": "flask.fill"
      case "social": "globe.asia.australia.fill"
      case "sports": "soccerball"
      case "music": "music.note"
      case "art": "paintpalette.fill"
      case "computer": "chevron.left.forwardslash.chevron.right"
      default: "book.closed.fill"
    })
    .foregroundStyle(Color(red: 0.10, green: 0.44, blue: 0.76))
  }
}

@available(iOS 16.1, *)
private struct SchoolDashWave: Shape {
  let progress: Double

  func path(in rect: CGRect) -> Path {
    let top = rect.height * (1 - min(max(progress, 0), 1))
    var path = Path()
    path.move(to: CGPoint(x: 0, y: top))
    for x in stride(from: 0.0, through: rect.width + 1, by: 2) {
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
