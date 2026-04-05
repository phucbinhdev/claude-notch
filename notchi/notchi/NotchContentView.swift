import SwiftUI

enum NotchConstants {
    static let expandedPanelSize = CGSize(width: 450, height: 450)
    static let expandedPanelHorizontalPadding: CGFloat = 19 * 2
}

extension Notification.Name {
    static let notchiShouldCollapse = Notification.Name("notchiShouldCollapse")
}

private let cornerRadiusInsets = (
    opened: (top: CGFloat(19), bottom: CGFloat(24)),
    closed: (top: CGFloat(6), bottom: CGFloat(14))
)

struct NotchContentView: View {
    var stateMachine: NotchiStateMachine = .shared
    var panelManager: NotchPanelManager = .shared
    var usageService: ClaudeUsageService = .shared
    @ObservedObject private var updateManager = UpdateManager.shared
    @State private var showingPanelSettings = false
    @State private var showingSessionActivity = false
    @State private var isMuted = AppSettings.isMuted
    @State private var isActivityCollapsed = false
    @State private var debugTask: NotchiTask? = nil

    private var sessionStore: SessionStore {
        stateMachine.sessionStore
    }

    private var notchSize: CGSize { panelManager.notchSize }
    private var isExpanded: Bool { panelManager.isExpanded }

    private var panelAnimation: Animation {
        isExpanded
            ? .spring(response: 0.42, dampingFraction: 0.8)
            : .spring(response: 0.45, dampingFraction: 1.0)
    }

    private var sideWidth: CGFloat {
        max(0, notchSize.height - 12) + 24
    }

    private var primaryTask: NotchiTask {
        sessionStore.sortedSessions.first?.state.task ?? .idle
    }

    private var isNormalState: Bool {
        primaryTask == .idle
    }

    private var collapsedNotchHeight: CGFloat {
        max(0, notchSize.height - 4)
    }

    private let collapsedIconSlotWidth: CGFloat = 28

    private var leftCompanionWidth: CGFloat {
        guard !isExpanded else { return sideWidth }
        return collapsedIconSlotWidth
    }

    private var rightStatusWidth: CGFloat {
        guard !isExpanded else { return sideWidth }
        return collapsedIconSlotWidth
    }

    private var leftCompanionOffsetX: CGFloat {
        guard !isExpanded else { return -15 }
        return -6
    }

    private var rightStatusOffsetX: CGFloat {
        guard !isExpanded else { return 15 }
        return 6
    }

    private var topCornerRadius: CGFloat {
        isExpanded ? cornerRadiusInsets.opened.top : cornerRadiusInsets.closed.top
    }

    private var bottomCornerRadius: CGFloat {
        isExpanded ? cornerRadiusInsets.opened.bottom : cornerRadiusInsets.closed.bottom
    }

