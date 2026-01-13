//
//  POIListView.swift
//  earth Lord
//
//  附近兴趣点列表页面
//

import SwiftUI

// MARK: - 筛选类型

/// 筛选选项（包含"全部"）
enum POIFilterType: String, CaseIterable {
    case all = "全部"
    case hospital = "医院"
    case supermarket = "超市"
    case factory = "工厂"
    case pharmacy = "药店"
    case gasStation = "加油站"

    /// 对应的POI类型（全部返回nil）
    var poiType: POIType? {
        switch self {
        case .all: return nil
        case .hospital: return .hospital
        case .supermarket: return .supermarket
        case .factory: return .factory
        case .pharmacy: return .pharmacy
        case .gasStation: return .gasStation
        }
    }

    /// 筛选项颜色
    var color: Color {
        switch self {
        case .all: return ApocalypseTheme.primary
        case .hospital: return Color.red
        case .supermarket: return Color.green
        case .factory: return Color.gray
        case .pharmacy: return Color.purple
        case .gasStation: return Color.orange
        }
    }
}

// MARK: - POI列表主视图

struct POIListView: View {

    // MARK: - State

    /// 是否正在搜索
    @State private var isSearching = false

    /// 当前选中的筛选类型
    @State private var selectedFilter: POIFilterType = .all

    /// POI数据（从假数据加载）
    @State private var pois: [POI] = MockExplorationData.mockPOIs

    /// 假GPS坐标
    private let mockLatitude = 22.54
    private let mockLongitude = 114.06

    // MARK: - Computed Properties

    /// 筛选后的POI列表
    private var filteredPOIs: [POI] {
        if selectedFilter == .all {
            return pois
        }
        guard let targetType = selectedFilter.poiType else {
            return pois
        }
        return pois.filter { $0.type == targetType }
    }

    /// 已发现的POI数量
    private var discoveredCount: Int {
        pois.filter { $0.discoveryStatus != .undiscovered }.count
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 状态栏
                    statusBar

                    // 搜索按钮
                    searchButton
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    // 筛选工具栏
                    filterToolbar

                    // POI列表
                    poiList
                }
            }
            .navigationTitle("附近地点")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 状态栏

    private var statusBar: some View {
        HStack {
            // GPS坐标
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.success)

                Text(String(format: "%.2f, %.2f", mockLatitude, mockLongitude))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            Spacer()

            // 发现数量
            Text("附近发现 \(discoveredCount) 个地点")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(ApocalypseTheme.cardBackground)
    }

    // MARK: - 搜索按钮

    private var searchButton: some View {
        Button(action: performSearch) {
            HStack(spacing: 12) {
                if isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)

                    Text("搜索中...")
                        .fontWeight(.semibold)
                } else {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.title3)

                    Text("搜索附近POI")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        isSearching ? ApocalypseTheme.textSecondary : ApocalypseTheme.primary,
                        isSearching ? ApocalypseTheme.textMuted : ApocalypseTheme.primaryDark
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(isSearching)
    }

    // MARK: - 筛选工具栏

    private var filterToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(POIFilterType.allCases, id: \.self) { filter in
                    filterButton(for: filter)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(ApocalypseTheme.cardBackground.opacity(0.5))
    }

    /// 筛选按钮
    private func filterButton(for filter: POIFilterType) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        }) {
            Text(filter.rawValue)
                .font(.subheadline)
                .fontWeight(selectedFilter == filter ? .bold : .medium)
                .foregroundColor(selectedFilter == filter ? .white : ApocalypseTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedFilter == filter
                        ? filter.color
                        : ApocalypseTheme.cardBackground
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            selectedFilter == filter ? Color.clear : ApocalypseTheme.textMuted,
                            lineWidth: 1
                        )
                )
        }
    }

    // MARK: - POI列表

    private var poiList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if filteredPOIs.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredPOIs) { poi in
                        NavigationLink(destination: POIDetailView(poi: poi)) {
                            POIRowView(poi: poi)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 50))
                .foregroundColor(ApocalypseTheme.textMuted)

            Text("没有找到该类型的地点")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text("尝试搜索或切换筛选条件")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Actions

    /// 执行搜索
    private func performSearch() {
        isSearching = true

        // 模拟网络请求，1.5秒后恢复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSearching = false
            // 这里可以刷新数据
            print("[POI] 搜索完成，刷新POI列表")
        }
    }

}

