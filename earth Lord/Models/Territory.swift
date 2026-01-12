//
//  Territory.swift
//  earth Lord
//
//  领地数据模型 - Day18
//

import Foundation
import CoreLocation

// MARK: - 领地模型

/// 领地数据结构（对应 Supabase territories 表）
struct Territory: Codable, Identifiable {
    /// 领地唯一ID
    let id: String

    /// 所有者用户ID
    let userId: String

    /// 领地名称（可选，数据库允许为空）
    let name: String?

    /// GPS路径点数组（格式：[{"lat": x, "lon": y}]）
    let path: [[String: Double]]

    /// 领地面积（平方米）
    let area: Double

    /// 路径点数量
    let pointCount: Int?

    /// 是否激活
    let isActive: Bool?

    /// 圈地完成时间
    let completedAt: String?

    /// 圈地开始时间
    let startedAt: String?

    /// 创建时间
    let createdAt: String?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case path
        case area
        case pointCount = "point_count"
        case isActive = "is_active"
        case completedAt = "completed_at"
        case startedAt = "started_at"
        case createdAt = "created_at"
    }

    // MARK: - 转换方法

    /// 将 path 转换为 CLLocationCoordinate2D 数组
    func toCoordinates() -> [CLLocationCoordinate2D] {
        return path.compactMap { point in
            guard let lat = point["lat"], let lon = point["lon"] else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }

    /// 格式化面积显示
    var formattedArea: String {
        if area >= 1_000_000 {
            return String(format: "%.2f km²", area / 1_000_000)
        } else if area >= 10_000 {
            return String(format: "%.2f 公顷", area / 10_000)
        } else {
            return String(format: "%.0f m²", area)
        }
    }

    /// 显示名称（如果 name 为空则显示默认名称）
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        return "未命名领地"
    }

    /// 格式化创建时间
    var formattedCreatedAt: String {
        guard let createdAt = createdAt else { return "未知时间" }

        // 解析 ISO8601 格式
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }

        // 尝试不带毫秒的格式
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }

        return createdAt
    }
}

// MARK: - 路径点模型（兼容旧代码）

/// GPS路径点（用于 JSONB 存储）
struct PathPoint: Codable {
    /// 纬度
    let lat: Double

    /// 经度
    let lon: Double

    /// 从 CLLocationCoordinate2D 创建
    init(coordinate: CLLocationCoordinate2D) {
        self.lat = coordinate.latitude
        self.lon = coordinate.longitude
    }

    /// 转换为 CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// 转换为字典格式
    var asDictionary: [String: Double] {
        return ["lat": lat, "lon": lon]
    }
}

// MARK: - 扩展：从坐标数组创建路径点数组

extension Array where Element == CLLocationCoordinate2D {
    /// 转换为 PathPoint 数组
    var asPathPoints: [PathPoint] {
        self.map { PathPoint(coordinate: $0) }
    }

    /// 转换为字典数组格式（用于上传）
    var asPathDictionaries: [[String: Double]] {
        self.map { ["lat": $0.latitude, "lon": $0.longitude] }
    }
}

extension Array where Element == PathPoint {
    /// 转换为 CLLocationCoordinate2D 数组
    var asCoordinates: [CLLocationCoordinate2D] {
        self.map { $0.coordinate }
    }

    /// 转换为字典数组格式
    var asDictionaries: [[String: Double]] {
        self.map { $0.asDictionary }
    }
}
