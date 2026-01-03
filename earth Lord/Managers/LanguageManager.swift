import Foundation
import SwiftUI
import Combine

/// 语言选项枚举
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    /// 显示名称（使用对应语言显示）
    var displayName: String {
        switch self {
        case .system:
            return "跟随系统"
        case .simplifiedChinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }

    /// 获取对应的语言代码
    var languageCode: String? {
        switch self {
        case .system:
            return Locale.preferredLanguages.first?.components(separatedBy: "-").first
        case .simplifiedChinese:
            return "zh-Hans"
        case .english:
            return "en"
        }
    }
}

/// 语言管理器 - 管理 App 内语言切换
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    // MARK: - Published Properties

    /// 当前选择的语言（发布变化以更新 UI）
    @Published var currentLanguage: AppLanguage {
        didSet {
            saveLanguagePreference()
            updateCurrentBundle()
        }
    }

    /// 当前语言的 Bundle（用于获取本地化字符串）
    private(set) var currentBundle: Bundle = Bundle.main

    // MARK: - Private Properties

    private let languageKey = "AppLanguage"

    // MARK: - Initialization

    private init() {
        // 从 UserDefaults 加载保存的语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // 默认跟随系统
            self.currentLanguage = .system
        }

        updateCurrentBundle()
    }

    // MARK: - Public Methods

    /// 切换语言
    /// - Parameter language: 要切换到的语言
    func changeLanguage(to language: AppLanguage) {
        print("🌍 切换语言: \(currentLanguage.displayName) -> \(language.displayName)")
        currentLanguage = language
    }

    /// 获取本地化字符串
    /// - Parameters:
    ///   - key: 本地化键
    ///   - comment: 注释（可选）
    /// - Returns: 本地化后的字符串
    func localizedString(_ key: String, comment: String = "") -> String {
        return currentBundle.localizedString(forKey: key, value: nil, table: nil)
    }

    // MARK: - Private Methods

    /// 保存语言选择到 UserDefaults
    private func saveLanguagePreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
        print("💾 语言设置已保存: \(currentLanguage.displayName)")
    }

    /// 更新当前使用的 Bundle
    private func updateCurrentBundle() {
        guard let languageCode = currentLanguage.languageCode else {
            currentBundle = Bundle.main
            return
        }

        // 尝试获取对应语言的 Bundle
        if let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            currentBundle = bundle
            print("✅ 成功加载语言包: \(languageCode)")
        } else {
            // 回退到主 Bundle
            currentBundle = Bundle.main
            print("⚠️ 未找到语言包: \(languageCode)，使用默认语言")
        }
    }
}

// MARK: - String Extension for Localization

extension String {
    /// 获取本地化字符串（使用 LanguageManager）
    var localized: String {
        return LanguageManager.shared.localizedString(self)
    }

    /// 获取本地化字符串（带参数）
    /// - Parameter arguments: 格式化参数
    /// - Returns: 格式化后的本地化字符串
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
