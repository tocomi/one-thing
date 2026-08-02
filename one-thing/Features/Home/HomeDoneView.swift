import SwiftUI

/// 今日の Thing を完了した後の称賛と結果を表示する。
struct HomeDoneView: View {
    let thing: Thing
    let dateText: String
    let message: String
    let isAnimationVisible: Bool

    /// 「視差効果を減らす」が有効な環境では、拡大やバウンスを伴う演出を控える。
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Text(dateText)
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(Color.appSecondary)
                .tracking(0.3)
                .frame(height: 44)
                .padding(.top, 20)

            Spacer()

            VStack(spacing: 24) {
                completionMark

                VStack(spacing: 12) {
                    Text(message)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appPrimary)
                        .multilineTextAlignment(.center)
                }

                Text(thing.title)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .frame(maxWidth: 360)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(completionAnimation, value: isAnimationVisible)
    }

    /// 完了直後に軽く広がるモノクロ寄りのチェック表現。
    private var completionMark: some View {
        ZStack {
            Circle()
                .stroke(Color.appAccent.opacity(isAnimationVisible ? 0.0 : 0.18), lineWidth: 1.5)
                .frame(width: ringDiameter, height: ringDiameter)
                .scaleEffect(ringScale)

            Circle()
                .fill(Color.appAccentSubtle)
                .frame(width: 74, height: 74)

            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.appAccent)
                .scaleEffect(checkmarkScale)
        }
        .frame(width: 112, height: 112)
    }

    // MARK: - Motion

    // Reduce Motion 時は拡大量を打ち消して基準値に固定する。輪郭の opacity だけは
    // 動かしたままにして、完了したことが伝わる手がかりを残す。

    /// バウンスは Reduce Motion で不快になりやすいため、跳ねない曲線に落とす。
    private var completionAnimation: Animation {
        reduceMotion
            ? .easeInOut(duration: 0.35)
            : .spring(duration: 0.55, bounce: 0.2)
    }

    private var ringDiameter: CGFloat {
        isAnimationVisible && !reduceMotion ? 104 : 68
    }

    private var ringScale: CGFloat {
        isAnimationVisible && !reduceMotion ? 1.08 : 1.0
    }

    private var checkmarkScale: CGFloat {
        isAnimationVisible && !reduceMotion ? 1.18 : 1.0
    }
}

// Reduce Motion は読み取り専用の環境値で Preview から注入できないため、
// 実機・シミュレータの「設定 > アクセシビリティ > 動作」で切り替えて確認する。
#Preview {
    HomeDoneView(
        thing: Thing(title: "散歩する", status: .done),
        dateText: "5月7日 (木)",
        message: "ひとつ、できた。",
        isAnimationVisible: true
    )
    .background(Color.appBackground)
}
