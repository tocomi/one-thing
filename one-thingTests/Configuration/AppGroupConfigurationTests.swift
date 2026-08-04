import Foundation
@testable import one_thing
import Testing

/// `AppGroup.identifier` と各 Target の entitlements の整合を検証する。
///
/// `UserDefaults(suiteName:)` は entitlements に無い ID を渡しても nil を返さず、
/// アプリ専用のドメインへ書き込んでしまう。ID がずれても実行時に気付けないため、
/// ビルド設定側の登録漏れをここで検出する。
@Suite("App Group の設定")
struct AppGroupConfigurationTests {
    @Test("entitlements が最低ひとつ存在する")
    func entitlementsFileExists() throws {
        #expect(try Self.entitlementsURLs().isEmpty == false)
    }

    @Test("すべての Target の entitlements に同じ App Group ID が登録されている")
    func allTargetsShareSameIdentifier() throws {
        for url in try Self.entitlementsURLs() {
            let groups = try Self.applicationGroups(at: url)
            #expect(
                groups.contains(AppGroup.identifier),
                "\(url.lastPathComponent) に \(AppGroup.identifier) が登録されていない"
            )
        }
    }

    /// リポジトリ配下の entitlements をすべて集める。Widget Extension を追加しても自動で対象になる。
    private static func entitlementsURLs() throws -> [URL] {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Configuration
            .deletingLastPathComponent() // one-thingTests
            .deletingLastPathComponent() // リポジトリ直下
        let ignoredDirectories: Set = [".git", ".build", "build", "DerivedData"]

        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        var urls: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            if ignoredDirectories.contains(url.lastPathComponent) {
                enumerator?.skipDescendants()
                continue
            }
            if url.pathExtension == "entitlements" {
                urls.append(url)
            }
        }
        return urls
    }

    private static func applicationGroups(at url: URL) throws -> [String] {
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        let entitlements = try #require(plist as? [String: Any], "\(url.lastPathComponent) を辞書として読めない")
        return try #require(
            entitlements["com.apple.security.application-groups"] as? [String],
            "\(url.lastPathComponent) に application-groups が無い"
        )
    }
}
