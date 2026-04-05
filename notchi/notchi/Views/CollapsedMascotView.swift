import SwiftUI

struct CollapsedMascotView: View {
    let task: NotchiTask

    private var isActive: Bool {
        task == .working || task == .compacting || task == .waiting
    }

    private var symbolColor: Color {
        switch task {
        case .working:    return TerminalColors.claudeOrange
        case .compacting: return TerminalColors.amber
        case .waiting:    return .yellow.opacity(0.95)
        default:          return .white.opacity(0.5)
        }
    }

    private var spinDuration: Double {
        task == .waiting ? 3.0 : 1.4
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !isActive)) { timeline in
            let angle = isActive
                ? (timeline.date.timeIntervalSinceReferenceDate / spinDuration)
                    .truncatingRemainder(dividingBy: 1.0) * 360
                : 0.0

            Text("✻")
                .font(.system(size: isActive ? 17 : 14, weight: .regular, design: .monospaced))
                .foregroundColor(symbolColor)
                .rotationEffect(.degrees(angle))
                .frame(width: 30, height: 30)
                .offset(y: -2)
        }
    }
}
