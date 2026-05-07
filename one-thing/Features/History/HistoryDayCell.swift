import SwiftUI

/// 月カレンダーの日付 1 マスを表示する。
struct HistoryDayCell: View {
    let day: HistoryCalendarDay
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                marker

                if let dayNumber = day.dayNumber {
                    Text("\(dayNumber)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(textColor)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .fixedSize()
                        .frame(width: 28, height: 28)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(day.date == nil)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var marker: some View {
        if day.thing?.status == .done {
            Circle()
                .fill(Color.appPrimary)
                .padding(5)
        } else if day.thing?.status == .rested {
            Circle()
                .stroke(Color.appPrimary, lineWidth: 1.5)
                .padding(5)
        }
    }

    private var textColor: Color {
        day.thing?.status == .done ? Color.appBackground : Color.appPrimary
    }

    private var accessibilityLabel: String {
        guard let dayNumber = day.dayNumber else {
            return ""
        }

        switch day.thing?.status {
        case .done:
            return "\(dayNumber)日 できた"
        case .rested:
            return "\(dayNumber)日 休んだ"
        default:
            return "\(dayNumber)日 記録なし"
        }
    }
}

#Preview {
    HStack {
        HistoryDayCell(
            day: HistoryCalendarDay(
                date: Date(),
                dayNumber: 1,
                thing: Thing(title: "散歩する", status: .done)
            ),
            action: {}
        )
        HistoryDayCell(
            day: HistoryCalendarDay(
                date: Date(),
                dayNumber: 2,
                thing: Thing(title: "本を読む", status: .rested)
            ),
            action: {}
        )
        HistoryDayCell(
            day: HistoryCalendarDay(date: Date(), dayNumber: 3, thing: nil),
            action: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}
