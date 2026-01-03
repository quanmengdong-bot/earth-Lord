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
