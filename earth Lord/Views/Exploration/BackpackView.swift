//
//  BackpackView.swift
//  earth Lord
//
//  背包管理页面
//

import SwiftUI

// MARK: - 背包筛选类型

/// 背包物品筛选选项
enum BackpackFilterType: String, CaseIterable {
    case all = "全部"
    case food = "食物"
    case water = "水"
    case material = "材料"
    case tool = "工具"
    case medical = "医疗"

    /// 对应的物品分类（全部返回nil）
    var itemCategory: ItemCategory? {
        switch self {
        case .all: return nil
        case .food: return .food
        case .water: return .water
        case .material: return .material
        case .tool: return .tool
        case .medical: return .medical
        }
    }

    /// 筛选项图标
    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .food: return "fork.knife"
        case .water: return "drop.fill"
        case .material: return "cube.box.fill"
        case .tool: return "wrench.and.screwdriver.fill"
        case .medical: return "cross.case.fill"
        }
    }

    /// 筛选项颜色
    var color: Color {
        switch self {
        case .all: return ApocalypseTheme.primary
        case .food: return Color.orange
        case .water: return Color.blue
        case .material: return Color.brown
        case .tool: return Color.gray
        case .medical: return Color.red
        }
    }
}

// MARK: - 背包主视图

struct BackpackView: View {

    // MARK: - State

    /// 搜索文字
    @State private var searchText = ""

    /// 当前选中的筛选类型
    @State private var selectedFilter: BackpackFilterType = .all

    /// 背包物品（从假数据加载）
    @State private var items: [InventoryItem] = MockExplorationData.mockInventoryItems

    /// 背包最大容量（假数据）
    private let maxCapacity: Double = 100.0

    // MARK: - Computed Properties

    /// 当前背包使用量
    private var currentCapacity: Double {
        MockExplorationData.calculateTotalWeight(items: items)
    }

    /// 容量百分比
    private var capacityPercentage: Double {
        currentCapacity / maxCapacity
    }

    /// 进度条颜色
    private var capacityColor: Color {
        if capacityPercentage > 0.9 {
            return ApocalypseTheme.danger
        } else if capacityPercentage > 0.7 {
            return ApocalypseTheme.warning
        } else {
            return ApocalypseTheme.success
        }
    }

    /// 筛选后的物品列表
    private var filteredItems: [InventoryItem] {
        var result = items

        // 按分类筛选
        if let category = selectedFilter.itemCategory {
            result = result.filter { item in
                guard let definition = MockExplorationData.getItemDefinition(by: item.itemId) else {
                    return false
                }
                return definition.category == category
            }
        }

        // 按搜索文字筛选
        if !searchText.isEmpty {
            result = result.filter { item in
                guard let definition = MockExplorationData.getItemDefinition(by: item.itemId) else {
                    return false
                }
                return definition.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

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
            }
            .navigationTitle("背包")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 容量状态卡

    private var capacityCard: some View {
        VStack(spacing: 12) {
            // 标题行
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundColor(ApocalypseTheme.primary)

                Text("背包容量")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                // 容量数值
                Text(String(format: "%.1f / %.0f kg", currentCapacity, maxCapacity))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(capacityColor)
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ApocalypseTheme.background)
                        .frame(height: 12)

                    // 进度
                    RoundedRectangle(cornerRadius: 6)
                        .fill(capacityColor)
                        .frame(width: geometry.size.width * min(capacityPercentage, 1.0), height: 12)
                }
            }
            .frame(height: 12)

            // 警告文字
            if capacityPercentage > 0.9 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)

                    Text("背包快满了！")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(ApocalypseTheme.danger)
            }
        }
        .padding(16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 搜索和筛选区域

    private var searchAndFilterSection: some View {
        VStack(spacing: 10) {
            // 搜索框
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

            // 分类筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(BackpackFilterType.allCases, id: \.self) { filter in
                        filterButton(for: filter)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
    }

    /// 筛选按钮
    private func filterButton(for filter: BackpackFilterType) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
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
        }
    }

    // MARK: - 物品列表

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredItems) { item in
                        if let definition = MockExplorationData.getItemDefinition(by: item.itemId) {
                            ItemRowView(item: item, definition: definition)
                        }
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
            Image(systemName: "bag")
                .font(.system(size: 50))
                .foregroundColor(ApocalypseTheme.textMuted)

            Text("没有找到物品")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text("尝试更换筛选条件或搜索其他物品")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - 物品行视图

struct ItemRowView: View {
    let item: InventoryItem
    let definition: ItemDefinition

    var body: some View {
        HStack(spacing: 12) {
            // 物品图标
            itemIcon

            // 物品信息
            VStack(alignment: .leading, spacing: 4) {
                // 名称和数量
                HStack(spacing: 6) {
                    Text(definition.name)
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Text("x\(item.quantity)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ApocalypseTheme.primary)
                }

                // 重量、品质、稀有度
                HStack(spacing: 10) {
                    // 重量
                    Label(String(format: "%.1fkg", definition.weight * Double(item.quantity)),
                          systemImage: "scalemass")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    // 品质（如果有）
                    if let quality = item.quality {
                        qualityBadge(quality)
                    }

                    // 稀有度标签
                    rarityBadge(definition.rarity)
                }
            }

            Spacer()

            // 操作按钮
            actionButtons
        }
        .padding(12)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Subviews

    /// 物品图标
    private var itemIcon: some View {
        ZStack {
            Circle()
                .fill(definition.category.color.opacity(0.2))
                .frame(width: 48, height: 48)

            Image(systemName: definition.category.iconName)
                .font(.title2)
                .foregroundColor(definition.category.color)
        }
    }

    /// 品质标签
    private func qualityBadge(_ quality: ItemQuality) -> some View {
        Text(quality.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(quality.color)
            .cornerRadius(4)
    }

    /// 稀有度标签
    private func rarityBadge(_ rarity: ItemRarity) -> some View {
        Text(rarity.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(rarity.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(rarity.color.opacity(0.2))
            .cornerRadius(4)
    }

    /// 操作按钮
    private var actionButtons: some View {
        VStack(spacing: 6) {
            // 使用按钮
            Button(action: {
                print("[背包] 使用物品: \(definition.name) (ID: \(item.itemId))")
            }) {
                Text("使用")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 50)
                    .padding(.vertical, 6)
                    .background(ApocalypseTheme.primary)
                    .cornerRadius(6)
            }

            // 存储按钮
            Button(action: {
                print("[背包] 存储物品: \(definition.name) (ID: \(item.itemId))")
            }) {
                Text("存储")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                    .frame(width: 50)
                    .padding(.vertical, 6)
                    .background(ApocalypseTheme.background)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ApocalypseTheme.textMuted, lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BackpackView()
}
