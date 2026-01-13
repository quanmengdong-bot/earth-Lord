//
//  ResourcesTabView.swift
//  earth Lord
//
//  资源模块主入口页面
//

import SwiftUI
import UIKit
import CoreLocation

// MARK: - 资源分段类型

/// 资源页面分段选项
enum ResourceSegment: String, CaseIterable {
    case exploration = "探索"
    case backpack = "背包"
    case poi = "POI"
    case territory = "领地"
    case trade = "交易"
}

// MARK: - 资源主视图

struct ResourcesTabView: View {

    // MARK: - State

    /// 当前选中的分段
    @State private var selectedSegment: ResourceSegment = .exploration

    /// 交易开关状态（假数据）
    @State private var isTradeEnabled = false

    // MARK: - Init

    init() {
        // 配置UI外观
        configureAppearance()
    }

    /// 配置UI外观
    private func configureAppearance() {
        // MARK: 分段选择器外观
        // 未选中状态的背景色（深灰色，更可见）
        UISegmentedControl.appearance().backgroundColor = UIColor(white: 0.25, alpha: 1.0)

        // 选中状态的背景色（白色）
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.white

        // 未选中状态的文字颜色（浅灰色，更清晰）
        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: UIColor(white: 0.75, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ], for: .normal)

        // 选中状态的文字颜色（黑色）
        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ], for: .selected)

        // MARK: 导航栏外观
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(white: 0.1, alpha: 1.0)  // 深色背景

        // 大标题样式（白色）
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        // 标准标题样式（白色）
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 分段选择器
                    segmentPicker
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    // 内容区域
                    contentView
                }
            }
            .navigationTitle("资源")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // 交易开关
                ToolbarItem(placement: .topBarTrailing) {
                    tradeToggle
                }
            }
        }
    }

    // MARK: - 分段选择器

    private var segmentPicker: some View {
        Picker("资源分段", selection: $selectedSegment) {
            ForEach(ResourceSegment.allCases, id: \.self) { segment in
                Text(segment.rawValue)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - 交易开关

    private var tradeToggle: some View {
        HStack(spacing: 6) {
            Image(systemName: isTradeEnabled ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle")
                .foregroundColor(isTradeEnabled ? ApocalypseTheme.success : ApocalypseTheme.textMuted)

            Toggle("", isOn: $isTradeEnabled)
                .labelsHidden()
                .tint(ApocalypseTheme.success)
                .scaleEffect(0.8)
        }
    }

    // MARK: - 内容区域

    @ViewBuilder
    private var contentView: some View {
        switch selectedSegment {
        case .exploration:
            // 探索
            ExplorationContentView()

        case .backpack:
            // 背包
            BackpackContentView()

        case .poi:
            // POI列表
            POIContentView()

        case .territory:
            // 领地 - 占位
            placeholderView(title: "领地资源", icon: "flag.fill", description: "功能开发中\n敬请期待")

        case .trade:
            // 交易 - 占位
            placeholderView(title: "交易市场", icon: "arrow.left.arrow.right", description: "功能开发中\n敬请期待")
        }
    }

    /// 占位视图
    private func placeholderView(title: String, icon: String, description: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            // 图标
            ZStack {
                Circle()
                    .fill(ApocalypseTheme.cardBackground)
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(ApocalypseTheme.textMuted)
            }

            // 标题
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 描述
            Text(description)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - POI内容视图（去掉导航）

struct POIContentView: View {

    // MARK: - State

    /// 是否正在搜索
    @State private var isSearching = false

    /// 当前选中的筛选类型
    @State private var selectedFilter: POIFilterType = .all

    /// POI数据
    @State private var pois: [POI] = MockExplorationData.mockPOIs

    /// 搜索按钮按下状态
    @State private var isSearchButtonPressed = false

    /// 列表是否已显示（用于入场动画）
    @State private var listAppeared = false

    /// 假GPS坐标
    private let mockLatitude = 22.54
    private let mockLongitude = 114.06

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

    var body: some View {
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

    // MARK: - 状态栏

    private var statusBar: some View {
        HStack {
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
        .scaleEffect(isSearchButtonPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSearchButtonPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isSearchButtonPressed = true }
                .onEnded { _ in isSearchButtonPressed = false }
        )
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
                if pois.isEmpty {
                    // 完全没有POI数据
                    noPOIEmptyState
                } else if filteredPOIs.isEmpty {
                    // 筛选后没有结果
                    filterEmptyState
                } else {
                    ForEach(Array(filteredPOIs.enumerated()), id: \.element.id) { index, poi in
                        NavigationLink(destination: POIDetailView(poi: poi)) {
                            POIRowView(poi: poi)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(listAppeared ? 1 : 0)
                        .offset(y: listAppeared ? 0 : 20)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                                .delay(Double(index) * 0.08),
                            value: listAppeared
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .onAppear {
            if !listAppeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    listAppeared = true
                }
            }
        }
    }

    /// 空状态：没有POI数据
    private var noPOIEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.textMuted)

            Text("附近暂无兴趣点")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text("点击搜索按钮发现周围的废墟")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 80)
    }

    /// 空状态：筛选后没有结果
    private var filterEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.textMuted)

            Text("没有找到该类型的地点")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text("尝试切换筛选条件")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - Actions

    private func performSearch() {
        isSearching = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSearching = false
            print("[POI] 搜索完成")
        }
    }
}

// MARK: - 探索内容视图

struct ExplorationContentView: View {

    // MARK: - State

    @ObservedObject private var explorationManager = ExplorationManager.shared
    @ObservedObject private var locationManager = LocationManager.shared

    /// 是否显示探索结果
    @State private var showResult = false

    /// 是否显示失败提示
    @State private var showFailedAlert = false

    /// 探索按钮按下状态
    @State private var isButtonPressed = false

    /// 是否已加载历史
    @State private var hasLoadedHistory = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 状态信息卡
                statusCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                // 超速警告卡（超速时显示）
                if explorationManager.isOverSpeed {
                    speedWarningCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .scale))
                }

                // 探索数据卡（探索中显示）
                if explorationManager.isExploring {
                    explorationDataCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // 探索按钮
                explorationButton
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                // 探索历史记录
                explorationHistorySection
                    .padding(.top, 20)
            }
            .padding(.bottom, 40)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: explorationManager.isExploring)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: explorationManager.isOverSpeed)
        .sheet(isPresented: $showResult) {
            if let result = explorationManager.explorationResult,
               let stats = explorationManager.explorationStats {
                ExplorationResultView(result: result, stats: stats)
            }
        }
        .alert("探索失败", isPresented: $showFailedAlert) {
            Button("确定", role: .cancel) {
                // 重置状态
                Task {
                    explorationManager.state = .idle
                }
            }
        } message: {
            Text(explorationManager.failReason?.message ?? "探索因异常终止")
        }
        .onChange(of: explorationManager.state) { newValue in
            if newValue == .completed {
                showResult = true
                // 探索完成后刷新历史
                Task {
                    await explorationManager.loadExplorationHistory()
                }
            } else if newValue == .failed {
                showFailedAlert = true
            }
        }
        .onAppear {
            if !hasLoadedHistory {
                hasLoadedHistory = true
                Task {
                    await explorationManager.loadExplorationHistory()
                }
            }
        }
    }

    // MARK: - 探索历史记录区域

    private var explorationHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(ApocalypseTheme.primary)

                Text("探索历史")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                Text("\(explorationManager.explorationHistory.count) 条记录")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .padding(.horizontal, 16)

            if explorationManager.explorationHistory.isEmpty {
                // 空状态
                VStack(spacing: 12) {
                    Image(systemName: "figure.walk.circle")
                        .font(.system(size: 40))
                        .foregroundColor(ApocalypseTheme.textMuted)

                    Text("还没有探索记录")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    Text("开始探索，记录你的冒险足迹")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // 历史列表
                LazyVStack(spacing: 8) {
                    ForEach(explorationManager.explorationHistory) { item in
                        explorationHistoryRow(item: item)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    /// 历史记录行
    private func explorationHistoryRow(item: ExplorationHistoryItem) -> some View {
        HStack(spacing: 12) {
            // 奖励等级图标
            ZStack {
                Circle()
                    .fill(tierColor(item.rewardTier).opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: "gift.fill")
                    .font(.system(size: 16))
                    .foregroundColor(tierColor(item.rewardTier))
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.formattedDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Spacer()

                    Text(item.rewardTier.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(tierColor(item.rewardTier))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(tierColor(item.rewardTier).opacity(0.15))
                        .cornerRadius(4)
                }

                HStack(spacing: 16) {
                    Label(item.formattedDistance, systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    Label(item.formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    if item.itemCount > 0 {
                        Label("\(item.itemCount) 物品", systemImage: "cube.box")
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }
            }
        }
        .padding(12)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 状态信息卡

    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                // 状态图标
                ZStack {
                    Circle()
                        .fill(explorationManager.isExploring ? ApocalypseTheme.success.opacity(0.2) : ApocalypseTheme.cardBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: explorationManager.isExploring ? "figure.walk" : "map")
                        .font(.title2)
                        .foregroundColor(explorationManager.isExploring ? ApocalypseTheme.success : ApocalypseTheme.textMuted)
                        .symbolEffect(.pulse, isActive: explorationManager.isExploring)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(explorationManager.isExploring ? "探索进行中" : "准备探索")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    if let coordinate = locationManager.userLocation {
                        Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    } else {
                        Text("获取位置中...")
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textMuted)
                    }
                }

                Spacer()

                // 奖励预览
                if explorationManager.isExploring {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(explorationManager.previewTier.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(tierColor(explorationManager.previewTier))

                        Text("预计奖励")
                            .font(.caption2)
                            .foregroundColor(ApocalypseTheme.textMuted)
                    }
                }
            }

            // 提示信息
            if !explorationManager.isExploring {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.info)

                    Text("行走 200 米以上可获得奖励")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - 超速警告卡

    private var speedWarningCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(ApocalypseTheme.danger)
                    .symbolEffect(.pulse, isActive: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("速度过快！")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.danger)

                    Text("请减速至 30 km/h 以下")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                Spacer()

                // 倒计时
                VStack(spacing: 2) {
                    Text("\(explorationManager.speedWarningCountdown)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(ApocalypseTheme.danger)
                        .contentTransition(.numericText())

                    Text("秒后终止")
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
            }

            // 当前速度
            HStack {
                Text("当前速度")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                Spacer()

                Text(explorationManager.formatSpeed(explorationManager.currentSpeed))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ApocalypseTheme.danger)
            }
        }
        .padding(16)
        .background(ApocalypseTheme.danger.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ApocalypseTheme.danger, lineWidth: 2)
        )
        .cornerRadius(16)
    }

    // MARK: - 探索数据卡

    private var explorationDataCard: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(ApocalypseTheme.primary)

                Text("实时数据")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()
            }

            // 数据行
            HStack(spacing: 12) {
                // 行走距离
                VStack(spacing: 4) {
                    Text(explorationManager.formatDistance(explorationManager.currentDistance))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                        .contentTransition(.numericText())

                    Text("行走距离")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                // 分隔线
                Rectangle()
                    .fill(ApocalypseTheme.textMuted)
                    .frame(width: 1, height: 40)

                // 当前速度
                VStack(spacing: 4) {
                    Text(explorationManager.formatSpeed(explorationManager.currentSpeed))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(speedColor)
                        .contentTransition(.numericText())

                    Text("当前速度")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                // 分隔线
                Rectangle()
                    .fill(ApocalypseTheme.textMuted)
                    .frame(width: 1, height: 40)

                // 探索时长
                VStack(spacing: 4) {
                    Text(explorationManager.formatDuration(explorationManager.currentDuration))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                        .contentTransition(.numericText())

                    Text("探索时长")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }

            // 进度提示
            if let nextTier = RewardGenerator.shared.nextTierInfo(currentDistance: explorationManager.currentDistance) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle")
                        .font(.caption)
                        .foregroundColor(tierColor(nextTier.tier))

                    Text("再走 \(Int(nextTier.remaining)) 米可达 \(nextTier.tier.displayName)")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }
        }
        .padding(16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - 探索按钮

    private var explorationButton: some View {
        Button(action: {
            Task {
                if explorationManager.isExploring {
                    await explorationManager.stopExploration()
                } else {
                    await explorationManager.startExploration()
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: explorationManager.isExploring ? "stop.fill" : "figure.walk")
                    .font(.title2)

                Text(explorationManager.isExploring ? "结束探索" : "开始探索")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        explorationManager.isExploring ? ApocalypseTheme.danger : ApocalypseTheme.success,
                        explorationManager.isExploring ? ApocalypseTheme.danger.opacity(0.8) : ApocalypseTheme.success.opacity(0.8)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: (explorationManager.isExploring ? ApocalypseTheme.danger : ApocalypseTheme.success).opacity(0.3), radius: 10, y: 5)
        }
        .scaleEffect(isButtonPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isButtonPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isButtonPressed = true }
                .onEnded { _ in isButtonPressed = false }
        )
        .disabled(explorationManager.state == .calculating)
    }

    // MARK: - 辅助方法

    /// 速度显示颜色
    private var speedColor: Color {
        let speed = explorationManager.currentSpeed
        if speed > 30 {
            return ApocalypseTheme.danger
        } else if speed > 20 {
            return ApocalypseTheme.warning
        } else {
            return ApocalypseTheme.success
        }
    }

    private func tierColor(_ tier: RewardTier) -> Color {
        switch tier {
        case .none: return ApocalypseTheme.textMuted
        case .bronze: return Color.brown
        case .silver: return Color.gray
        case .gold: return Color.yellow
        case .diamond: return Color.cyan
        }
    }
}

// MARK: - 背包内容视图（使用真实数据）

struct BackpackContentView: View {

    // MARK: - State

    @ObservedObject private var inventoryManager = InventoryManager.shared

    @State private var searchText = ""
    @State private var selectedFilter: BackpackFilterType = .all

    /// 动画用：显示的容量百分比
    @State private var animatedCapacityPercentage: Double = 0

    /// 列表切换动画ID
    @State private var listTransitionId = UUID()

    /// 是否已初始化
    @State private var hasInitialized = false

    private var maxCapacity: Double {
        inventoryManager.maxCapacity
    }

    private var currentCapacity: Double {
        inventoryManager.currentWeight
    }

    private var capacityPercentage: Double {
        inventoryManager.capacityPercentage
    }

    private var capacityColor: Color {
        if capacityPercentage > 0.9 {
            return ApocalypseTheme.danger
        } else if capacityPercentage > 0.7 {
            return ApocalypseTheme.warning
        } else {
            return ApocalypseTheme.success
        }
    }

    private var filteredItems: [InventoryItem] {
        var result = inventoryManager.inventoryItems

        if let category = selectedFilter.itemCategory {
            result = result.filter { item in
                guard let definition = inventoryManager.getItemDefinition(by: item.itemId) else {
                    return false
                }
                return definition.category == category
            }
        }

        if !searchText.isEmpty {
            result = result.filter { item in
                guard let definition = inventoryManager.getItemDefinition(by: item.itemId) else {
                    return false
                }
                return definition.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // 容量状态卡
            capacityCard
                .padding(.horizontal, 16)
                .padding(.top, 12)

            // 搜索和筛选
            searchAndFilterSection
                .padding(.top, 12)

            // 物品列表
            itemList
        }
        .onAppear {
            if !hasInitialized {
                hasInitialized = true
                Task {
                    await inventoryManager.initialize()
                }
            }
            // 进度条动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animatedCapacityPercentage = capacityPercentage
            }
        }
        .onChange(of: capacityPercentage) { newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedCapacityPercentage = newValue
            }
        }
    }

    // MARK: - 容量状态卡

    private var capacityCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundColor(ApocalypseTheme.primary)

                Text("背包容量")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                if inventoryManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(String(format: "%.1f / %.0f kg", currentCapacity, maxCapacity))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(capacityColor)
                        .contentTransition(.numericText())
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ApocalypseTheme.background)
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(capacityColor)
                        .frame(width: geometry.size.width * min(animatedCapacityPercentage, 1.0), height: 12)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedCapacityPercentage)
                }
            }
            .frame(height: 12)

            if capacityPercentage > 0.9 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)

                    Text("背包快满了！")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(ApocalypseTheme.danger)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 搜索和筛选

    private var searchAndFilterSection: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ApocalypseTheme.textMuted)

                TextField("搜索物品...", text: $searchText)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ApocalypseTheme.textMuted)
                    }
                }
            }
            .padding(12)
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(10)
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(BackpackFilterType.allCases, id: \.self) { filter in
                        backpackFilterButton(for: filter)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
    }

    private func backpackFilterButton(for filter: BackpackFilterType) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFilter = filter
                listTransitionId = UUID()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: filter.iconName)
                    .font(.caption)

                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(selectedFilter == filter ? .bold : .medium)
            }
            .foregroundColor(selectedFilter == filter ? .white : ApocalypseTheme.textSecondary)
            .padding(.horizontal, 14)
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
            .scaleEffect(selectedFilter == filter ? 1.05 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedFilter)
    }

    // MARK: - 物品列表

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if inventoryManager.isLoading {
                    // 加载中
                    ProgressView("加载中...")
                        .padding(.vertical, 60)
                } else if inventoryManager.inventoryItems.isEmpty {
                    // 背包完全是空的
                    emptyBackpackState
                        .transition(.opacity)
                } else if filteredItems.isEmpty {
                    // 搜索/筛选后没有结果
                    noSearchResultState
                        .transition(.opacity)
                } else {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        if let definition = inventoryManager.getItemDefinition(by: item.itemId) {
                            ItemRowView(item: item, definition: definition)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .id(listTransitionId)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: listTransitionId)
        }
        .refreshable {
            await inventoryManager.loadInventory()
        }
    }

    /// 空状态：背包是空的
    private var emptyBackpackState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.textMuted)

            Text("背包空空如也")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text("去探索收集物资吧")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 80)
    }

    /// 空状态：搜索没有结果
    private var noSearchResultState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.textMuted)

            Text("没有找到相关物品")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text("尝试其他搜索关键词")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

// MARK: - Preview

#Preview {
    ResourcesTabView()
}