// MARK: - POI行视图

struct POIRowView: View {
    let poi: POI

    var body: some View {
        HStack(spacing: 14) {
            // 类型图标
            poiIcon

            // 信息区域
            VStack(alignment: .leading, spacing: 4) {
                // 名称
                HStack {
                    Text(poi.discoveryStatus == .undiscovered ? "???" : poi.name)
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Spacer()

                    // 危险等级
                    if poi.discoveryStatus != .undiscovered {
                        dangerBadge
                    }
                }

                // 类型和状态
                HStack(spacing: 12) {
                    // 类型文字
                    Text(poi.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(poi.type.themeColor)

                    // 发现状态
                    discoveryStatusBadge

                    // 物资状态
                    if poi.discoveryStatus != .undiscovered {
                        resourceStatusBadge
                    }
                }
            }

            // 箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .padding(14)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .opacity(poi.discoveryStatus == .undiscovered ? 0.6 : 1.0)
    }

    // MARK: - Subviews

    /// POI类型图标
    private var poiIcon: some View {
        ZStack {
            Circle()
                .fill(poi.type.themeColor.opacity(0.2))
                .frame(width: 50, height: 50)

            Image(systemName: poi.discoveryStatus == .undiscovered ? "questionmark" : poi.type.iconName)
                .font(.title2)
                .foregroundColor(poi.type.themeColor)
        }
    }

    /// 危险等级标识
    private var dangerBadge: some View {
        HStack(spacing: 2) {
            ForEach(0..<poi.dangerLevel, id: \.self) { _ in
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 8))
            }
        }
        .foregroundColor(dangerColor)
    }

    /// 危险等级对应颜色
    private var dangerColor: Color {
        switch poi.dangerLevel {
        case 1...2: return ApocalypseTheme.success
        case 3: return ApocalypseTheme.warning
        case 4...5: return ApocalypseTheme.danger
        default: return ApocalypseTheme.textMuted
        }
    }

    /// 发现状态标识
    private var discoveryStatusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: discoveryStatusIcon)
                .font(.caption2)

            Text(discoveryStatusText)
                .font(.caption)
        }
        .foregroundColor(discoveryStatusColor)
    }

    private var discoveryStatusIcon: String {
        switch poi.discoveryStatus {
        case .undiscovered: return "eye.slash"
        case .discovered: return "eye"
        case .looted: return "checkmark.circle"
        }
    }

    private var discoveryStatusText: String {
        switch poi.discoveryStatus {
        case .undiscovered: return "未发现"
        case .discovered: return "已发现"
        case .looted: return "已探索"
        }
    }

    private var discoveryStatusColor: Color {
        switch poi.discoveryStatus {
        case .undiscovered: return ApocalypseTheme.textMuted
        case .discovered: return ApocalypseTheme.info
        case .looted: return ApocalypseTheme.success
        }
    }

    /// 物资状态标识
    private var resourceStatusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: resourceStatusIcon)
                .font(.caption2)

            Text(resourceStatusText)
                .font(.caption)
        }
        .foregroundColor(resourceStatusColor)
    }

    private var resourceStatusIcon: String {
        switch poi.resourceStatus {
        case .hasResources: return "cube.box.fill"
        case .empty: return "cube.box"
        case .unknown: return "questionmark.square"
        }
    }

    private var resourceStatusText: String {
        switch poi.resourceStatus {
        case .hasResources: return "有物资"
        case .empty: return "已搜空"
        case .unknown: return "未知"
        }
    }

    private var resourceStatusColor: Color {
        switch poi.resourceStatus {
        case .hasResources: return ApocalypseTheme.success
        case .empty: return ApocalypseTheme.textMuted
        case .unknown: return ApocalypseTheme.warning
        }
    }
}

// MARK: - Preview

#Preview {
    POIListView()
}
