import SwiftUI

/// 月ごとの達成・休息履歴を表示するシート。
struct HistoryView: View {
    /// 曜日ヘッダーとカレンダー本体で共有する 7 列の Grid 定義。
    private static let calendarColumns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 7
    )

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
            .task {
                await viewModel.load()
            }
            .sheet(item: $viewModel.selectedDay) { day in
                HistoryDetailView(
                    dateText: day.date.map { viewModel.dayText(for: $0) } ?? "",
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

    /// 月移動中でもヘッダーは残し、その下だけを読み込み・エラー・カレンダーで切り替える。
    private var content: some View {
        VStack(spacing: 18) {
            monthHeader
            calendarBody
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var calendarBody: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(Color.appAccent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.subheadline)
                .foregroundStyle(Color.appSecondary)
                .multilineTextAlignment(.center)
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 18) {
                weekdayHeader
                calendarGrid
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Self.calendarColumns, spacing: 10) {
            ForEach(viewModel.days) { day in
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
                await viewModel.moveToPreviousMonth()
            }
            .disabled(!viewModel.canMoveToPreviousMonth)

            Spacer()

            Text(viewModel.monthText)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.appPrimary)

            Spacer()

            monthButton(systemName: "chevron.right", accessibilityLabel: "次の月") {
                await viewModel.moveToNextMonth()
            }
            .disabled(!viewModel.canMoveToNextMonth)
        }
        .frame(height: 44)
    }

    private func monthButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task {
                await action()
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

#Preview {
    let calendar = Calendar.autoupdatingCurrent
    let today = calendar.startOfDay(for: Date())
    let repository = InMemoryThingRepository(
        things: [
            Thing(date: today, title: "散歩する", status: .done),
            Thing(date: calendar.date(byAdding: .day, value: -1, to: today) ?? today, title: "本を読む", status: .rested)
        ]
    )

    HistoryView(
        viewModel: HistoryViewModel(
            loadHistoryUseCase: LoadHistoryUseCase(repository: repository),
            editHistoryUseCase: EditHistoryUseCase(
                repository: repository
            ),
            deleteHistoryUseCase: DeleteHistoryUseCase(
                repository: repository
            )
        )
    )
}
