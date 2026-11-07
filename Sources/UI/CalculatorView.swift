import SwiftUI

/// Tab 2 — the enchantment calculator.
struct CalculatorView: View {
    @EnvironmentObject private var model: CrackerModel

    var body: some View {
        MCScreen {
            MCPageHeader(symbol: "wand.and.stars",
                         title: L.tabCalculator,
                         subtitle: L.calculatorHint)

            if !model.isSeedKnown {
                seedHintCard
            }

            setupCard
            targetsCard
            calculateSection
            messageSection
            resultSection
            resetSection
        }
    }

    // MARK: - Hint

    private var seedHintCard: some View {
        MCCard(border: Theme.gold.opacity(0.45)) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 5) {
                    Text(L.playerSeedNotFoundTitle)
                        .font(Theme.fontTitle)
                        .foregroundStyle(Theme.gold)
                    Text(L.playerSeedNotFound)
                        .font(Theme.fontBody)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Item setup

    private var setupCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 14) {
                MCCardHeader(symbol: "shippingbox.fill", title: L.itemSetupTitle)

                VStack(alignment: .leading, spacing: 7) {
                    Text(L.materialSection)
                        .font(Theme.fontSection)
                        .foregroundStyle(Theme.textSecondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(model.availableMaterials) { material in
                                MCChip(title: material.displayName,
                                       isSelected: model.material.displayName == material.displayName) {
                                    model.selectMaterial(material)
                                }
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text(L.itemSection)
                        .font(Theme.fontSection)
                        .foregroundStyle(Theme.textSecondary)
                    Menu {
                        ForEach(model.itemOptions, id: \.id) { item in
                            Button(item.displayName) {
                                model.itemID = item.id
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentItemName)
                                .font(Theme.monoBody)
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.accentGreen)
                        }
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.controlFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Theme.cardStroke, lineWidth: 1)
                        )
                    }
                }

                MCDivider()

                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L.maxBookshelves)
                            .font(Theme.fontSection)
                            .foregroundStyle(Theme.textSecondary)
                        MCNumberField(text: $model.maxBookshelvesText, placeholder: "15")
                        Text(L.maxBookshelvesTooltip)
                            .font(Theme.fontCaption)
                            .foregroundStyle(Theme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L.playerLevel)
                            .font(Theme.fontSection)
                            .foregroundStyle(Theme.textSecondary)
                        MCNumberField(text: $model.playerLevelText, placeholder: "30")
                        Text(L.playerLevelTooltip)
                            .font(Theme.fontCaption)
                            .foregroundStyle(Theme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var currentItemName: String {
        for item in model.itemOptions where item.id == model.itemID {
            return item.displayName
        }
        return L.itemPlaceholder
    }

    // MARK: - Targets

    private var targetsCard: some View {
        let options = model.enchantOptions
        return MCCard {
            VStack(alignment: .leading, spacing: 10) {
                MCCardHeader(symbol: "list.bullet", title: L.targetsSection)
                if options.isEmpty {
                    Text(L.noTargetsHint)
                        .font(Theme.fontCaption)
                        .foregroundStyle(Theme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(options) { option in
                        if option.id != options.first?.id {
                            MCDivider()
                        }
                        enchantRow(option)
                    }
                }
            }
        }
    }

    private func enchantRow(_ option: EnchantOption) -> some View {
        let level = model.targets[option.id] ?? 0
        return HStack(spacing: 10) {
            Text(option.name)
                .font(Theme.fontRow)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 8)
            Menu {
                Button(L.noPreference) {
                    model.setTarget(option.id, level: 0)
                }
                Button(L.unwanted) {
                    model.setTarget(option.id, level: -1)
                }
                if option.maxLevel >= 1 {
                    ForEach(1...option.maxLevel, id: \.self) { targetLevel in
                        Button(L.roman(targetLevel)) {
                            model.setTarget(option.id, level: targetLevel)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(targetLabel(for: level))
                        .font(Theme.monoBody)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(targetColor(for: level))
                .padding(.horizontal, 12)
                .frame(minWidth: 92, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.controlFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(targetColor(for: level).opacity(0.35), lineWidth: 1)
                )
            }
        }
        .padding(.vertical, 3)
    }

    private func targetLabel(for level: Int) -> String {
        if level == 0 {
            return L.noPreference
        }
        if level == -1 {
            return L.unwanted
        }
        return L.roman(level)
    }

    private func targetColor(for level: Int) -> Color {
        if level == 0 {
            return Theme.textSecondary
        }
        if level == -1 {
            return Theme.danger
        }
        return Theme.accentGreen
    }

    // MARK: - Calculate

    private var hasTarget: Bool {
        for value in model.targets.values where value != 0 {
            return true
        }
        return false
    }

    private var canCalculate: Bool {
        model.isSeedKnown && hasTarget && !model.isCalculating
    }

    private var calculateSection: some View {
        VStack(spacing: 8) {
            Button {
                model.runCalculator()
            } label: {
                HStack(spacing: 10) {
                    if model.isCalculating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.onAccentGreen))
                    }
                    Text(L.calculate)
                }
            }
            .buttonStyle(MCButtonStyle(kind: .primary))
            .disabled(!canCalculate)
            .opacity(canCalculate ? 1.0 : 0.45)

            Text(L.calculateTooltip)
                .font(Theme.fontCaption)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Message

    private var messageSection: some View {
        Group {
            if !model.calcMessage.isEmpty {
                Text(model.calcMessage)
                    .font(Theme.fontBody)
                    .foregroundStyle(Theme.danger)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.danger.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.danger.opacity(0.35), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Result

    private var resultSection: some View {
        Group {
            if let result = model.calcResult {
                MCCard(border: Theme.accentPurple.opacity(0.45)) {
                    VStack(alignment: .leading, spacing: 10) {
                        MCCardHeader(symbol: "sparkles", title: L.resultSection)
                        MCResultRow(label: L.dropCount, value: result.dropText)
                        MCDivider()
                        MCResultRow(label: L.bookshelvesResult,
                                    value: result.bookshelvesText,
                                    valueColor: Theme.accentBlue)
                        MCDivider()
                        MCResultRow(label: L.slotResult,
                                    value: result.slotText,
                                    valueColor: Theme.gold)
                        Button(L.done) {
                            model.applyResult()
                        }
                        .buttonStyle(MCButtonStyle(kind: .primary))
                        .padding(.top, 4)
                        Text(L.doneTooltip)
                            .font(Theme.fontCaption)
                            .foregroundStyle(Theme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Button(L.resetCalculator) {
            model.resetCalculator()
        }
        .buttonStyle(MCButtonStyle(kind: .secondary))
    }
}
