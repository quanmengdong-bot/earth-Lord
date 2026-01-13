//
//  MockExplorationData.swift
//  earth Lord
//
//  探索模块测试假数据
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - POI 状态枚举

/// 兴趣点发现状态
enum POIDiscoveryStatus: String, Codable {
    case undiscovered = "undiscovered"  // 未发现（地图上不显示或显示为问号）
    case discovered = "discovered"       // 已发现（可以查看详情）
    case looted = "looted"              // 已搜刮（物资已被拾取）
}

/// 兴趣点资源状态
enum POIResourceStatus: String, Codable {
    case hasResources = "has_resources"  // 有物资可拾取
    case empty = "empty"                 // 已被搜空
    case unknown = "unknown"             // 未知（未探索）
}

/// 兴趣点类型
enum POIType: String, Codable {
    case supermarket = "supermarket"     // 超市
    case hospital = "hospital"           // 医院
    case gasStation = "gas_station"      // 加油站
    case pharmacy = "pharmacy"           // 药店
    case factory = "factory"             // 工厂
    case warehouse = "warehouse"         // 仓库
    case residential = "residential"     // 居民区

    /// 类型对应的图标
    var iconName: String {
        switch self {
        case .hospital: return "cross.case.fill"
        case .supermarket: return "cart.fill"
        case .factory: return "building.2.fill"
        case .pharmacy: return "pills.fill"
        case .gasStation: return "fuelpump.fill"
        case .warehouse: return "shippingbox.fill"
        case .residential: return "house.fill"
        }
    }

    /// 类型对应的颜色
    var themeColor: Color {
        switch self {
        case .hospital: return Color.red
        case .supermarket: return Color.green
        case .factory: return Color.gray
        case .pharmacy: return Color.purple
        case .gasStation: return Color.orange
        case .warehouse: return Color.brown
        case .residential: return Color.blue
        }
    }

    /// 类型中文名称
    var displayName: String {
        switch self {
        case .hospital: return "医院"
        case .supermarket: return "超市"
        case .factory: return "工厂"
        case .pharmacy: return "药店"
        case .gasStation: return "加油站"
        case .warehouse: return "仓库"
        case .residential: return "居民区"
        }
    }
}

// MARK: - POI 模型

/// 兴趣点（Point of Interest）数据模型
struct POI: Identifiable, Codable {
    /// 唯一标识符
    let id: String

    /// POI名称
    let name: String

    /// POI类型
    let type: POIType

    /// 地理坐标
    let latitude: Double
    let longitude: Double

    /// 发现状态
    var discoveryStatus: POIDiscoveryStatus

    /// 资源状态
    var resourceStatus: POIResourceStatus

    /// 危险等级（1-5，5最危险）
    let dangerLevel: Int

    /// 描述信息
    let description: String

    /// 坐标转换
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - 物品相关枚举

/// 物品分类
enum ItemCategory: String, Codable, CaseIterable {
    case water = "water"           // 水类
    case food = "food"             // 食物
    case medical = "medical"       // 医疗用品
    case material = "material"     // 材料
    case tool = "tool"             // 工具
    case weapon = "weapon"         // 武器
    case clothing = "clothing"     // 服装
    case misc = "misc"             // 杂项

    /// 分类中文名称
    var displayName: String {
        switch self {
        case .water: return "饮用水"
        case .food: return "食物"
        case .medical: return "医疗"
        case .material: return "材料"
        case .tool: return "工具"
        case .weapon: return "武器"
        case .clothing: return "服装"
        case .misc: return "杂项"
        }
    }

    /// 分类图标
    var iconName: String {
        switch self {
        case .water: return "drop.fill"
        case .food: return "fork.knife"
        case .medical: return "cross.case.fill"
        case .material: return "cube.box.fill"
        case .tool: return "wrench.and.screwdriver.fill"
        case .weapon: return "shield.fill"
        case .clothing: return "tshirt.fill"
        case .misc: return "questionmark.square.fill"
        }
    }

    /// 分类对应颜色
    var color: Color {
        switch self {
        case .water: return Color.blue
        case .food: return Color.orange
        case .medical: return Color.red
        case .material: return Color.brown
        case .tool: return Color.gray
        case .weapon: return Color.red
        case .clothing: return Color.purple
        case .misc: return Color.gray
        }
    }
}

/// 物品品质等级
enum ItemQuality: String, Codable, CaseIterable {
    case poor = "poor"             // 劣质（灰色）
    case common = "common"         // 普通（白色）
    case uncommon = "uncommon"     // 优良（绿色）
    case rare = "rare"             // 稀有（蓝色）
    case epic = "epic"             // 史诗（紫色）
    case legendary = "legendary"   // 传说（橙色）

