//
//  TestMenuView.swift
//  earth Lord
//
//  测试模块入口菜单 - 包含 Supabase 测试和圈地测试
//

import SwiftUI

struct TestMenuView: View {

    var body: some View {
        ZStack {
            // 背景
            ApocalypseTheme.background
                .ignoresSafeArea()

            List {
                // Supabase 连接测试
                NavigationLink(destination: SupabaseTestView()) {
                    HStack(spacing: 16) {
                        Image(systemName: "server.rack")
                            .font(.title2)
                            .foregroundColor(ApocalypseTheme.info)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Supabase 连接测试")
                                .font(.headline)
                                .foregroundColor(ApocalypseTheme.textPrimary)

                            Text("测试数据库连接状态")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // 圈地功能测试
                NavigationLink(destination: TerritoryTestView()) {
                    HStack(spacing: 16) {
                        Image(systemName: "flag.circle")
                            .font(.title2)
                            .foregroundColor(ApocalypseTheme.success)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("圈地功能测试")
                                .font(.headline)
                                .foregroundColor(ApocalypseTheme.textPrimary)

                            Text("查看圈地实时日志")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden) // 隐藏 List 默认背景
        }
        .navigationTitle("开发测试")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        TestMenuView()
    }
}
