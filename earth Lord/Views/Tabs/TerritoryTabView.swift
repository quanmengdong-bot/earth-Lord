//
//  TerritoryTabView.swift
//  earth Lord
//
//  领地列表页面 - Day17
//

import SwiftUI

struct TerritoryTabView: View {

    // MARK: - State Properties

    /// 领地管理器
    @ObservedObject private var territoryManager = TerritoryManager.shared

    /// 认证管理器
    @ObservedObject private var authManager = AuthManager.shared

    /// 选中的领地（用于显示详情）
    @State private var selectedTerritory: Territory? = nil

    /// 是否显示删除确认
    @State private var showDeleteConfirm = false

    /// 待删除的领地
    @State private var territoryToDelete: Territory? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

                // 内容
                if !authManager.isAuthenticated {
                    // 未登录提示
                    notLoggedInView
                } else if territoryManager.isLoading && territoryManager.territories.isEmpty {
                    // 首次加载
                    loadingView
                } else if territoryManager.territories.isEmpty {
                    // 空状态
                    emptyStateView
                } else {
                    // 领地列表
                    territoryListView
                }
            }
            .navigationTitle("我的领地")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // 刷新按钮
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task {
                            await territoryManager.fetchMyTerritories()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(ApocalypseTheme.primary)
                    }
                    .disabled(territoryManager.isLoading)
                }
            }
            .onAppear {
                // 页面出现时加载领地列表
                if authManager.isAuthenticated && territoryManager.territories.isEmpty {
                    Task {
                        await territoryManager.fetchMyTerritories()
                    }
                }
            }
            .alert("删除领地", isPresented: $showDeleteConfirm) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    if let territory = territoryToDelete {
                        Task {
                            await territoryManager.deleteTerritory(territory)
                        }
                    }
                }
            } message: {
                if let territory = territoryToDelete {
                    Text("确定要删除「\(territory.name)」吗？此操作无法撤销。")
                }
            }
            .sheet(item: $selectedTerritory) { territory in
                TerritoryDetailView(territory: territory)
            }
        }
    }

    // MARK: - Subviews

    /// 未登录视图
    private var notLoggedInView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text("请先登录")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text("登录后可以查看和管理你的领地")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    /// 加载中视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ApocalypseTheme.primary)

            Text("加载中...")
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
    }

    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "flag.slash")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text("还没有领地")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text("去地图页面圈一块属于你的领地吧！")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)

            // 提示：如何圈地
            VStack(alignment: .leading, spacing: 12) {
                tipRow(icon: "1.circle.fill", text: "打开地图页面")
                tipRow(icon: "2.circle.fill", text: "点击「开始圈地」按钮")
                tipRow(icon: "3.circle.fill", text: "步行画出一个封闭区域")
                tipRow(icon: "4.circle.fill", text: "回到起点完成圈地")
            }
            .padding()
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 32)
        }
        .padding()
    }

    /// 提示行
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.primary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
        }
    }

    /// 领地列表视图
    private var territoryListView: some View {
        VStack(spacing: 0) {
            // 统计卡片
            statsCard
                .padding()

            // 列表
            List {
                ForEach(territoryManager.territories) { territory in
                    TerritoryRowView(territory: territory)
                        .listRowBackground(ApocalypseTheme.cardBackground)
                        .listRowSeparatorTint(ApocalypseTheme.textSecondary.opacity(0.3))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTerritory = territory
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                territoryToDelete = territory
                                showDeleteConfirm = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    /// 统计卡片
    private var statsCard: some View {
        HStack(spacing: 20) {
            // 领地数量
            VStack(spacing: 4) {
                Text("\(territoryManager.territories.count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ApocalypseTheme.primary)

                Text("块领地")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)
                .background(ApocalypseTheme.textSecondary.opacity(0.3))

            // 总面积
            VStack(spacing: 4) {
                Text(TerritoryManager.formatArea(territoryManager.totalArea))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ApocalypseTheme.primary)

                Text("总面积")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - 领地行视图

struct TerritoryRowView: View {
    let territory: Territory

    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(ApocalypseTheme.primary.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "flag.fill")
                    .foregroundColor(ApocalypseTheme.primary)
                    .font(.title3)
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(territory.name)
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                HStack(spacing: 12) {
                    // 面积
                    Label(TerritoryManager.formatArea(territory.area), systemImage: "square.dashed")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    // 路径点数
                    Label("\(territory.path.count) 点", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }

            Spacer()

            // 时间
            if let createdAt = territory.createdAt {
                Text(formatDate(createdAt))
                    .font(.caption2)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            // 箭头
            Image(systemName: "chevron.right")
                .foregroundColor(ApocalypseTheme.textSecondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }

    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    TerritoryTabView()
}
