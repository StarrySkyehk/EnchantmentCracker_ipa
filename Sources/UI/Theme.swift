import SwiftUI

/// Central palette + typography: iOS-native layout with a Minecraft flavoured
/// dark scheme (obsidian background, grass accent, enchanting purple).
enum Theme {

    // MARK: - Palette

    /// #0D0B14 — near-black obsidian.
    static let background = Color(red: 0.051, green: 0.043, blue: 0.078)
    /// Deeper tone used behind text fields.
    static let backgroundDeep = Color(red: 0.031, green: 0.027, blue: 0.051)
    /// Card surface, a touch lighter than the background.
    static let cardFill = Color(red: 0.098, green: 0.086, blue: 0.165)
    /// Inset control surface inside a card.
    static let controlFill = Color(red: 0.137, green: 0.121, blue: 0.216)
    /// Hairline card border.
    static let cardStroke = Color(red: 1.0, green: 1.0, blue: 1.0).opacity(0.09)

    /// #6BBF4A — grass green.
    static let accentGreen = Color(red: 0.42, green: 0.75, blue: 0.29)
    static let accentGreenDeep = Color(red: 0.22, green: 0.46, blue: 0.15)
    static let onAccentGreen = Color(red: 0.043, green: 0.110, blue: 0.031)
    /// #9A6BFF — enchanting table purple.
    static let accentPurple = Color(red: 0.604, green: 0.42, blue: 1.0)
    /// Lapis blue.
    static let accentBlue = Color(red: 0.35, green: 0.63, blue: 0.95)
    static let danger = Color(red: 0.88, green: 0.35, blue: 0.30)
    static let dangerDeep = Color(red: 0.42, green: 0.13, blue: 0.12)
    static let gold = Color(red: 0.92, green: 0.76, blue: 0.35)

    static let textPrimary = Color(red: 0.93, green: 0.92, blue: 0.97)
    static let textSecondary = Color(red: 0.64, green: 0.62, blue: 0.73)
    static let textMuted = Color(red: 0.45, green: 0.43, blue: 0.54)

    // MARK: - Fonts

    static let fontHero = Font.system(size: 27, weight: .heavy, design: .rounded)
    static let fontTitle = Font.system(size: 19, weight: .bold, design: .rounded)
    static let fontSection = Font.system(size: 13, weight: .bold, design: .rounded)
    static let fontBody = Font.system(size: 15, weight: .regular, design: .rounded)
    static let fontCaption = Font.system(size: 12, weight: .regular, design: .rounded)
    static let fontButton = Font.system(size: 18, weight: .heavy, design: .rounded)
    static let fontRow = Font.system(size: 15, weight: .medium, design: .rounded)

    /// Monospaced digits for seeds, levels and counts.
    static let monoHero = Font.system(size: 24, weight: .bold, design: .monospaced)
    static let monoTitle = Font.system(size: 18, weight: .semibold, design: .monospaced)
    static let monoBody = Font.system(size: 15, weight: .medium, design: .monospaced)
    static let monoField = Font.system(size: 21, weight: .semibold, design: .monospaced)

    // MARK: - Gradients

    static let backdrop = LinearGradient(
        colors: [
            Color(red: 0.086, green: 0.071, blue: 0.149),
            background,
            backgroundDeep
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let greenGradient = LinearGradient(
        colors: [accentGreen, accentGreenDeep],
        startPoint: .top,
        endPoint: .bottom
    )

    static let purpleGreenGradient = LinearGradient(
        colors: [accentPurple, accentGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
