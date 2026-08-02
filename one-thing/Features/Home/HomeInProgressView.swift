import SwiftUI

/// 今日のことが進行中のときに、タスク本文の表示・編集と完了操作を提供する。
struct HomeInProgressView: View {
    let thing: Thing
    let dateText: String
    @Binding var editingTitle: String
    let isEditingTitle: Bool
    let canSaveEditingTitle: Bool
    let isSubmitting: Bool
    let startEditingTitle: () -> Void
    let cancelEditingTitle: () -> Void
    let saveEditingTitle: () -> Void
    let completeThing: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            dateLabel
                .padding(.top, 20)

            Spacer()

            Group {
                if isEditingTitle {
                    editingArea
                        .transition(.opacity)
                } else {
                    taskHero
                        .transition(.opacity)
                }
            }
            .animation(.spring(duration: 0.32, bounce: 0.0), value: isEditingTitle)

            Spacer()

            if !isEditingTitle {
                PrimaryActionButton(title: "できた！") {
                    completeThing()
                }
                .disabled(isSubmitting)
                .padding(.horizontal, 32)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// タスクタイトルをヒーローとして大きく表示する。表示領域全体が編集への導線になる。
    private var taskHero: some View {
        Button(action: startEditingTitle) {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("今日のやること")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.appSecondary)
                        .tracking(0.3)

                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(maxWidth: 180, maxHeight: 1)
                }

                Text(thing.title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .frame(maxWidth: 380)

                // タップできることを静かに示すだけの手がかり。単独のボタンには見せない。
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appSecondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("今日のやること、\(thing.title)")
        .accessibilityHint("タップして編集")
        .padding(.horizontal, 32)
    }

    /// 進行中タスクのタイトルを編集する入力欄と操作ボタン。
    private var editingArea: some View {
        VStack(spacing: 20) {
            Text("今日のやること")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Color.appSecondary)
                .tracking(0.3)

            ThingTextField(accessibilityLabel: "今日のやること", text: $editingTitle)

            HStack(spacing: 14) {
                Button("キャンセル") {
                    cancelEditingTitle()
                }
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Color.appSecondary)
                .disabled(isSubmitting)

                Button {
                    saveEditingTitle()
                } label: {
                    Text("保存")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 11)
                        .background(Color.appAccent, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSaveEditingTitle)
            }
        }
        .padding(.horizontal, 32)
    }

    private var dateLabel: some View {
        Text(dateText)
            .font(.system(.title3, design: .rounded, weight: .medium))
            .foregroundStyle(Color.appSecondary)
            .tracking(0.3)
            .frame(height: 44)
    }
}

#Preview {
    @Previewable @State var editingTitle = ""

    HomeInProgressView(
        thing: Thing(title: "散歩する", status: .inProgress),
        dateText: "5月7日 (木)",
        editingTitle: $editingTitle,
        isEditingTitle: false,
        canSaveEditingTitle: false,
        isSubmitting: false,
        startEditingTitle: {},
        cancelEditingTitle: {},
        saveEditingTitle: {},
        completeThing: {}
    )
    .background(Color.appBackground)
}
