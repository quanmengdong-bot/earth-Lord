//
//  MoreTabView.swift
//  earth Lord
//
//  Created by AI Assistant on 2025/12/28.
//

import SwiftUI

struct MoreTabView: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                List {
                    Section {
                        NavigationLink(destination: TestMenuView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "hammer.circle")
                                    .font(.title3)
                                    .foregroundColor(ApocalypseTheme.primary)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("开发测试".localized)
                                        .font(.headline)
                                        .foregroundColor(ApocalypseTheme.textPrimary)

                                    Text("Supabase 和圈地功能测试".localized)
                                        .font(.caption)
                                        .foregroundColor(ApocalypseTheme.textSecondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("开发工具".localized)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("更多".localized)
            .id(languageManager.currentLanguage) // 强制刷新
        }
    }
}

#Preview {
    MoreTabView()
}
