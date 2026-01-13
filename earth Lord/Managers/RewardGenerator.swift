//
//  RewardGenerator.swift
//  earth Lord
//
//  奖励生成器 - 根据行走距离生成奖励物品
//

import Foundation

// MARK: - 奖励等级

/// 奖励等级枚举
enum RewardTier: String, CaseIterable {
    case none = "none"           // 无奖励 (< 200m)
    case bronze = "bronze"       // 铜级 (200-500m)
    case silver = "silver"       // 银级 (500-1000m)
    case gold = "gold"           // 金级 (1000-2000m)
    case diamond = "diamond"     // 钻石级 (> 2000m)

    /// 等级中文名称
    var displayName: String {
        switch self {
        case .none: return "无奖励"
        case .bronze: return "铜级"
        case .silver: return "银级"
        case .gold: return "金级"
        case .diamond: return "钻石级"
        }
    }

    /// 等级图标
    var icon: String {
        switch self {
        case .none: return "xmark.circle"
        case .bronze: return "seal"
        case .silver: return "seal.fill"
        case .gold: return "star.fill"
        case .diamond: return "sparkles"
        }
    }

    /// 等级颜色名称（用于 UI 显示）
    var colorName: String {
        switch self {
        case .none: return "gray"
        case .bronze: return "brown"
        case .silver: return "gray"
        case .gold: return "yellow"
        case .diamond: return "cyan"
        }
    }

    /// 奖励物品数量
    var itemCount: Int {
        switch self {
        case .none: return 0
        case .bronze: return 1
        case .silver: return 2
        case .gold: return 3
        case .diamond: return 5
        }
    }

    /// 普通物品概率
    var commonProbability: Double {
        switch self {
        case .none: return 0
        case .bronze: return 0.90   // 90%
        case .silver: return 0.70   // 70%
        case .gold: return 0.50     // 50%
        case .diamond: return 0.30  // 30%
        }
    }

    /// 稀有物品概率
    var rareProbability: Double {
        switch self {
        case .none: return 0
        case .bronze: return 0.10   // 10%
        case .silver: return 0.25   // 25%
        case .gold: return 0.35     // 35%
        case .diamond: return 0.40  // 40%
        }
    }

    /// 史诗物品概率
    var epicProbability: Double {
        switch self {
        case .none: return 0
        case .bronze: return 0      // 0%
        case .silver: return 0.05   // 5%
        case .gold: return 0.15     // 15%
        case .diamond: return 0.30  // 30%
        }
    }
}

// MARK: - 奖励生成器

/// 奖励生成器（单例模式）
class RewardGenerator {

    // MARK: - Singleton

    static let shared = RewardGenerator()

    // MARK: - 物品池

    /// 普通物品池
    private let commonItemPool: [String] = [
        "item_water_bottle",    // 矿泉水
        "item_purified_water",  // 纯净水
        "item_canned_food",     // 罐头食品
        "item_biscuit",         // 饼干
        "item_dried_meat",      // 肉干
        "item_bandage",         // 绷带
        "item_matches",         // 火柴
        "item_wood",            // 木材
        "item_scrap_metal",     // 废金属
        "item_cloth",           // 布料
        "item_rope"             // 绳子
    ]

    /// 稀有物品池
    private let rareItemPool: [String] = [
        "item_medicine",        // 急救药品
        "item_first_aid_kit",   // 急救包
        "item_flashlight",      // 手电筒
        "item_radio",           // 收音机
        "item_toolbox"          // 工具箱
    ]

    /// 史诗物品池
    private let epicItemPool: [String] = [
        "item_antibiotics",     // 抗生素
        "item_generator_parts", // 发电机零件
        "item_gas_mask",        // 防毒面具
        "item_night_vision"     // 夜视仪
    ]

    // MARK: - Initialization

    private init() {
        print("🎁 RewardGenerator 初始化")
    }

    // MARK: - 核心方法

    /// 根据距离计算奖励等级
    /// - Parameter distance: 行走距离（米）
    /// - Returns: 奖励等级
    func calculateTier(distance: Double) -> RewardTier {
        switch distance {
        case 0..<200:
            return .none
        case 200..<500:
            return .bronze
        case 500..<1000:
            return .silver
        case 1000..<2000:
            return .gold
        default:
            return .diamond
        }
    }

