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
                    Label {
                        Text(verbatim: "地图".localized)
                    } icon: {
                        Image(systemName: "map.fill")
                    }
                }
                .tag(0)

            TerritoryTabView()
                .tabItem {
                    Label {
                        Text(verbatim: "领地".localized)
                    } icon: {
                        Image(systemName: "flag.fill")
                    }
                }
                .tag(1)

            ProfileTabView()
                .tabItem {
                    Label {
                        Text(verbatim: "个人".localized)
                    } icon: {
                        Image(systemName: "person.fill")
                    }
                }
                .tag(2)

            MoreTabView()
                .tabItem {
                    Label {
                        Text(verbatim: "更多".localized)
                    } icon: {
                        Image(systemName: "ellipsis")
                    }
                }
                .tag(3)
        }
        .tint(ApocalypseTheme.primary)
        .id(languageManager.currentLanguage) // 强制刷新 TabView
    }
}

#Preview {
    MainTabView()
}
