import SwiftUI

/// 設定シートの入口となる画面。
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SettingsViewModel

    /// 設定シートで利用する ViewModel を受け取る。
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("通知") {
                    Toggle(
                        "通知を受け取る",
                        isOn: notificationToggleBinding
                    )
                    DatePicker(
                        "朝の通知",
                        selection: timeBinding(for: \.morningNotificationMinutes),
                        displayedComponents: .hourAndMinute
                    )
                    DatePicker(
                        "夜の通知",
                        selection: timeBinding(for: \.eveningNotificationMinutes),
                        displayedComponents: .hourAndMinute
                    )

                    if viewModel.notificationPermissionDenied {
                        Text("通知が許可されていません。端末の設定から変更できます。")
                            .font(.footnote)
                            .foregroundStyle(Color.appSecondary)
                    }
                }

                Section {
                    DatePicker(
                        "1日の切り替わり",
                        selection: timeBinding(for: \.dayBoundaryMinutes),
                        displayedComponents: .hourAndMinute
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
                .navigationTitle("設定")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("閉じる") {
                            dismiss()
                        }
                    }
                }
        }
    }

    private var notificationToggleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.receivesNotifications },
            set: { isEnabled in
                Task {
                    await viewModel.setReceivesNotifications(isEnabled)
                }
            }
        )
    }

    private func timeBinding(for keyPath: ReferenceWritableKeyPath<SettingsViewModel, Int>) -> Binding<Date> {
        Binding(
            get: {
                viewModel.date(from: viewModel[keyPath: keyPath])
            },
            set: { date in
                viewModel[keyPath: keyPath] = viewModel.minutes(from: date)
                Task {
                    await viewModel.syncNotifications()
                }
            }
        )
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel())
}
