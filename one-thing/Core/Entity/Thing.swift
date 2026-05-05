import Foundation
import SwiftData

enum ThingStatus: String, Codable, Equatable {
    case unset
    case inProgress
    case done
    case rested
}

@Model
final class Thing: Equatable, Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var title: String
    var status: ThingStatus

    var isDone: Bool {
        status == .done
    }

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

    static func == (lhs: Thing, rhs: Thing) -> Bool {
        lhs.id == rhs.id
            && lhs.date == rhs.date
            && lhs.title == rhs.title
            && lhs.status == rhs.status
    }
}
