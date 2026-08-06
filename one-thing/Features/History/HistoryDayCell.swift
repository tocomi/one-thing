import SwiftUI

/// 月カレンダーの日付 1 マスを表示する。
struct HistoryDayCell: View {
    let day: HistoryCalendarDay
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                todayMarker

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

                statusIcon
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(day.date == nil || day.isFuture)
        .opacity(day.isFuture ? 0.36 : 1)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var todayMarker: some View {
        if day.isToday {
            Circle()
                .fill(Color.appAccentSubtle)
                .overlay {
                    Circle()
                        .stroke(Color.appAccent.opacity(0.45), lineWidth: 1)
                }
                .frame(width: 28, height: 28)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if day.thing?.status == .done {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .frame(width: 14, height: 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(4)
        } else if day.thing?.status == .rested {
            Image(systemName: "pause.circle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.appSecondary)
                .frame(width: 14, height: 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(4)
        }
    }

    private var accessibilityLabel: String {
        guard let dayNumber = day.dayNumber else {
            return ""
        }

        if day.isFuture {
            return "\(dayNumber)日 未来"
        }

        return "\(dayNumber)日 \(HistoryResultText.text(for: day.thing?.status))"
    }

    private var textColor: Color {
        day.isFuture ? Color.appSecondary : Color.appPrimary
    }
}

#Preview {
    HStack {
        HistoryDayCell(
            day: HistoryCalendarDay(
                date: Date(),
                dayNumber: 1,
                thing: ThingSnapshot(title: "散歩する", status: .done),
                isToday: true,
                isFuture: false
            ),
            action: {}
        )
        HistoryDayCell(
            day: HistoryCalendarDay(
                date: Date(),
                dayNumber: 2,
                thing: ThingSnapshot(title: "本を読む", status: .rested),
                isToday: false,
                isFuture: false
            ),
            action: {}
        )
        HistoryDayCell(
            day: HistoryCalendarDay(date: Date(), dayNumber: 3, thing: nil, isToday: false, isFuture: true),
            action: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}
