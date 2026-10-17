import Foundation

enum AppIdentity {
    static let productionBundleID = "com.tangfanx.popdeck"
    static var isDevelopment: Bool {
        Bundle.main.object(forInfoDictionaryKey: "PopDeckDevelopmentBuild") as? Bool ?? false
    }
    static var displayName: String { isDevelopment ? "PopDeck Dev" : "PopDeck" }
    static var cacheDirectoryName: String {
        let identifier = Bundle.main.bundleIdentifier ?? productionBundleID
        return identifier == productionBundleID ? "PopDeck" : identifier
    }
    static func settingsTitle(_ title: String) -> String {
        isDevelopment ? title.replacingOccurrences(of: "PopDeck", with: displayName) : title
    }
}
