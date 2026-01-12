//
//  CollisionModels.swift
//  earth Lord
//
//  碰撞检测数据模型 - Day19
//

import Foundation

// MARK: - 预警级别

/// 碰撞预警级别
enum WarningLevel: Int {
    case safe = 0       // 安全（>100m）
    case caution = 1    // 注意（50-100m）- 黄色横幅
    case warning = 2    // 警告（25-50m）- 橙色横幅
    case danger = 3     // 危险（<25m）- 红色横幅
    case violation = 4  // 违规（已碰撞）- 红色横幅 + 停止圈地

    /// 预警级别描述
    var description: String {
        switch self {
        case .safe: return "安全"
        case .caution: return "注意"
        case .warning: return "警告"
        case .danger: return "危险"
        case .violation: return "违规"
        }
    }

    /// 是否需要显示横幅
    var shouldShowBanner: Bool {
        return self != .safe
    }

    /// 是否需要停止圈地
    var shouldStopTracking: Bool {
        return self == .violation
    }
}

// MARK: - 碰撞类型

/// 碰撞类型
enum CollisionType {
    case pointInTerritory       // 点在他人领地内
    case pathCrossTerritory     // 路径穿越他人领地边界
    case selfIntersection       // 自相交（Day 17 已有）

    /// 碰撞类型描述
    var description: String {
        switch self {
        case .pointInTerritory:
            return "位于他人领地内"
        case .pathCrossTerritory:
            return "穿越他人领地边界"
        case .selfIntersection:
            return "路径自相交"
        }
    }
}

// MARK: - 碰撞检测结果

/// 碰撞检测结果
struct CollisionResult {
    /// 是否碰撞
    let hasCollision: Bool

    /// 碰撞类型
    let collisionType: CollisionType?

    /// 提示消息
    let message: String?

    /// 距离最近领地的距离（米）
    let closestDistance: Double?

    /// 预警级别
    let warningLevel: WarningLevel

    /// 碰撞的领地名称（可选）
    let territoryName: String?

    // MARK: - 初始化

    init(
        hasCollision: Bool,
        collisionType: CollisionType? = nil,
        message: String? = nil,
        closestDistance: Double? = nil,
        warningLevel: WarningLevel,
        territoryName: String? = nil
    ) {
        self.hasCollision = hasCollision
        self.collisionType = collisionType
        self.message = message
        self.closestDistance = closestDistance
        self.warningLevel = warningLevel
        self.territoryName = territoryName
    }

    // MARK: - 便捷构造器

    /// 安全状态
    static var safe: CollisionResult {
        CollisionResult(
            hasCollision: false,
            collisionType: nil,
            message: nil,
            closestDistance: nil,
            warningLevel: .safe,
            territoryName: nil
        )
    }

    /// 创建违规结果
    static func violation(type: CollisionType, message: String, territoryName: String? = nil) -> CollisionResult {
        CollisionResult(
            hasCollision: true,
            collisionType: type,
            message: message,
            closestDistance: 0,
            warningLevel: .violation,
            territoryName: territoryName
        )
    }

    /// 创建预警结果
    static func warning(level: WarningLevel, distance: Double, message: String) -> CollisionResult {
        CollisionResult(
            hasCollision: false,
            collisionType: nil,
            message: message,
            closestDistance: distance,
            warningLevel: level,
            territoryName: nil
        )
    }
}
