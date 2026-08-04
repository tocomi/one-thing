import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("HomeViewModel")
struct HomeViewModelTests {
    @Test("今日の Thing があれば読み込んで候補は表示しない")
    func loadShowsTodayThing() async {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .inProgress)
        ])
        let viewModel = makeHomeViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.thing?.title == "散歩する")
        #expect(viewModel.suggestions.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("画面状態は永続化オブジェクトではなく読み込み時点の値を保持する")
    func loadKeepsValueSnapshot() async {
        let thing = Thing(date: appToday(), title: "散歩する", status: .inProgress)
        let repository = FakeThingRepository(things: [thing])
        let viewModel = makeHomeViewModel(repository: repository)

        await viewModel.load()
        // 保存済みオブジェクトが後から変化しても、画面状態は引きずられない。
        thing.title = "本を読む"
        thing.status = .done

        #expect(viewModel.thing?.title == "散歩する")
        #expect(viewModel.thing?.status == .inProgress)
    }

    @Test("今日の Thing がなければ履歴から候補を表示する")
    func loadShowsSuggestionsWhenUnset() async {
        let repository = FakeThingRepository(things: [
            Thing(date: pastDay(1), title: "散歩する", status: .done),
            Thing(date: pastDay(2), title: "散歩する", status: .done),
            Thing(date: pastDay(3), title: "本を読む", status: .done)
        ])
        let viewModel = makeHomeViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.thing == nil)
        #expect(viewModel.suggestions == ["散歩する", "本を読む"])
    }

    @Test("読み込みに失敗するとエラーメッセージを表示する")
    func loadSurfacesError() async {
        let repository = FakeThingRepository()
        repository.errors[.fetchThing] = FakeRepositoryError()
        let viewModel = makeHomeViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("入力内容を保存すると今日の Thing になり入力欄が空になる")
    func submitDraftSavesThing() async {
        let repository = FakeThingRepository()
        let viewModel = makeHomeViewModel(repository: repository)
        viewModel.draftTitle = "  散歩する  "

        await viewModel.submitDraft()

        #expect(viewModel.thing?.title == "散歩する")
        #expect(viewModel.thing?.status == .inProgress)
        #expect(viewModel.draftTitle.isEmpty)
        #expect(viewModel.suggestions.isEmpty)
        #expect(viewModel.isSubmitting == false)
    }

    @Test("空白だけの入力は保存しない")
    func submitDraftIgnoresBlankTitle() async {
        let repository = FakeThingRepository()
        let viewModel = makeHomeViewModel(repository: repository)
        viewModel.draftTitle = "   "

        await viewModel.submitDraft()

        #expect(viewModel.thing == nil)
        #expect(viewModel.canSubmitDraft == false)
        #expect(repository.createdThings.isEmpty)
    }

    @Test("候補を選ぶと入力欄に反映される")
    func selectSuggestionFillsDraft() {
        let viewModel = makeHomeViewModel(repository: FakeThingRepository())

        viewModel.selectSuggestion("散歩する")

        #expect(viewModel.draftTitle == "散歩する")
        #expect(viewModel.canSubmitDraft)
    }

    @Test("タイトル編集を保存すると内容が更新される")
    func saveEditingTitleUpdatesThing() async {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "本を読む", status: .inProgress)
        ])
        let viewModel = makeHomeViewModel(repository: repository)
        await viewModel.load()

        viewModel.startEditingTitle()
        #expect(viewModel.editingTitle == "本を読む")

        viewModel.editingTitle = "散歩する"
        await viewModel.saveEditingTitle()

        #expect(viewModel.thing?.title == "散歩する")
        #expect(viewModel.isEditingTitle == false)
        #expect(viewModel.editingTitle.isEmpty)
    }

    @Test("完了操作で今日の Thing が done になる")
    func completeThingMarksAsDone() async {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .inProgress)
        ])
        let viewModel = makeHomeViewModel(repository: repository)
        await viewModel.load()

        await viewModel.completeThing()

        #expect(viewModel.thing?.status == .done)
        #expect(viewModel.isCompletionAnimationVisible)
    }

    @Test("Thing が未設定なら完了操作は何もしない")
    func completeThingIgnoresUnsetState() async {
        let repository = FakeThingRepository()
        let viewModel = makeHomeViewModel(repository: repository)

        await viewModel.completeThing()

        #expect(viewModel.thing == nil)
        #expect(viewModel.errorMessage == nil)
        #expect(repository.saveChangesCallCount == 0)
    }

    @Test("境界時刻より前は前日の Thing を今日として扱う")
    func loadUsesInjectedTimeBeforeDayBoundary() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 31), title: "散歩する", status: .inProgress)
        ])
        let viewModel = makeHomeViewModel(
            repository: repository,
            now: TestClock.date(2026, 8, 1, 3, 0)
        )

        await viewModel.load()

        #expect(viewModel.thing?.title == "散歩する")
        #expect(repository.fetchThingDates == [TestClock.day(2026, 7, 31)])
    }

    @Test("境界時刻を過ぎていれば当日の Thing を今日として扱う")
    func loadUsesInjectedTimeAfterDayBoundary() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 31), title: "散歩する", status: .inProgress)
        ])
        let viewModel = makeHomeViewModel(
            repository: repository,
            now: TestClock.date(2026, 8, 1, 4, 0)
        )

        await viewModel.load()

        #expect(viewModel.thing == nil)
        #expect(repository.fetchThingDates == [TestClock.day(2026, 8, 1)])
    }

    @Test("未設定時の促し文は注入した時刻で切り替わる")
    func unsetPromptTextFollowsInjectedTime() {
        let morning = makeHomeViewModel(
            repository: FakeThingRepository(),
            now: TestClock.date(2026, 8, 1, 11, 59)
        )
        let afternoon = makeHomeViewModel(
            repository: FakeThingRepository(),
            now: TestClock.date(2026, 8, 1, 12, 0)
        )

        #expect(morning.unsetPromptText == "今日は何をする？")
        #expect(afternoon.unsetPromptText == "今日やること、決めた？")
    }

    @Test("デバッグ用のリセットで保存データと画面状態を初期化する")
    func resetSavedDataClearsState() async {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .inProgress)
        ])
        let viewModel = makeHomeViewModel(repository: repository)
        await viewModel.load()

        await viewModel.resetSavedDataForDebug()

        #expect(viewModel.thing == nil)
        #expect(viewModel.suggestions.isEmpty)
        #expect(repository.deleteAllThingsCallCount == 1)
    }
}
