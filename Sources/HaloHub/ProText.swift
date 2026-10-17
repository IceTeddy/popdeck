import Foundation

enum ProText {
    static func t(_ chinese: String, _ english: String) -> String {
        AppLanguage.current == .zhHans ? chinese : english
    }
}
