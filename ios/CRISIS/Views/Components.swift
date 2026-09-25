import SwiftUI

struct BadgeView: View {
    let badge: Badge
    var body: some View {
        Text(badge.text)
            .font(AppFont.mono(10.5))
            .padding(.horizontal, 9).padding(.vertical, 3)
            .foregroundStyle(Theme.color(badge.color))
            .background(Theme.tint(badge.color))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.color(badge.color).opacity(0.3)))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct TagView: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text.uppercased())
            .font(AppFont.mono(9))
            .fontWeight(.semibold)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct ChipView: View {
    let label: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.mono(11))
                .padding(.horizontal, 11).padding(.vertical, 5)
                .foregroundStyle(active ? Theme.bg : Theme.text3)
                .background(active ? Theme.teal : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(active ? Theme.teal : Theme.border))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

/// The card used for protocol / region / species list rows.
struct EntryCard: View {
    let title: String
    let subtitle: String
    var accent: Color = Theme.teal
    var meta: [(String, Color)] = []
    /// "⚡" (protocol) or "✱" (procedure) — shown only where entry types mix
    /// (Home's cross-type search); omitted inside the type-pure Protocols/
    /// HALO tabs since it'd be redundant there.
    var typeIcon: String? = nil

    private var titleText: Text {
        guard let typeIcon else { return Text(title) }
        return Text(typeIcon + " ").foregroundStyle(Theme.text3) + Text(title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            titleText
                .font(AppFont.display(14.5, weight: .bold))
                .foregroundStyle(Theme.text)
            Text(subtitle)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.text2)
                .lineLimit(3)
            if !meta.isEmpty {
                HStack(spacing: 6) {
                    ForEach(meta, id: \.0) { TagView(text: $0.0, color: $0.1) }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
        .overlay(alignment: .leading) {
            Rectangle().fill(accent).frame(width: 3).clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField(placeholder, text: $text)
            .font(AppFont.display(14, weight: .semibold))
            .padding(11)
            .background(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(Theme.text)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    var body: some View {
        VStack(spacing: 10) {
            Text(icon).font(.system(size: 36))
            Text(message).foregroundStyle(Theme.text3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

/// Content Update Architecture, 2026-08-31 — mirrors the web app's
/// .review-meta styling. Shown on protocol/procedure/species detail pages.
struct ReviewMetaView: View {
    let lastVerified: String
    let onFlag: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("Last verified \(lastVerified)")
                .font(AppFont.mono(10.5))
                .foregroundStyle(Theme.text3)
            Button(action: onFlag) {
                Text("Flag as outdated")
                    .font(AppFont.mono(10.5))
                    .foregroundStyle(Theme.text3)
                    .underline(true, color: Theme.text3)
            }
        }
    }
}

struct PageHeader: View {
    let kicker: String
    let title: String
    let lede: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !kicker.isEmpty {
                Text(kicker.uppercased())
                    .font(AppFont.mono(11, weight: .semibold))
                    .foregroundStyle(Theme.teal)
            }
            Text(title)
                .font(AppFont.display(24))
                .foregroundStyle(Theme.text)
            Text(lede)
                .font(AppFont.serif(14, italic: true))
                .foregroundStyle(Theme.text2)
        }
        .padding(.bottom, 12)
    }
}
