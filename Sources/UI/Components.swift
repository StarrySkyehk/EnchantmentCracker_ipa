import SwiftUI
import UIKit

// MARK: - Keyboard

enum KeyboardHelper {
    /// Resigns the current first responder, hiding the software keyboard.
    static func dismiss() {
        Task { @MainActor in
            _ = UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                to: nil,
                                                from: nil,
                                                for: nil)
        }
    }
}

extension View {
    /// Adds the "完成" button above the keyboard (iOS shows it as an accessory bar).
    func mcKeyboardToolbar() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    KeyboardHelper.dismiss()
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accentGreen)
            }
        }
    }
}

// MARK: - Cards

struct MCCardBackground: View {
    var border: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Theme.cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(border, lineWidth: 1)
            )
    }
}

/// A rounded, subtly stroked panel — the basic building block of every screen.
struct MCCard<Content: View>: View {
    private let border: Color
    private let content: Content

    init(border: Color = Theme.cardStroke, @ViewBuilder content: () -> Content) {
        self.border = border
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MCCardBackground(border: border))
    }
}

// MARK: - Screen scaffold

/// Shared scroll container: gradient backdrop, centred column that stays
/// readable on iPad and never clips on small screens.
struct MCScreen<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.backdrop.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .toolbarBackground(Theme.backgroundDeep, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

// MARK: - Small pieces

struct MCDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
    }
}

struct MCCardHeader: View {
    let symbol: String
    let title: String
    var accessory: String = ""

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.accentGreen)
                .frame(width: 18)
            Text(title)
                .font(Theme.fontSection)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 8)
            if !accessory.isEmpty {
                Text(accessory)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }
}

struct MCStatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.16)))
            .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
    }
}

struct MCResultRow: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.accentGreen

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(Theme.fontBody)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 8)
            Text(value)
                .font(Theme.monoTitle)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Inputs

/// Flexible numeric text field: fixed minimum 48pt touch target, monospaced digits.
struct MCNumberField: View {
    @Binding var text: String
    var placeholder: String = "0"

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(Theme.monoField)
            .foregroundStyle(Theme.textPrimary)
            .tint(Theme.accentGreen)
            .frame(maxWidth: .infinity, minHeight: 48)
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

/// Uppercase hex text field used for XP seeds and the player seed.
struct MCHexField: View {
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.asciiCapable)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .multilineTextAlignment(.center)
            .font(Theme.monoBody)
            .foregroundStyle(Theme.textPrimary)
            .tint(Theme.accentPurple)
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

/// Label + grey tooltip line on the left, any control on the right.
struct MCFieldRow<Field: View>: View {
    let label: String
    let tooltip: String
    private let field: Field

    init(label: String, tooltip: String, @ViewBuilder field: () -> Field) {
        self.label = label
        self.tooltip = tooltip
        self.field = field()
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(Theme.fontRow)
                    .foregroundStyle(Theme.textPrimary)
                if !tooltip.isEmpty {
                    Text(tooltip)
                        .font(Theme.fontCaption)
                        .foregroundStyle(Theme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            field
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Chips

struct MCChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Theme.onAccentGreen : Theme.textSecondary)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Theme.accentGreen : Theme.controlFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? Theme.accentGreen.opacity(0.9) : Theme.cardStroke,
                                lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Button styles

struct MCButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case danger
    }

    var kind: Kind = .primary

    private func palette(for kind: Kind) -> (top: Color, bottom: Color, text: Color, border: Color) {
        switch kind {
        case .primary:
            return (Theme.accentGreen, Theme.accentGreenDeep,
                    Theme.onAccentGreen, Theme.accentGreen.opacity(0.55))
        case .secondary:
            return (Theme.controlFill, Theme.cardFill,
                    Theme.textPrimary, Color.white.opacity(0.14))
        case .danger:
            return (Theme.danger, Theme.dangerDeep,
                    Color.white, Theme.danger.opacity(0.55))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        let palette = self.palette(for: kind)
        return configuration.label
            .font(Theme.fontButton)
            .foregroundStyle(palette.text)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [palette.top, palette.bottom],
                                         startPoint: .top,
                                         endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
    }
}

// MARK: - Page header

struct MCPageHeader: View {
    let symbol: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.purpleGreenGradient)
                    .frame(width: 46, height: 46)
                Image(systemName: symbol)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.fontHero)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(Theme.fontCaption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}