    /// 品质中文名称
    var displayName: String {
        switch self {
        case .poor: return "劣质"
        case .common: return "普通"
        case .uncommon: return "优良"
        case .rare: return "稀有"
        case .epic: return "史诗"
        case .legendary: return "传说"
        }
    }

    /// 品质对应颜色
    var color: Color {
        switch self {
        case .poor: return Color.gray
        case .common: return Color.white
        case .uncommon: return Color.green
        case .rare: return Color.blue
        case .epic: return Color.purple
        case .legendary: return Color.orange
        }
    }
}

/// 物品稀有度（影响掉落概率）
enum ItemRarity: String, Codable {
    case veryCommon = "very_common"  // 非常常见（掉率高）
    case common = "common"           // 常见
    case uncommon = "uncommon"       // 不常见
    case rare = "rare"               // 稀有
    case veryRare = "very_rare"      // 非常稀有（掉率低）

    /// 稀有度中文名称
    var displayName: String {
        switch self {
        case .veryCommon: return "普通"
        case .common: return "常见"
        case .uncommon: return "优秀"
        case .rare: return "稀有"
        case .veryRare: return "史诗"
        }
    }

    /// 稀有度对应颜色
    var color: Color {
        switch self {
        case .veryCommon: return Color.gray
        case .common: return Color.gray
        case .uncommon: return Color.green
        case .rare: return Color.blue
        case .veryRare: return Color.purple
        }
    }
}

// MARK: - 物品定义模型

/// 物品定义（游戏中所有物品的元数据）
/// 用途：定义物品的基本属性，不包含数量和品质，作为物品模板
struct ItemDefinition: Identifiable, Codable {
    /// 物品唯一ID（如 "item_water_bottle"）
    let id: String

    /// 物品中文名称
    let name: String

    /// 物品分类
    let category: ItemCategory

    /// 单个物品重量（千克）
    let weight: Double

    /// 单个物品体积（升）
    let volume: Double

    /// 物品稀有度（影响掉落概率）
    let rarity: ItemRarity

    /// 物品描述
    let description: String

    /// 是否可堆叠
    let stackable: Bool

    /// 最大堆叠数量
    let maxStack: Int

    /// 是否有品质属性（如武器、工具有品质，水和食物通常没有）
    let hasQuality: Bool
}

// MARK: - 背包物品模型

/// 背包中的物品实例
/// 用途：表示玩家背包中实际拥有的物品，包含数量和品质
struct InventoryItem: Identifiable, Codable {
    /// 实例唯一ID（用于区分同一物品的不同堆叠）
    let id: String

    /// 物品定义ID（关联 ItemDefinition）
    let itemId: String

    /// 物品数量
    var quantity: Int

    /// 物品品质（部分物品没有品质，为nil）
    let quality: ItemQuality?

    /// 获取时间
    let acquiredAt: Date

    /// 计算总重量
    func totalWeight(definition: ItemDefinition) -> Double {
        return definition.weight * Double(quantity)
    }

    /// 计算总体积
    func totalVolume(definition: ItemDefinition) -> Double {
        return definition.volume * Double(quantity)
    }
}

// MARK: - 探索结果模型

/// 单次探索结果统计
/// 用途：记录一次探索活动的成果
struct ExplorationResult: Identifiable, Codable {
    /// 结果ID
    let id: String

    /// 探索开始时间
    let startTime: Date

    /// 探索结束时间
    let endTime: Date

    /// 本次行走距离（米）
    let walkDistance: Double

    /// 本次探索面积（平方米）
    let exploredArea: Double

    /// 本次获得的物品列表
    let itemsFound: [FoundItem]

    /// 探索时长（分钟）
    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    /// 格式化行走距离
    var formattedDistance: String {
        if walkDistance >= 1000 {
            return String(format: "%.2f km", walkDistance / 1000)
        }
        return String(format: "%.0f m", walkDistance)
    }

