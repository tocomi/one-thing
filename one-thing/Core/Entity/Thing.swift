import Foundation

enum ThingStatus: Equatable {
    case unset
    case inProgress
    case done
    case rested
}

struct Thing: Equatable, Identifiable {
    let id: UUID
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
}
