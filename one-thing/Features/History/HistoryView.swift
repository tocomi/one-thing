import SwiftUI

/// 月ごとの達成・休息履歴を表示するシート。
struct HistoryView: View {
    /// 曜日ヘッダーとカレンダー本体で共有する 7 列の Grid 定義。
    private static let calendarColumns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 7
    )

    /// カレンダーの左右余白。月ページは端まで広げ、中身だけをこの幅で寄せる。
    private static let horizontalPadding: CGFloat = 20

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: HistoryViewModel

    /// 履歴画面で利用する ViewModel を受け取る。
    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                content
            }
            // スワイプでもボタンでも、表示中の月が変わったらその月を読み込む。
            .task(id: viewModel.displayedMonth) {
                await viewModel.loadDisplayedMonthIfNeeded()
            }
            .sheet(item: $viewModel.selectedDay) { day in
                daySheet(for: day)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("これまで")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// 選んだ日のシートを組み立てる。編集できない今日は読み取り専用の表示にする。
    @ViewBuilder
    private func daySheet(for day: HistoryCalendarDay) -> some View {
        let dateText = day.date.map { viewModel.dayText(for: $0) } ?? ""

        if viewModel.isEditable(day) {
            HistoryDetailView(
                dateText: dateText,
                day: day,
                isSaving: viewModel.isSaving,
                errorMessage: viewModel.errorMessage
            ) { date, title, status in
                await viewModel.saveHistoryDay(
                    date: date,
                    title: title,
                    status: status
                )
            } delete: { date in
                await viewModel.deleteHistoryDay(date: date)
            }
        } else {
            HistoryDaySummaryView(dateText: dateText, thing: day.thing)
        }
    }

    private var content: some View {
        VStack(spacing: 18) {
            monthHeader
                .padding(.horizontal, Self.horizontalPadding)
            weekdayHeader
                .padding(.horizontal, Self.horizontalPadding)
            monthPages
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// 月ごとのページを左右スワイプで送れるようにする。未来の月はページ自体を持たない。
    /// ページ幅を画面幅に固定しているため、読み込み完了で中身が入れ替わってもページ位置はずれない。
    private var monthPages: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(viewModel.months, id: \.self) { month in
                    monthPage(for: month)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: displayedMonthBinding)
        // 今月は月ページ一覧の末尾にあるため、初期表示は末尾に合わせる。
        .defaultScrollAnchor(.trailing)
    }

    /// 月ページの位置と表示中の月を双方向でつなぐ。スワイプでの着地とボタン操作の両方がここを通る。
    private var displayedMonthBinding: Binding<Date?> {
        Binding(
            get: { viewModel.displayedMonth },
            set: { month in
                guard let month else {
                    return
                }

                viewModel.displayedMonth = month
            }
        )
    }

    @ViewBuilder
    private func monthPage(for month: Date) -> some View {
        if let days = viewModel.days(for: month) {
            calendarGrid(days: days)
                .padding(.horizontal, Self.horizontalPadding)
        } else if let errorMessage = viewModel.loadError(for: month) {
            Text(errorMessage)
                .font(.subheadline)
                .foregroundStyle(Color.appSecondary)
                .multilineTextAlignment(.center)
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ProgressView()
                .tint(Color.appAccent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func calendarGrid(days: [HistoryCalendarDay]) -> some View {
        LazyVGrid(columns: Self.calendarColumns, spacing: 10) {
            ForEach(days) { day in
                HistoryDayCell(day: day) {
                    guard day.date != nil, !day.isFuture else {
                        return
                    }

                    viewModel.selectedDay = day
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            monthButton(systemName: "chevron.left", accessibilityLabel: "前の月") {
                viewModel.moveToPreviousMonth()
            }
            .disabled(!viewModel.canMoveToPreviousMonth)

            Spacer()

            Text(viewModel.monthText)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.appPrimary)

            Spacer()

            monthButton(systemName: "chevron.right", accessibilityLabel: "次の月") {
                viewModel.moveToNextMonth()
            }
            .disabled(!viewModel.canMoveToNextMonth)
        }
        .frame(height: 44)
    }

    /// スワイプが使えない状況でも月を送れるよう、ページ送りと同じ操作をボタンでも提供する。
    private func monthButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.appSecondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: Self.calendarColumns, spacing: 0) {
            ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(Color.appSecondary)
                    .frame(height: 24)
            }
        }
    }
}

// Preview は状態ごとに用意しているため HistoryViewPreview.swift にまとめている。