    /// 格式化探索面积
    var formattedArea: String {
        if exploredArea >= 1_000_000 {
            return String(format: "%.2f km²", exploredArea / 1_000_000)
        } else if exploredArea >= 10_000 {
            return String(format: "%.2f 公顷", exploredArea / 10_000)
        }
        return String(format: "%.0f m²", exploredArea)
    }
}

/// 探索中发现的物品
struct FoundItem: Codable {
    /// 物品定义ID
    let itemId: String

    /// 发现数量
    let quantity: Int

    /// 物品品质（可选）
    let quality: ItemQuality?
}

/// 累计探索统计
/// 用途：记录玩家的累计探索数据和排名
struct ExplorationStats: Codable {
    /// 累计行走距离（米）
    let totalWalkDistance: Double

    /// 累计探索面积（平方米）
    let totalExploredArea: Double

    /// 累计探索时长（分钟）
    let totalDurationMinutes: Int

    /// 累计发现POI数量
    let totalPOIsDiscovered: Int

    /// 累计收集物品数量
    let totalItemsCollected: Int

    /// 行走距离排名
    let walkDistanceRank: Int

    /// 探索面积排名
    let exploredAreaRank: Int
}

// MARK: - ============================================
// MARK: - 测试假数据
// MARK: - ============================================

/// 探索模块测试假数据
/// 用途：用于开发和测试阶段，模拟真实的游戏数据
struct MockExplorationData {

    // MARK: - POI 假数据

    /// 5个不同状态的兴趣点测试数据
    /// 用途：测试POI列表展示、地图标记、探索交互
    static let mockPOIs: [POI] = [
        // 废弃超市：已发现，有物资可拾取
        POI(
            id: "poi_001",
            name: "废弃超市",
            type: .supermarket,
            latitude: 31.2304,
            longitude: 121.4737,
            discoveryStatus: .discovered,
            resourceStatus: .hasResources,
            dangerLevel: 2,
            description: "一家废弃的连锁超市，货架上还残留着一些物资。"
        ),

        // 医院废墟：已发现，已被其他幸存者搜刮过
        POI(
            id: "poi_002",
            name: "医院废墟",
            type: .hospital,
            latitude: 31.2354,
            longitude: 121.4787,
            discoveryStatus: .discovered,
            resourceStatus: .empty,
            dangerLevel: 4,
            description: "曾经繁忙的医院，现在只剩下破碎的玻璃和空荡荡的病房。已被搜刮一空。"
        ),

        // 加油站：未发现，地图上显示为问号
        POI(
            id: "poi_003",
            name: "加油站",
            type: .gasStation,
            latitude: 31.2284,
            longitude: 121.4817,
            discoveryStatus: .undiscovered,
            resourceStatus: .unknown,
            dangerLevel: 3,
            description: "需要靠近才能发现详细信息。"
        ),

        // 药店废墟：已发现，有珍贵的医疗物资
        POI(
            id: "poi_004",
            name: "药店废墟",
            type: .pharmacy,
            latitude: 31.2324,
            longitude: 121.4697,
            discoveryStatus: .discovered,
            resourceStatus: .hasResources,
            dangerLevel: 2,
            description: "一家小型药店，柜台后面可能还藏着一些药品。"
        ),

        // 工厂废墟：未发现
        POI(
            id: "poi_005",
            name: "工厂废墟",
            type: .factory,
            latitude: 31.2264,
            longitude: 121.4657,
            discoveryStatus: .undiscovered,
            resourceStatus: .unknown,
            dangerLevel: 5,
            description: "需要靠近才能发现详细信息。"
        )
    ]

    // MARK: - 物品定义假数据

