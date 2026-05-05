import Foundation
import SwiftData

/// その日に取り組む「ひとつのこと」の進行状態を表す。
enum ThingStatus: String, Codable, Equatable {
    case unset
    case inProgress
    case done
    case rested
}

/// 1 日に 1 件だけ扱うタスク本体を表す SwiftData エンティティ。
@Model
final class Thing: Equatable, Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var title: String
    var status: ThingStatus

    /// タスクが完了済みかどうかを View などから読みやすく判定する。
    var isDone: Bool {
        status == .done
    }

    /// タスクの識別子、対象日、タイトル、状態を指定してエンティティを作成する。
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

    /// 同じタスク内容かどうかを識別子と保存値で比較する。
    static func == (lhs: Thing, rhs: Thing) -> Bool {
        lhs.id == rhs.id
            && lhs.date == rhs.date
            && lhs.title == rhs.title
            && lhs.status == rhs.status
    }
}
