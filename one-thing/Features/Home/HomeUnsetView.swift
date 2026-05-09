import SwiftUI

/// 今日のことが未設定のときに入力欄と履歴サジェストを表示する。
struct HomeUnsetView: View {
    let dateText: String
    let promptText: String
    @Binding var draftTitle: String
    let suggestions: [String]
    let canSubmitDraft: Bool
    let isSubmitting: Bool
    let selectSuggestion: (String) -> Void
    let submitDraft: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            dateLabel
                .padding(.top, 20)

            Spacer()

            VStack(spacing: 20) {
                Text(promptText)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
                    .multilineTextAlignment(.center)

                ThingTextField(placeholder: "今日やること...", text: $draftTitle)

                if shouldShowSuggestions {
                    suggestionArea
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            PrimaryActionButton(title: "決めた！") {
                submitDraft()
            }
            .disabled(!canSubmitDraft || isSubmitting)
            .padding(.horizontal, 32)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(duration: 0.32, bounce: 0.0), value: shouldShowSuggestions)
    }

    private var shouldShowSuggestions: Bool {
        draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !suggestions.isEmpty
    }

    private var dateLabel: some View {
        Text(dateText)
            .font(.system(.title3, design: .rounded, weight: .medium))
            .foregroundStyle(Color.appSecondary)
            .tracking(0.3)
            .frame(height: 44)
    }

    private var suggestionArea: some View {
        VStack(spacing: 12) {
            Text("前にもやったこと、またやってみる？")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Color.appSecondary)
                .multilineTextAlignment(.center)

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        selectSuggestion(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.appAccentSubtle, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(suggestion)を入力")
                }
            }
        }
    }
}

/// 子 View を横方向に並べ、収まらない分を次の行へ折り返すレイアウト。
struct FlowLayout: Layout {
    let spacing: CGFloat
    let rowSpacing: CGFloat

    /// チップ同士の間隔を受け取る。
    init(spacing: CGFloat = 8, rowSpacing: CGFloat = 8) {
        self.spacing = spacing
        self.rowSpacing = rowSpacing
    }

    /// 折り返しを考慮して必要な全体サイズを返す。
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let rows = makeRows(
            proposal: proposal,
            subviews: subviews
        )

        return CGSize(
            width: rows.map(\.width).max() ?? 0,
            height: rows.last.map { $0.yOffset + $0.height } ?? 0
        )
    }

    /// 計算した行ごとの配置に従って子 View を置く。
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let rows = makeRows(
            proposal: ProposedViewSize(width: bounds.width, height: proposal.height),
            subviews: subviews
        )

        for row in rows {
            var x = bounds.minX + max((bounds.width - row.width) / 2, 0)

            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: x, y: bounds.minY + row.yOffset),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
        }
    }

    private func makeRows(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> [FlowLayoutRow] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [FlowLayoutRow] = []
        var currentRow = FlowLayoutRow()

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextWidth = currentRow.items.isEmpty
                ? size.width
                : currentRow.width + spacing + size.width

            if nextWidth > maxWidth, !currentRow.items.isEmpty {
                rows.append(currentRow)
                currentRow = FlowLayoutRow(yOffset: currentRow.yOffset + currentRow.height + rowSpacing)
            }

            currentRow.append(item: FlowLayoutItem(subview: subview, size: size), spacing: spacing)
        }

        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

private struct FlowLayoutItem {
    let subview: LayoutSubview
    let size: CGSize
}

private struct FlowLayoutRow {
    var items: [FlowLayoutItem] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
    var yOffset: CGFloat = 0

    mutating func append(item: FlowLayoutItem, spacing: CGFloat) {
        width += items.isEmpty ? item.size.width : spacing + item.size.width
        height = max(height, item.size.height)
        items.append(item)
    }
}
