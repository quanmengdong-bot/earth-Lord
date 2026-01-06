//
//  MainTabView.swift
//  earth Lord
//
//  Created by AI Assistant on 2025/12/28.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject private var languageManager = LanguageManager.shared

    init() {
        // 配置 Tab Bar 外观，提升在地图上的可见度
        configureTabBarAppearance()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MapTabView()
                .tabItem {
                    Label(mapTitle, systemImage: "map.fill")
                }
                .tag(0)

            TerritoryTabView()
                .tabItem {
                    Label(territoryTitle, systemImage: "flag.fill")
                }
                .tag(1)

            ProfileTabView()
                .tabItem {
                    Label(profileTitle, systemImage: "person.fill")
                }
                .tag(2)

            MoreTabView()
                .tabItem {
                    Label(moreTitle, systemImage: "ellipsis")
                }
                .tag(3)
        }
        .tint(ApocalypseTheme.primary)
        .id(languageManager.currentLanguage) // 强制刷新 TabView
    }

    // MARK: - Tab Bar Appearance Configuration

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()

        // 使用毛玻璃背景（半透明深色）
        appearance.configureWithDefaultBackground()

        // 设置背景色：深色半透明背景 + 毛玻璃效果
        appearance.backgroundColor = UIColor(white: 0.1, alpha: 0.95) // 深灰色，95% 不透明

        // 添加顶部分隔线，增强边界感
        appearance.shadowColor = UIColor(white: 1.0, alpha: 0.1)

        // 未选中状态：浅灰色
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.6, alpha: 1.0)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.6, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        // 选中状态：橙色（ApocalypseTheme.primary）
        let primaryColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // 橙色
        appearance.stackedLayoutAppearance.selected.iconColor = primaryColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: primaryColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        // 应用配置
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance // iOS 15+ 滚动边缘样式
    }

    // MARK: - Computed Properties for Localized Titles

    private var mapTitle: String {
        return "地图".localized
    }

    private var territoryTitle: String {
        return "领地".localized
    }

    private var profileTitle: String {
        return "个人".localized
    }

    private var moreTitle: String {
        return "更多".localized
    }
}

#Preview {
    MainTabView()
}