    /// 物品定义表
    /// 用途：定义游戏中所有可获得物品的基本属性
    static let itemDefinitions: [ItemDefinition] = [
        // 水类
        ItemDefinition(
            id: "item_water_bottle",
            name: "矿泉水",
            category: .water,
            weight: 0.5,
            volume: 0.5,
            rarity: .common,
            description: "一瓶500ml的矿泉水，末日中的珍贵资源。",
            stackable: true,
            maxStack: 20,
            hasQuality: false
        ),

        // 食物类
        ItemDefinition(
            id: "item_canned_food",
            name: "罐头食品",
            category: .food,
            weight: 0.4,
            volume: 0.3,
            rarity: .common,
            description: "密封良好的罐头，保质期很长。",
            stackable: true,
            maxStack: 15,
            hasQuality: false
        ),

        // 医疗类 - 绷带
        ItemDefinition(
            id: "item_bandage",
            name: "绷带",
            category: .medical,
            weight: 0.05,
            volume: 0.02,
            rarity: .common,
            description: "医用绷带，可以处理轻伤。",
            stackable: true,
            maxStack: 30,
            hasQuality: false
        ),

        // 医疗类 - 药品
        ItemDefinition(
            id: "item_medicine",
            name: "急救药品",
            category: .medical,
            weight: 0.1,
            volume: 0.05,
            rarity: .uncommon,
            description: "各类常用药品，可以治疗疾病。",
            stackable: true,
            maxStack: 10,
            hasQuality: false
        ),

        // 材料类 - 木材
        ItemDefinition(
            id: "item_wood",
            name: "木材",
            category: .material,
            weight: 1.0,
            volume: 2.0,
            rarity: .veryCommon,
            description: "基础建筑材料，用途广泛。",
            stackable: true,
            maxStack: 50,
            hasQuality: false
        ),

        // 材料类 - 废金属
        ItemDefinition(
            id: "item_scrap_metal",
            name: "废金属",
            category: .material,
            weight: 0.8,
            volume: 0.5,
            rarity: .common,
            description: "可以熔炼或用于制作的金属碎片。",
            stackable: true,
            maxStack: 30,
            hasQuality: false
        ),

        // 工具类 - 手电筒（有品质）
        ItemDefinition(
            id: "item_flashlight",
            name: "手电筒",
            category: .tool,
            weight: 0.3,
            volume: 0.2,
            rarity: .uncommon,
            description: "照明工具，夜间探索必备。品质越高，照明范围越大。",
            stackable: false,
            maxStack: 1,
            hasQuality: true
        ),

        // 工具类 - 绳子
        ItemDefinition(
            id: "item_rope",
            name: "绳子",
            category: .tool,
            weight: 0.5,
            volume: 0.3,
            rarity: .common,
            description: "结实的尼龙绳，可用于攀爬、捆绑等。",
            stackable: true,
            maxStack: 10,
            hasQuality: false
        )
    ]

    // MARK: - 背包物品假数据

    /// 背包物品测试数据（8种不同类型的物品）
    /// 用途：测试背包UI展示、物品管理、重量计算
    static let mockInventoryItems: [InventoryItem] = [
        // 矿泉水 x 5
        InventoryItem(
            id: "inv_001",
            itemId: "item_water_bottle",
            quantity: 5,
            quality: nil,  // 水没有品质
            acquiredAt: Date().addingTimeInterval(-3600)
        ),

        // 罐头食品 x 8
        InventoryItem(
            id: "inv_002",
            itemId: "item_canned_food",
            quantity: 8,
            quality: nil,  // 食物没有品质
            acquiredAt: Date().addingTimeInterval(-7200)
        ),

        // 绷带 x 12
        InventoryItem(
            id: "inv_003",
            itemId: "item_bandage",
            quantity: 12,
            quality: nil,  // 消耗品没有品质
            acquiredAt: Date().addingTimeInterval(-1800)
        ),

        // 急救药品 x 3
        InventoryItem(
            id: "inv_004",
            itemId: "item_medicine",
            quantity: 3,
            quality: nil,
            acquiredAt: Date().addingTimeInterval(-5400)
        ),

        // 木材 x 20
        InventoryItem(
            id: "inv_005",
            itemId: "item_wood",
            quantity: 20,
            quality: nil,  // 材料没有品质
            acquiredAt: Date().addingTimeInterval(-10800)
        ),

        // 废金属 x 15
        InventoryItem(
            id: "inv_006",
            itemId: "item_scrap_metal",
            quantity: 15,
            quality: nil,
            acquiredAt: Date().addingTimeInterval(-14400)
        ),

        // 手电筒 x 1（稀有品质）
        InventoryItem(
            id: "inv_007",
            itemId: "item_flashlight",
            quantity: 1,
            quality: .rare,  // 工具有品质
            acquiredAt: Date().addingTimeInterval(-86400)
        ),

        // 绳子 x 4
        InventoryItem(
            id: "inv_008",
            itemId: "item_rope",
            quantity: 4,
            quality: nil,
            acquiredAt: Date().addingTimeInterval(-43200)
        )
    ]

    // MARK: - 探索结果假数据

