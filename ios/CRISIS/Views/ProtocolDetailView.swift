import SwiftUI

struct ProtocolDetailView: View {
    let `protocol`: CrisisProtocol
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    quicknav(proxy: proxy)

                    VStack(alignment: .leading, spacing: 18) {
                        Text(`protocol`.kicker.uppercased())
                            .font(AppFont.mono(11, weight: .semibold))
                            .foregroundStyle(Theme.teal)
                        Text(`protocol`.title)
                            .font(AppFont.display(22))
                            .foregroundStyle(Theme.text)
                        Text(`protocol`.subtitle)
                            .font(AppFont.serif(14, italic: true))
                            .foregroundStyle(Theme.text2)
                        HStack(spacing: 8) {
                            ForEach(`protocol`.badges, id: \.text) { BadgeView(badge: $0) }
                        }

                        if let lastVerified = `protocol`.lastVerified {
                            ReviewMetaView(lastVerified: lastVerified) {
                                if let url = ContentConfig.issueURL(kind: `protocol`.type, id: `protocol`.id, title: `protocol`.title, lastVerified: lastVerified) {
                                    openURL(url)
                                }
                            }
                        }

                        ForEach(`protocol`.sections) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Text(section.num)
                                        .font(AppFont.mono(11))
                                        .foregroundStyle(Theme.text3)
                                    Text(section.title)
                                        .font(AppFont.display(16))
                                        .foregroundStyle(Theme.text)
                                }
                                .padding(.vertical, 10).padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    LinearGradient(colors: [Theme.tint(section.color), .clear], startPoint: .leading, endPoint: .trailing)
                                )
                                .overlay(alignment: .leading) {
                                    Rectangle().fill(Theme.color(section.color)).frame(width: 4)
                                }
                                .id(section.id)

                                if let tagline = section.tagline, !tagline.isEmpty {
                                    Text(tagline)
                                        .font(AppFont.serif(13, italic: true))
                                        .foregroundStyle(Theme.text2)
                                }

                                SectionBlocksView(blocks: section.blocks)
                            }
                        }

                        Text(`protocol`.footer)
                            .font(AppFont.serif(12, italic: true))
                            .foregroundStyle(Theme.text3)
                            .padding(.top, 20)
                    }
                    .padding(18)
                }
            }
        }
        .background(Theme.bg)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func quicknav(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(`protocol`.sections) { section in
                    Button {
                        withAnimation { proxy.scrollTo(section.id, anchor: .top) }
                    } label: {
                        Text(section.title)
                            .font(AppFont.mono(11))
                            .padding(.horizontal, 11).padding(.vertical, 6)
                            .foregroundStyle(Theme.text2)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border))
                    }
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 9)
        }
        .background(Theme.bg.opacity(0.92))
    }
}
