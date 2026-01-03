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
                    Label("地图".localized, systemImage: "map.fill")
                }
                .tag(0)

            TerritoryTabView()
                .tabItem {
                    Label("领地".localized, systemImage: "flag.fill")
                }
                .tag(1)

            ProfileTabView()
                .tabItem {
                    Label("个人".localized, systemImage: "person.fill")
                }
                .tag(2)

            MoreTabView()
                .tabItem {
                    Label("更多".localized, systemImage: "ellipsis")
                }
                .tag(3)
        }
        .tint(ApocalypseTheme.primary)
    }
}

#Preview {
    MainTabView()
}
