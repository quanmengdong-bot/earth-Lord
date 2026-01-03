import SwiftUI

/// 支持动态语言切换的本地化 Text 组件
struct LocalizedText: View {
    let key: String
    let arguments: [CVarArg]
    @ObservedObject private var languageManager = LanguageManager.shared

    init(_ key: String, arguments: CVarArg...) {
        self.key = key
        self.arguments = arguments
    }

    var body: some View {
        Text(localizedString)
    }

    private var localizedString: String {
        let languageCode = languageManager.currentLanguage.languageCode

        // 如果是源语言（中文），直接返回key
        if languageCode == "zh-Hans" {
            if arguments.isEmpty {
                return key
            }
            return String(format: key, arguments: arguments)
        }

        // 加载对应语言的 Bundle
        guard let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else {
            // 回退到原字符串
            if arguments.isEmpty {
                return key
            }
            return String(format: key, arguments: arguments)
        }

        // 获取翻译
        let translated = NSLocalizedString(key, bundle: bundle, comment: "")

        if arguments.isEmpty {
            return translated
        }
        return String(format: translated, arguments: arguments)
    }
}