    /// 根据距离生成奖励物品
    /// - Parameter distance: 行走距离（米）
    /// - Returns: 奖励物品列表
    func generateReward(distance: Double) -> [FoundItem] {
        let tier = calculateTier(distance: distance)

        // 无奖励
        if tier == .none {
            print("🎁 距离 \(Int(distance))m < 200m，无奖励")
            return []
        }

        print("🎁 生成 \(tier.displayName) 奖励，物品数量: \(tier.itemCount)")

        var rewards: [FoundItem] = []

        // 生成指定数量的物品
        for i in 0..<tier.itemCount {
            let item = generateSingleItem(tier: tier)
            rewards.append(item)
            print("  [\(i + 1)] \(item.itemId) x\(item.quantity)")
        }

        return rewards
    }

    /// 生成单个奖励物品
    /// - Parameter tier: 奖励等级
    /// - Returns: 发现的物品
    private func generateSingleItem(tier: RewardTier) -> FoundItem {
        // 1. 掷骰子决定稀有度
        let roll = Double.random(in: 0...1)
        let itemPool: [String]
        var quality: ItemQuality? = nil
        var isCommonPool = false

        if roll < tier.epicProbability {
            // 史诗物品
            itemPool = epicItemPool
            quality = randomQuality(minLevel: .rare)
        } else if roll < tier.epicProbability + tier.rareProbability {
            // 稀有物品
            itemPool = rareItemPool
            quality = randomQuality(minLevel: .uncommon)
        } else {
            // 普通物品
            itemPool = commonItemPool
            quality = nil  // 普通物品通常没有品质
            isCommonPool = true
        }

        // 2. 从物品池随机抽取
        let itemId = itemPool.randomElement() ?? commonItemPool[0]

        // 3. 决定数量（普通物品可能多个，稀有/史诗物品通常1个）
        let quantity: Int
        if isCommonPool {
            quantity = Int.random(in: 1...3)
        } else {
            quantity = 1
        }

        return FoundItem(
            itemId: itemId,
            quantity: quantity,
            quality: quality
        )
    }

    /// 生成随机品质
    /// - Parameter minLevel: 最低品质等级
    /// - Returns: 随机品质
    private func randomQuality(minLevel: ItemQuality) -> ItemQuality {
        let allQualities: [ItemQuality] = [.poor, .common, .uncommon, .rare, .epic, .legendary]

        // 找到最低等级的索引
        guard let minIndex = allQualities.firstIndex(of: minLevel) else {
            return .common
        }

        // 从最低等级开始的品质列表
        let availableQualities = Array(allQualities[minIndex...])

        // 权重：品质越高，概率越低
        let weights: [Double]
        switch availableQualities.count {
        case 6: // poor 开始
            weights = [0.05, 0.30, 0.30, 0.20, 0.10, 0.05]
        case 5: // common 开始
            weights = [0.35, 0.30, 0.20, 0.10, 0.05]
        case 4: // uncommon 开始
            weights = [0.40, 0.30, 0.20, 0.10]
        case 3: // rare 开始
            weights = [0.50, 0.35, 0.15]
        case 2: // epic 开始
            weights = [0.70, 0.30]
        default:
            weights = [1.0]
        }

        // 加权随机选择
        let roll = Double.random(in: 0...1)
        var cumulative: Double = 0

        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if roll <= cumulative {
                return availableQualities[index]
            }
        }

        return availableQualities.last ?? .common
    }

    // MARK: - 辅助方法

    /// 格式化奖励预览（用于 UI 显示）
    /// - Parameter distance: 预期行走距离
    /// - Returns: 奖励预览文本
    func previewReward(distance: Double) -> String {
        let tier = calculateTier(distance: distance)

        if tier == .none {
            return "行走 200 米以上才能获得奖励"
        }

        return "\(tier.displayName)奖励：最多 \(tier.itemCount) 件物品"
    }

    /// 获取下一等级所需距离
    /// - Parameter currentDistance: 当前距离
    /// - Returns: (下一等级, 还需距离)
    func nextTierInfo(currentDistance: Double) -> (tier: RewardTier, remaining: Double)? {
        let thresholds: [(RewardTier, Double)] = [
            (.bronze, 200),
            (.silver, 500),
            (.gold, 1000),
            (.diamond, 2000)
        ]

        for (tier, threshold) in thresholds {
            if currentDistance < threshold {
                return (tier, threshold - currentDistance)
            }
        }

        // 已经是最高等级
        return nil
    }
}
