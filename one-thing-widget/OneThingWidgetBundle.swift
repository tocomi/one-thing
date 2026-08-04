import SwiftUI
import WidgetKit

/// ウィジェット Extension のエントリーポイント。
///
/// 提供するウィジェットが増えたときは、ここに追加していく。
@main
struct OneThingWidgetBundle: WidgetBundle {
    var body: some Widget {
        OneThingWidget()
    }
}
