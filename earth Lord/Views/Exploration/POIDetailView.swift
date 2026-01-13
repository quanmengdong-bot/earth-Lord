//
//  POIDetailView.swift
//  earth Lord
//
//  POI详情页面
//

import SwiftUI

// MARK: - POI详情视图

struct POIDetailView: View {

    // MARK: - Properties

    /// POI数据
    let poi: POI

    /// 假数据：距离
    private let mockDistance: Double = 350

    // MARK: - State

    /// 是否显示探索结果
    @State private var showExplorationResult = false

    /// 是否正在搜寻
    @State private var isSearching = false

    /// POI状态（可修改的本地副本）
    @State private var localPOI: POI

    // MARK: - Init

    init(poi: POI) {
        self.poi = poi
        self._localPOI = State(initialValue: poi)
    }

    // MARK: - Computed Properties

    /// 是否可以搜寻
    private var canSearch: Bool {
        localPOI.resourceStatus == .hasResources && localPOI.discoveryStatus != .undiscovered
    }

    /// 危险等级文字
    private var dangerLevelText: String {
        switch localPOI.dangerLevel {
        case 1: return "安全"
        case 2: return "低危"
        case 3: return "中危"
        case 4...5: return "高危"
        default: return "未知"
        }
    }

    /// 危险等级颜色
    private var dangerLevelColor: Color {
        switch localPOI.dangerLevel {
        case 1: return ApocalypseTheme.success
        case 2: return Color.green
        case 3: return ApocalypseTheme.warning
        case 4...5: return ApocalypseTheme.danger
        default: return ApocalypseTheme.textMuted
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            ApocalypseTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // 顶部大图区域
                    headerSection

                    // 信息区域
                    infoSection
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                    // 操作按钮区域
                    actionSection
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ApocalypseTheme.background, for: .navigationBar)
        .sheet(isPresented: $showExplorationResult) {
            // 成功状态示例（实际使用时根据搜寻结果决定显示成功或失败）
            ExplorationResultView(
                result: MockExplorationData.mockExplorationResult,
                stats: MockExplorationData.mockExplorationStats
            )
            // 错误状态示例（取消注释测试）：
            // ExplorationResultView(
            //     error: .networkError,
            //     onRetry: { performSearch() }
            // )
        }
    }

    // MARK: - 顶部大图区域

    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    localPOI.type.themeColor,
                    localPOI.type.themeColor.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 240)

            // 大图标
            VStack {
                Spacer()

                Image(systemName: localPOI.type.iconName)
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                Spacer()
            }
            .frame(height: 240)

            // 底部遮罩和文字
            VStack(alignment: .leading, spacing: 6) {
                Text(localPOI.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text(localPOI.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    if localPOI.discoveryStatus == .undiscovered {
                        Text("· 未发现")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    // MARK: - 信息区域

    private var infoSection: some View {
        VStack(spacing: 12) {
            // 距离
            infoCard(
                icon: "location.fill",
                iconColor: ApocalypseTheme.info,
                title: "距离",
                value: formatDistance(mockDistance)
            )

            // 物资状态
            infoCard(
                icon: resourceStatusIcon,
                iconColor: resourceStatusColor,
                title: "物资状态",
                value: resourceStatusText,
                valueColor: resourceStatusColor
            )

            // 危险等级
            infoCard(
                icon: "exclamationmark.triangle.fill",
                iconColor: dangerLevelColor,
                title: "危险等级",
                value: dangerLevelText,
                valueColor: dangerLevelColor
            )

            // 来源
            infoCard(
                icon: "doc.text.fill",
                iconColor: ApocalypseTheme.textSecondary,
                title: "来源",
                value: "地图数据"
            )
        }
    }

    /// 信息卡片
    private func infoCard(
        icon: String,
        iconColor: Color,
        title: String,
        value: String,
        valueColor: Color? = nil
    ) -> some View {
        HStack(spacing: 14) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            // 标题
            Text(title)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Spacer()

            // 值
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(valueColor ?? ApocalypseTheme.textPrimary)
        }
        .padding(14)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 物资状态辅助

    private var resourceStatusIcon: String {
        switch localPOI.resourceStatus {
        case .hasResources: return "cube.box.fill"
        case .empty: return "cube.box"
        case .unknown: return "questionmark.square"
        }
    }

    private var resourceStatusText: String {
        switch localPOI.resourceStatus {
        case .hasResources: return "有物资"
        case .empty: return "已清空"
        case .unknown: return "未知"
        }
    }

    private var resourceStatusColor: Color {
        switch localPOI.resourceStatus {
        case .hasResources: return ApocalypseTheme.success
        case .empty: return ApocalypseTheme.textMuted
        case .unknown: return ApocalypseTheme.warning
        }
    }

    // MARK: - 操作按钮区域

    private var actionSection: some View {
        VStack(spacing: 14) {
            // 主按钮：搜寻此POI
            Button(action: performSearch) {
                HStack(spacing: 10) {
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                    }

                    Text(isSearching ? "搜寻中..." : "搜寻此POI")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: canSearch ? [
                            ApocalypseTheme.primary,
                            ApocalypseTheme.primaryDark
                        ] : [
                            ApocalypseTheme.textMuted,
                            ApocalypseTheme.textMuted
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
            .disabled(!canSearch || isSearching)

            // 不可搜寻时的提示
            if !canSearch {
                Text(localPOI.resourceStatus == .empty ? "此地点已被搜空" : "需要先发现此地点")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }

            // 两个小按钮
            HStack(spacing: 12) {
                // 标记已发现
                secondaryButton(
                    title: localPOI.discoveryStatus == .undiscovered ? "标记已发现" : "已发现",
                    icon: "eye.fill",
                    isActive: localPOI.discoveryStatus != .undiscovered,
                    action: markAsDiscovered
                )

                // 标记无物资
                secondaryButton(
                    title: localPOI.resourceStatus == .empty ? "无物资" : "标记无物资",
                    icon: "cube.box",
                    isActive: localPOI.resourceStatus == .empty,
                    action: markAsEmpty
                )
            }
        }
    }

    /// 次要按钮
    private func secondaryButton(
        title: String,
        icon: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isActive ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isActive ? ApocalypseTheme.primary : ApocalypseTheme.textMuted, lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    /// 执行搜寻
    private func performSearch() {
        guard canSearch else { return }

        isSearching = true
        print("[POI详情] 开始搜寻: \(localPOI.name)")

        // 模拟搜寻过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSearching = false
            showExplorationResult = true
            print("[POI详情] 搜寻完成，显示结果")
        }
    }

    /// 标记为已发现
    private func markAsDiscovered() {
        if localPOI.discoveryStatus == .undiscovered {
            localPOI.discoveryStatus = .discovered
            print("[POI详情] 标记为已发现: \(localPOI.name)")
        }
    }

    /// 标记为无物资
    private func markAsEmpty() {
        if localPOI.resourceStatus != .empty {
            localPOI.resourceStatus = .empty
            print("[POI详情] 标记为无物资: \(localPOI.name)")
        }
    }

    // MARK: - Helpers

    /// 格式化距离
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f 公里", meters / 1000)
        }
        return String(format: "%.0f 米", meters)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        POIDetailView(poi: MockExplorationData.mockPOIs[0])
    }
}
