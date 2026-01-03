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

    // MARK: - Computed Properties for Localized Titles

    private var mapTitle: String {
        let translated = "地图".localized
        print("🏷️ mapTitle 计算: '地图' -> '\(translated)' (语言: \(languageManager.currentLanguage.languageCode))")
        return translated
    }

    private var territoryTitle: String {
        let translated = "领地".localized
        print("🏷️ territoryTitle 计算: '领地' -> '\(translated)'")
        return translated
    }

    private var profileTitle: String {
        let translated = "个人".localized
        print("🏷️ profileTitle 计算: '个人' -> '\(translated)'")
        return translated
    }

    private var moreTitle: String {
        let translated = "更多".localized
        print("🏷️ moreTitle 计算: '更多' -> '\(translated)'")
        return translated
    }
}

#Preview {
    MainTabView()
}
