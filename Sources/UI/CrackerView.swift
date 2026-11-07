import SwiftUI

/// Tab 1 — the XP seed cracker.
struct CrackerView: View {
    @EnvironmentObject private var model: CrackerModel

    var body: some View {
        MCScreen {
            MCPageHeader(symbol: "hammer.fill",
                         title: L.tabCracker,
                         subtitle: L.crackerHint)
            versionCard
            inputCard
            actionCard
            statusCard
            playerSeedCard
            resetSection
        }
    }

    // MARK: - Version

    private var versionCard: some View {
        MCCard {
            HStack(spacing: 12) {
                Image(systemName: "cube.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.accentPurple)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.gameVersion)
                        .font(Theme.fontSection)
                        .foregroundStyle(Theme.textSecondary)
                    Text(model.version.displayName)
                        .font(Theme.monoBody)
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer(minLength: 8)
                Menu {
                    ForEach(MCVersion.allCases) { version in
                        Button(version.displayName) {
                            model.version = version
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(L.switchVersion)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Theme.accentGreen)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(Theme.accentGreen.opacity(0.14)))
                    .overlay(Capsule().stroke(Theme.accentGreen.opacity(0.40), lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Inputs

    private var inputCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 12) {
                MCCardHeader(symbol: "square.grid.2x2.fill", title: L.inputData)
                MCDivider()
                MCFieldRow(label: L.bookshelves, tooltip: L.bookshelvesTooltip) {
                    MCNumberField(text: $model.bookshelvesText)
                        .frame(width: 104)
                }
                MCDivider()
                MCFieldRow(label: L.slot1, tooltip: L.xpCost1Tooltip) {
                    MCNumberField(text: $model.slot1Text)
                        .frame(width: 104)
                }
                MCDivider()
                MCFieldRow(label: L.slot2, tooltip: L.xpCost2Tooltip) {
                    MCNumberField(text: $model.slot2Text)
                        .frame(width: 104)
                }
                MCDivider()
                MCFieldRow(label: L.slot3, tooltip: L.xpCost3Tooltip) {
                    MCNumberField(text: $model.slot3Text)
                        .frame(width: 104)
                }
            }
        }
    }

    // MARK: - Main action

    private var actionCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 12) {
                if model.isCracking {
                    HStack(spacing: 8) {
                        Text(model.progressText.isEmpty ? L.progressPrefix : model.progressText)
                            .font(Theme.monoBody)
                            .foregroundStyle(Theme.accentGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                        Spacer(minLength: 0)
                    }
                    ProgressView(value: model.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Theme.accentGreen))
                        .scaleEffect(x: 1.0, y: 1.8, anchor: .center)
                        .padding(.vertical, 4)
                    Button(L.cancel) {
                        model.cancelCrack()
                    }
                    .buttonStyle(MCButtonStyle(kind: .secondary))
                } else {
                    Button(L.check) {
                        model.check()
                    }
                    .buttonStyle(MCButtonStyle(kind: .primary))
                    .disabled(!model.canCheck)
                    .opacity(model.canCheck ? 1.0 : 0.45)
                    Text(L.checkTooltip)
                        .font(Theme.fontCaption)
                        .foregroundStyle(Theme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Status

    private var statusCard: some View {
        MCCard(border: statusColor.opacity(0.40)) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: statusSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .frame(width: 26, height: 26)
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.statusTitle)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(statusColor)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    if !model.statusDetail.isEmpty {
                        Text(model.statusDetail)
                            .font(Theme.fontCaption)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var statusColor: Color {
        switch model.status {
        case .found:
            return Theme.accentGreen
        case .impossible:
            return Theme.danger
        case .possible:
            return Theme.accentBlue
        case .running:
            return Theme.accentPurple
        case .idle:
            return Theme.textSecondary
        }
    }

    private var statusSymbol: String {
        switch model.status {
        case .found:
            return "checkmark.seal.fill"
        case .impossible:
            return "xmark.octagon.fill"
        case .possible:
            return "questionmark.circle.fill"
        case .running:
            return "hourglass"
        case .idle:
            return "circle.dashed"
        }
    }

    // MARK: - Player seed

    private var playerSeedCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 12) {
                MCCardHeader(symbol: "key.fill", title: L.playerSeedSection)
                Text(L.playerSeedSectionHint)
                    .font(Theme.fontCaption)
                    .foregroundStyle(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L.xpSeed1)
                            .font(Theme.fontCaption)
                            .foregroundStyle(Theme.textSecondary)
                        MCHexField(text: $model.xpSeed1Text, placeholder: "8 位十六进制")
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L.xpSeed2)
                            .font(Theme.fontCaption)
                            .foregroundStyle(Theme.textSecondary)
                        MCHexField(text: $model.xpSeed2Text, placeholder: "8 位十六进制")
                    }
                }
                Button(L.calculateSeed) {
                    model.calculatePlayerSeed()
                }
                .buttonStyle(MCButtonStyle(kind: .secondary))
                MCDivider()
                HStack(alignment: .bottom, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L.playerSeed)
                            .font(Theme.fontCaption)
                            .foregroundStyle(Theme.textSecondary)
                        MCHexField(text: $model.playerSeedText, placeholder: L.playerSeedPlaceholder)
                    }
                    if !model.playerSeedStatus.isEmpty {
                        MCStatusPill(text: model.playerSeedStatus, color: playerSeedStatusColor)
                            .padding(.bottom, 6)
                    }
                }
            }
        }
    }

    private var playerSeedStatusColor: Color {
        if model.playerSeedStatus == "Success!" {
            return Theme.accentGreen
        }
        if model.playerSeedStatus == "Fail!" {
            return Theme.danger
        }
        return Theme.textSecondary
    }

    // MARK: - Reset

    private var resetSection: some View {
        VStack(spacing: 8) {
            Button(L.reset) {
                model.resetCracker()
            }
            .buttonStyle(MCButtonStyle(kind: .danger))
            Text(L.resetTooltip)
                .font(Theme.fontCaption)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
    }
}
