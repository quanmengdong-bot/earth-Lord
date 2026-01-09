//
//  Territory.swift
//  earth Lord
//
//  领地数据模型 - Day17
//

import Foundation
import CoreLocation

// MARK: - 领地模型

/// 领地数据结构（对应 Supabase territories 表）
struct Territory: Codable, Identifiable {
    /// 领地唯一ID
    let id: UUID

    /// 所有者用户ID
    let userId: UUID

    /// 领地名称
    var name: String

    /// GPS路径点数组（JSONB格式存储）
    let path: [PathPoint]

    /// 领地面积（平方米）
    let area: Double

    /// 创建时间
    let createdAt: Date?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case path
        case area
        case createdAt = "created_at"
    }
}

// MARK: - 路径点模型

/// GPS路径点（用于 JSONB 存储）
struct PathPoint: Codable {
    /// 纬度
    let latitude: Double

    /// 经度
    let longitude: Double

    /// 从 CLLocationCoordinate2D 创建
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    /// 转换为 CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - 创建领地请求模型

/// 用于插入新领地的数据结构（不包含 id 和 created_at）
struct CreateTerritoryRequest: Codable {
    /// 所有者用户ID
    let userId: UUID

    /// 领地名称
    let name: String

    /// GPS路径点数组
    let path: [PathPoint]

    /// 领地面积（平方米）
    let area: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case path
        case area
    }
}

// MARK: - 扩展：从坐标数组创建路径点数组

extension Array where Element == CLLocationCoordinate2D {
    /// 转换为 PathPoint 数组
    var asPathPoints: [PathPoint] {
        self.map { PathPoint(coordinate: $0) }
    }
}

extension Array where Element == PathPoint {
    /// 转换为 CLLocationCoordinate2D 数组
    var asCoordinates: [CLLocationCoordinate2D] {
        self.map { $0.coordinate }
    }
}
