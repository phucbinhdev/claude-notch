import AppKit
import SwiftUI

enum MascotAnimationPreset {
    case none
    case pulse
}

enum MascotVisualRole {
    case companion
    case status
}

struct MascotSymbolConfiguration {
    let symbolName: String
    let fallbackSymbolName: String
    let tintColor: Color
    let animationPreset: MascotAnimationPreset
}

extension NotchiState {
    func mascotSymbolConfiguration(for role: MascotVisualRole) -> MascotSymbolConfiguration {
        let symbolName: String
        let animationPreset: MascotAnimationPreset

        switch role {
        case .companion:
            symbolName = "apple.logo"
            animationPreset = .none
        case .status:
            switch task {
            case .idle, .sleeping, .compacting:
                symbolName = "dot.circle"
                animationPreset = .none
            case .working:
                symbolName = "ellipsis.message.fill"
                animationPreset = .pulse
            case .waiting:
                symbolName = "questionmark.circle.fill"
                animationPreset = .none
            }
        }

        return MascotSymbolConfiguration(
            symbolName: symbolName,
            fallbackSymbolName: "circle.fill",
            tintColor: stateTintColor(for: role),
            animationPreset: animationPreset
        )
    }

    private func stateTintColor(for role: MascotVisualRole) -> Color {
        switch role {
        case .companion:
            return .white.opacity(0.62)
        case .status:
            switch task {
            case .idle, .sleeping, .compacting:
                return .white.opacity(0.4)
            case .working:
                return .cyan.opacity(0.9)
            case .waiting:
                return .yellow.opacity(0.95)
            }
        }
    }
}

struct SymbolMascotView: View {
    let state: NotchiState
    let size: CGFloat
    var role: MascotVisualRole = .status

    private var config: MascotSymbolConfiguration {
        state.mascotSymbolConfiguration(for: role)
    }

    private var resolvedSymbolName: String {
        if NSImage(systemSymbolName: config.symbolName, accessibilityDescription: nil) != nil {
            return config.symbolName
        }

        if NSImage(systemSymbolName: config.fallbackSymbolName, accessibilityDescription: nil) != nil {
            return config.fallbackSymbolName
        }

        return "circle.fill"
    }

    var body: some View {
        Image(systemName: resolvedSymbolName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(config.tintColor)
            .frame(width: size, height: size)
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(
                .pulse.byLayer,
                options: .repeating,
                isActive: config.animationPreset == .pulse
            )
            .animation(.snappy(duration: 0.28), value: resolvedSymbolName)
    }
}
