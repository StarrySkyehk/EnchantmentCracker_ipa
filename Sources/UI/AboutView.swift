import Foundation
import SwiftUI

/// Tab 3 — about / credits / how to use.
struct AboutView: View {
    var body: some View {
        MCScreen {
            hero
            creditsCard
            linksCard
            stepsCard
            licenseCard
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.purpleGreenGradient)
                    .frame(width: 82, height: 82)
                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: Theme.accentPurple.opacity(0.35), radius: 18, x: 0, y: 8)

            Text(L.appName)
                .font(Theme.fontHero)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(L.appNameCN)
                .font(Theme.fontBody)
                .foregroundStyle(Theme.textSecondary)

            MCStatusPill(text: "v" + appVersion, color: Theme.accentGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.9"
    }

    // MARK: - Credits

    private var creditsCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 10) {
                MCCardHeader(symbol: "person.2.fill", title: L.aboutCreditsTitle)
                creditLine(symbol: "star.fill", text: L.aboutCreditOriginal)
                creditLine(symbol: "bolt.fill", text: L.aboutCreditImprovements)
                MCDivider()
                Text(L.aboutBugReport)
                    .font(Theme.fontCaption)
                    .foregroundStyle(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func creditLine(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accentPurple)
                .frame(width: 16, height: 18)
            Text(text)
                .font(Theme.fontBody)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Links

    private var linksCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 10) {
                MCCardHeader(symbol: "link", title: L.aboutLinksTitle)
                linkRow(symbol: "chevron.left.forwardslash.chevron.right",
                        title: "Earthcomputer/EnchantmentCracker",
                        subtitle: L.aboutLinkGithub,
                        url: AboutURL.github)
                MCDivider()
                linkRow(symbol: "play.rectangle.fill",
                        title: L.aboutLinkVideo,
                        subtitle: "youtu.be/hfiTZF0hlzw",
                        url: AboutURL.video)
                MCDivider()
                linkRow(symbol: "photo.on.rectangle",
                        title: L.aboutLinkAlbum,
                        subtitle: "imgur.com/a/oaxCC5x",
                        url: AboutURL.album)
            }
        }
    }

    private func linkRow(symbol: String, title: String, subtitle: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accentGreen)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.fontBody)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(Theme.fontCaption)
                        .foregroundStyle(Theme.textMuted)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Steps

    private var stepsCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 10) {
                MCCardHeader(symbol: "list.number", title: L.aboutStepsTitle)
                ForEach(0..<L.aboutSteps.count, id: \.self) { index in
                    stepRow(index: index, text: L.aboutSteps[index])
                }
            }
        }
    }

    private func stepRow(index: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index + 1)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.onAccentGreen)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Theme.accentGreen))
            Text(text)
                .font(Theme.fontBody)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - License

    private var licenseCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 8) {
                MCCardHeader(symbol: "doc.text.fill", title: L.aboutLicenseTitle)
                Text(L.aboutLicense)
                    .font(Theme.fontCaption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("GPL-3.0")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.accentGreen)
            }
        }
    }

    // MARK: - URLs (from the original "program.about" resource)

    private enum AboutURL {
        static let github = URL(string: "https://github.com/Earthcomputer/EnchantmentCracker")!
        static let video = URL(string: "https://youtu.be/hfiTZF0hlzw")!
        static let album = URL(string: "https://imgur.com/a/oaxCC5x")!
    }
}
