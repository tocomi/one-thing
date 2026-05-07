#if DEBUG
import SwiftUI

/// 開発メニューを開くためのデバッグ専用ボタン。
struct HomeDebugMenuButton: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button {
                    isPresented = true
                } label: {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appSecondary.opacity(0.5))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 20)
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    HomeDebugMenuButton(isPresented: .constant(false))
}
#endif