    /// Uses the system notch curve in collapsed mode when available.
    private var notchClipShape: AnyShape {
        if !isExpanded, let systemPath = panelManager.systemNotchPath {
            return AnyShape(SystemNotchShape(cgPath: systemPath))
        }
        return AnyShape(NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        ))
    }

    private var shouldShowBackButton: Bool {
        showingPanelSettings ||
        (sessionStore.activeSessionCount >= 2 && showingSessionActivity)
    }

    private var expandedPanelHeight: CGFloat {
        let fullHeight = NotchConstants.expandedPanelSize.height - notchSize.height - 24
        let collapsedHeight: CGFloat = 155
        return isActivityCollapsed ? collapsedHeight : fullHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            notchLayout
        }
        .padding(.horizontal, isExpanded ? cornerRadiusInsets.opened.top : cornerRadiusInsets.closed.bottom)
        .padding(.bottom, isExpanded ? 12 : 0)
        .background {
            Color.black
        }
        .clipShape(notchClipShape)
        .shadow(
            color: isExpanded ? .black.opacity(0.7) : .clear,
            radius: 6
        )
        .opacity(hasSessions || isExpanded ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: hasSessions)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(panelAnimation, value: isExpanded)
        .onReceive(NotificationCenter.default.publisher(for: .notchiShouldCollapse)) { _ in
            panelManager.collapse()
        }
        .onChange(of: isExpanded) { _, expanded in
            if !expanded {
                showingPanelSettings = false
                showingSessionActivity = false
            }
        }
        .onChange(of: sessionStore.activeSessionCount) { _, count in
            if count < 2 {
                showingSessionActivity = false
            }
        }
    }

    @ViewBuilder
    private var notchLayout: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                    .frame(height: isExpanded ? notchSize.height : collapsedNotchHeight)

                if isExpanded {
                    ExpandedPanelView(
                        sessionStore: sessionStore,
                        usageService: usageService,
                        showingSettings: $showingPanelSettings,
                        showingSessionActivity: $showingSessionActivity,
                        isActivityCollapsed: $isActivityCollapsed
                    )
                    .frame(
                        width: NotchConstants.expandedPanelSize.width - 48,
                        height: expandedPanelHeight
                    )
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.8, anchor: .top)
                                .combined(with: .opacity)
                                .animation(.smooth(duration: 0.35)),
                            removal: .opacity.animation(.easeOut(duration: 0.15))
                        )
                    )
                }
            }

            if isExpanded {
                HStack {
                    if shouldShowBackButton {
                        backButton
                            .padding(.leading, 15)
                    } else {
                        HStack(spacing: 8) {
                            PanelHeaderButton(
                                sfSymbol: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                                action: toggleMute
                            )
                        }
                        .padding(.leading, 12)
                    }
                    Spacer()
                    headerButtons
                }
                .padding(.top, 4)
                .padding(.horizontal, 8)
                .frame(width: NotchConstants.expandedPanelSize.width - 48)
            }
        }
    }

    private var headerButtons: some View {
        HStack(spacing: 8) {
            PanelHeaderButton(
                sfSymbol: "gearshape.fill",
                showsIndicator: updateManager.hasPendingUpdate,
                action: { showingPanelSettings = true }
            )
        }
        .padding(.trailing, 8)
    }

    private var backButton: some View {
        Button(action: goBack) {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
                Text("Back")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.7))
        }
        .buttonStyle(.plain)
    }

    private func goBack() {
        if showingPanelSettings {
            showingPanelSettings = false
        } else if showingSessionActivity {
            showingSessionActivity = false
            sessionStore.selectSession(nil)
        }
    }

    private var hasSessions: Bool {
        sessionStore.activeSessionCount > 0
    }

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: 0) {
            companionSprite
                .offset(x: leftCompanionOffsetX)
                .frame(width: leftCompanionWidth, height: collapsedNotchHeight)
                .animation(.none)
                .opacity(isExpanded ? 0 : (hasSessions ? 1 : 0))
                .animation(.snappy(duration: 0.2), value: hasSessions)

            Color.clear
                .frame(width: notchSize.width - cornerRadiusInsets.closed.top)

            sessionCountBadge
                .offset(x: rightStatusOffsetX, y: 0)
                .frame(width: rightStatusWidth)
                .opacity(isExpanded ? 0 : (hasSessions ? 1 : 0))
                .animation(.snappy(duration: 0.2), value: hasSessions)
        }
    }

    @ViewBuilder
    private var sessionCountBadge: some View {
        let count = sessionStore.activeSessionCount
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 16, height: 16)
            Text("\(count)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    @ViewBuilder
    private var companionSprite: some View {
        let topSession = sessionStore.sortedSessions.first
        CollapsedMascotView(task: debugTask ?? topSession?.state.task ?? .idle)
    }

    private func toggleMute() {
        AppSettings.toggleMute()
        isMuted = AppSettings.isMuted
    }
}

#Preview {
    NotchContentView()
        .frame(width: 400, height: 200)
}
