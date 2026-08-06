import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("HomeViewModel 今日が休んだ")
struct HomeViewModelRestedTodayTests {
    @Test("今日が休んだなら完了扱いにせず未設定として表示する")
    func doesNotShowRestedTodayAsDone() async {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .rested),
            Thing(date: pastDay(1), title: "本を読む", status: .done),
            Thing(date: pastDay(2), title: "本を読む", status: .done)
        ])
        let viewModel = makeHomeViewModel(repository: repository)

        await viewModel.load()

        // 記録は残したまま、ホームの表示だけを未設定に寄せる。
        #expect(viewModel.thing == nil)
        #expect(repository.storedThing(on: appToday())?.status == .rested)
        // 未設定として表示するため、履歴からの候補も未設定のときと同じように出す。
        #expect(viewModel.suggestions == ["本を読む"])
        #expect(viewModel.errorMessage == nil)
    }

    @Test("シーン復帰でも今日の休んだは未設定として表示する")
    func keepsRestedTodayUnsetOnRefresh() async {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .rested)
        ])
        let viewModel = makeHomeViewModel(repository: repository)

        await viewModel.refreshForActiveScene()

        #expect(viewModel.thing == nil)
    }

    @Test("今日が休んだなら完了操作は何もしない")
    func doesNotCompleteRestedToday() async {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .rested)
        ])
        let viewModel = makeHomeViewModel(repository: repository)
        await viewModel.load()

        await viewModel.completeThing()

        #expect(viewModel.thing == nil)
        #expect(repository.storedThing(on: appToday())?.status == .rested)
        #expect(repository.saveChangesCallCount == 0)
    }

    @Test("休んだ今日から決め直すと進行中の表示に戻る")
    func resettingRestedTodayReturnsToInProgress() async {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .rested)
        ])
        let viewModel = makeHomeViewModel(repository: repository)
        await viewModel.load()

        viewModel.draftTitle = "本を読む"
        await viewModel.submitDraft()

        #expect(viewModel.thing?.title == "本を読む")
        #expect(viewModel.thing?.status == .inProgress)
        #expect(repository.storedThing(on: appToday())?.status == .inProgress)
    }

    @Test("今日が完了・進行中ならそのまま表示する")
    func keepsDoneAndInProgressToday() async {
        let doneRepository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .done)
        ])
        let doneViewModel = makeHomeViewModel(repository: doneRepository)

        await doneViewModel.load()

        #expect(doneViewModel.thing?.status == .done)

        let inProgressRepository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .inProgress)
        ])
        let inProgressViewModel = makeHomeViewModel(repository: inProgressRepository)

        await inProgressViewModel.load()

        #expect(inProgressViewModel.thing?.status == .inProgress)
    }
}