    /// 单次探索结果示例
    /// 用途：测试探索结束后的结果展示页面
    static let mockExplorationResult = ExplorationResult(
        id: "explore_001",
        startTime: Date().addingTimeInterval(-1800),  // 30分钟前开始
        endTime: Date(),                               // 现在结束
        walkDistance: 2500,                            // 本次行走2500米
        exploredArea: 50000,                           // 本次探索5万平方米
        itemsFound: [
            // 发现木材 x 5
            FoundItem(itemId: "item_wood", quantity: 5, quality: nil),
            // 发现矿泉水 x 3
            FoundItem(itemId: "item_water_bottle", quantity: 3, quality: nil),
            // 发现罐头 x 2
            FoundItem(itemId: "item_canned_food", quantity: 2, quality: nil)
        ]
    )

    /// 累计探索统计假数据
    /// 用途：测试个人统计页面、排行榜展示
    static let mockExplorationStats = ExplorationStats(
        totalWalkDistance: 15000,       // 累计行走15公里
        totalExploredArea: 250000,      // 累计探索25万平方米
        totalDurationMinutes: 480,      // 累计探索8小时
        totalPOIsDiscovered: 12,        // 累计发现12个POI
        totalItemsCollected: 156,       // 累计收集156个物品
        walkDistanceRank: 42,           // 行走距离排名第42
        exploredAreaRank: 38            // 探索面积排名第38
    )

    // MARK: - 辅助方法

    /// 根据物品ID获取物品定义
    /// 用途：在显示背包物品时获取物品的详细信息
    static func getItemDefinition(by id: String) -> ItemDefinition? {
        return itemDefinitions.first { $0.id == id }
    }

    /// 计算背包总重量
    /// 用途：检查是否超出负重上限
    static func calculateTotalWeight(items: [InventoryItem]) -> Double {
        return items.reduce(0) { total, item in
            guard let definition = getItemDefinition(by: item.itemId) else { return total }
            return total + item.totalWeight(definition: definition)
        }
    }

    /// 计算背包总体积
    /// 用途：检查是否超出背包容量
    static func calculateTotalVolume(items: [InventoryItem]) -> Double {
        return items.reduce(0) { total, item in
            guard let definition = getItemDefinition(by: item.itemId) else { return total }
            return total + item.totalVolume(definition: definition)
        }
    }

    /// 获取已发现的POI列表
    /// 用途：在地图上显示已发现的兴趣点
    static func getDiscoveredPOIs() -> [POI] {
        return mockPOIs.filter { $0.discoveryStatus != .undiscovered }
    }

    /// 获取有资源的POI列表
    /// 用途：显示可探索的目标地点
    static func getPOIsWithResources() -> [POI] {
        return mockPOIs.filter { $0.resourceStatus == .hasResources }
    }
}

// MARK: - Preview 辅助

#if DEBUG
extension MockExplorationData {
    /// 打印所有假数据摘要（调试用）
    static func printSummary() {
        print("=== 探索模块假数据摘要 ===")
        print("POI数量: \(mockPOIs.count)")
        print("  - 已发现: \(mockPOIs.filter { $0.discoveryStatus == .discovered }.count)")
        print("  - 未发现: \(mockPOIs.filter { $0.discoveryStatus == .undiscovered }.count)")
        print("  - 有资源: \(mockPOIs.filter { $0.resourceStatus == .hasResources }.count)")
        print("")
        print("物品定义数量: \(itemDefinitions.count)")
        print("背包物品数量: \(mockInventoryItems.count)")
        print("背包总重量: \(String(format: "%.2f", calculateTotalWeight(items: mockInventoryItems))) kg")
        print("背包总体积: \(String(format: "%.2f", calculateTotalVolume(items: mockInventoryItems))) L")
        print("")
        print("本次探索:")
        print("  - 行走距离: \(mockExplorationResult.formattedDistance)")
        print("  - 探索面积: \(mockExplorationResult.formattedArea)")
        print("  - 探索时长: \(mockExplorationResult.durationMinutes) 分钟")
        print("  - 获得物品: \(mockExplorationResult.itemsFound.count) 种")
        print("")
        print("累计统计:")
        print("  - 累计距离: \(mockExplorationStats.totalWalkDistance / 1000) km (排名 #\(mockExplorationStats.walkDistanceRank))")
        print("  - 累计面积: \(mockExplorationStats.totalExploredArea / 10000) 公顷 (排名 #\(mockExplorationStats.exploredAreaRank))")
    }
}
#endif
