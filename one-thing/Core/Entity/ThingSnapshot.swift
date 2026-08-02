import Foundation

/// 画面側が保持する Thing の値型スナップショット。
///
/// SwiftData の `@Model` インスタンスは削除されるとプロパティ参照でクラッシュするため、
/// ViewModel と View は永続化オブジェクトではなく、読み込み時点の値をこの型で持つ。
struct ThingSnapshot: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let title: String
    let status: ThingStatus

    /// タスクが完了済みかどうかを View などから読みやすく判定する。
    var isDone: Bool {
        status == .done
    }

    /// 各項目を直接指定してスナップショットを作る。
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        title: String,
        status: ThingStatus = .inProgress
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.status = status
    }

    /// 永続化エンティティから、その時点の値を写し取る。
    init(_ thing: Thing) {
        self.init(
            id: thing.id,
            date: thing.date,
            title: thing.title,
            status: thing.status
        )
    }
}
