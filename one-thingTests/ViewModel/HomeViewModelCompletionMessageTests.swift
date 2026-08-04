import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("HomeViewModel 完了メッセージ")
struct HomeViewModelCompletionMessageTests {
    @Test("同じ Thing のまま再読み込みしても切り替わらない")
    func staysStableAcrossReloads() async {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .done)
        ])
        let viewModel = makeHomeViewModel(repository: repository)
        await viewModel.load()
        let message = viewModel.completionMessage

        // カレンダーを閉じたときやシーン復帰時に走る経路。
        await viewModel.refreshForActiveScene()
        await viewModel.load()

        #expect(viewModel.completionMessage == message)
    }

    @Test("同じ Thing なら ViewModel を作り直しても切り替わらない")
    func staysStableAcrossViewModelRecreation() async {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .done)
        ])
        let viewModel = makeHomeViewModel(repository: repository)
        await viewModel.load()

        // アプリを起動し直して ViewModel が作り直された状況。
        let recreated = makeHomeViewModel(repository: repository)
        await recreated.load()

        #expect(recreated.completionMessage == viewModel.completionMessage)
    }

    @Test("別の Thing が完了状態になれば選び直す")
    func isReselectedForAnotherThing() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .done)
        ])
        let viewModel = makeHomeViewModel(repository: repository)
        await viewModel.load()
        let firstThingID = try #require(viewModel.thing?.id)

        // 保存済みの Thing が別のものに入れ替わった状況を作る。
        try await repository.deleteThing(on: appToday())
        let replacement = try await repository.createThing(
            date: appToday(),
            title: "本を読む",
            status: .done
        )
        await viewModel.refreshForActiveScene()

        #expect(replacement.id != firstThingID)
        #expect(viewModel.thing?.id == replacement.id)
        #expect(viewModel.completionMessage == CompletionMessages.message(for: replacement.id))
    }

    @Test("メッセージは候補から選ばれる")
    func selectsFromCandidates() async {
        let repository = FakeThingRepository(things: [
            Thing(date: appToday(), title: "散歩する", status: .done)
        ])
        let viewModel = makeHomeViewModel(repository: repository)

        await viewModel.load()

        #expect(CompletionMessages.all.contains(viewModel.completionMessage))
    }
}
