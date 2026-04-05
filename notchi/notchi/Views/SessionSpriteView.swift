import SwiftUI

struct SessionSpriteView: View {
    let state: NotchiState
    let isSelected: Bool
    var size: CGFloat = 16
    var role: MascotVisualRole = .status
    private var bobAmplitude: CGFloat {
        guard state.bobAmplitude > 0 else { return 0 }
        return isSelected ? state.bobAmplitude : state.bobAmplitude * 0.67
    }

    private static let sobTrembleAmplitude: CGFloat = 0.2

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: bobAmplitude == 0 && state.emotion != .sob)) { timeline in
            SymbolMascotView(state: state, size: size, role: role)
            .offset(
                x: trembleOffset(at: timeline.date, amplitude: state.emotion == .sob ? Self.sobTrembleAmplitude : 0),
                y: 0
            )
        }
    }
}
