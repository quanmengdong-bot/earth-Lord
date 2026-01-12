//
//  TerritoryManager.swift
//  earth Lord
//
//  领地管理器 - Day18
//  负责领地的上传和拉取操作（与 Supabase 交互）
//

import Foundation
import CoreLocation
import Combine
import Supabase

// MARK: - 边界框结构

/// 边界框（Bounding Box）
struct BoundingBox {
    let minLat: Double
    let maxLat: Double
    let minLon: Double
    let maxLon: Double
}

// MARK: - 领地管理器

@MainActor
class TerritoryManager: ObservableObject {

    // MARK: - Singleton

    static let shared = TerritoryManager()

    // MARK: - Published Properties

    /// 当前用户的领地列表
    @Published var territories: [Territory] = []

    /// 所有活跃的领地（用于地图显示）
    @Published var allTerritories: [Territory] = []

    /// 是否正在加载
    @Published var isLoading: Bool = false

    /// 错误信息
    @Published var errorMessage: String? = nil

    /// 最近保存的领地（用于显示成功提示）
    @Published var lastSavedTerritory: Territory? = nil

    // MARK: - Initialization

    private init() {
        print("🏰 TerritoryManager 初始化完成")
    }

    // MARK: - 坐标转换方法

    /// 将坐标数组转换为 path JSON 格式
    /// - Parameter coordinates: GPS坐标数组
    /// - Returns: 格式：[{"lat": x, "lon": y}, ...]
    func coordinatesToPathJSON(_ coordinates: [CLLocationCoordinate2D]) -> [[String: Double]] {
        return coordinates.map { coord in
            ["lat": coord.latitude, "lon": coord.longitude]
        }
    }

    /// 将坐标数组转换为 WKT 格式
    /// - Parameter coordinates: GPS坐标数组
    /// - Returns: WKT 字符串，格式：SRID=4326;POLYGON((lon lat, ...))
    /// - Note: WKT 格式是「经度在前，纬度在后」！多边形必须闭合（首尾相同）
    func coordinatesToWKT(_ coordinates: [CLLocationCoordinate2D]) -> String {
        guard coordinates.count >= 3 else {
            return ""
        }

        var wktCoords = coordinates

        // 确保多边形闭合（首尾相同）
        if let first = coordinates.first, let last = coordinates.last {
            if first.latitude != last.latitude || first.longitude != last.longitude {
                wktCoords.append(first)
            }
        }

        // WKT 格式：经度在前，纬度在后
        let pointStrings = wktCoords.map { coord in
            "\(coord.longitude) \(coord.latitude)"
        }

        let polygonString = pointStrings.joined(separator: ", ")
        return "SRID=4326;POLYGON((\(polygonString)))"
    }

    /// 计算坐标数组的边界框
    /// - Parameter coordinates: GPS坐标数组
    /// - Returns: 边界框 (minLat, maxLat, minLon, maxLon)
    func calculateBoundingBox(_ coordinates: [CLLocationCoordinate2D]) -> BoundingBox {
        guard !coordinates.isEmpty else {
            return BoundingBox(minLat: 0, maxLat: 0, minLon: 0, maxLon: 0)
        }

        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }

        return BoundingBox(
            minLat: lats.min() ?? 0,
            maxLat: lats.max() ?? 0,
            minLon: lons.min() ?? 0,
            maxLon: lons.max() ?? 0
        )
    }

    // MARK: - 上传领地

    /// 上传领地到 Supabase
    /// - Parameters:
    ///   - coordinates: GPS路径坐标数组
    ///   - area: 领地面积（平方米）
    ///   - startTime: 圈地开始时间
    /// - Throws: 上传错误
    func uploadTerritory(coordinates: [CLLocationCoordinate2D], area: Double, startTime: Date) async throws {
        print("📤 开始上传领地...")

        // 检查用户是否已登录
        guard let userId = AuthManager.shared.currentUser?.id else {
            let error = NSError(domain: "TerritoryManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "请先登录后再圈地"])
            errorMessage = "请先登录后再圈地"
            print("❌ 上传失败：用户未登录")
            throw error
        }

        isLoading = true
        errorMessage = nil

        // 准备上传数据
        let pathJSON = coordinatesToPathJSON(coordinates)
        let wktPolygon = coordinatesToWKT(coordinates)
        let bbox = calculateBoundingBox(coordinates)

        // 构建上传数据字典
        let uploadData: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "path": AnyEncodable(pathJSON),
            "polygon": AnyEncodable(wktPolygon),
            "bbox_min_lat": AnyEncodable(bbox.minLat),
            "bbox_max_lat": AnyEncodable(bbox.maxLat),
            "bbox_min_lon": AnyEncodable(bbox.minLon),
            "bbox_max_lon": AnyEncodable(bbox.maxLon),
            "area": AnyEncodable(area),
            "point_count": AnyEncodable(coordinates.count),
            "started_at": AnyEncodable(startTime.ISO8601Format()),
            "is_active": AnyEncodable(true)
        ]

        print("📊 上传数据：")
        print("   - user_id: \(userId)")
        print("   - point_count: \(coordinates.count)")
        print("   - area: \(Int(area)) m²")
        print("   - bbox: (\(bbox.minLat), \(bbox.maxLat), \(bbox.minLon), \(bbox.maxLon))")

        do {
            // 上传到 Supabase，并返回插入的数据
            let response: [Territory] = try await supabase
                .from("territories")
                .insert(uploadData)
                .select()
                .execute()
                .value

            print("✅ 领地上传成功！")

            // 记录日志
            TerritoryLogger.shared.log("领地上传成功, 面积: \(Int(area))m²", type: .success)

            // ⭐ Day18 关键：设置 lastSavedTerritory 以便后续更新名称
            if let savedTerritory = response.first {
                lastSavedTerritory = savedTerritory
                print("📝 保存的领地 ID: \(savedTerritory.id)")
            }

            // 刷新领地列表
            await fetchMyTerritories()

            isLoading = false

        } catch {
            let errorMsg = "上传领地失败: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ \(errorMsg)")

            // 记录日志
            TerritoryLogger.shared.log(errorMsg, type: .error)

            isLoading = false
            throw error
        }
    }

    // MARK: - 加载领地

    /// 加载所有活跃的领地
    /// - Returns: 领地数组
    func loadAllTerritories() async throws -> [Territory] {
        print("📥 加载所有活跃领地...")

        isLoading = true
        errorMessage = nil

        do {
            let response: [Territory] = try await supabase
                .from("territories")
                .select()
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value

            print("✅ 加载成功，共 \(response.count) 块活跃领地")

            allTerritories = response
            isLoading = false
            return response

        } catch {
            let errorMsg = "加载领地失败: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ \(errorMsg)")

            isLoading = false
            throw error
        }
    }

    /// 获取当前用户的所有领地
    func fetchMyTerritories() async {
        print("📥 获取我的领地列表...")

        // 检查用户是否已登录
        guard let userId = AuthManager.shared.currentUser?.id else {
            errorMessage = "请先登录"
            print("❌ 获取失败：用户未登录")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response: [Territory] = try await supabase
                .from("territories")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            print("✅ 获取成功，共 \(response.count) 块领地")

            territories = response

        } catch {
            let errorMsg = "获取领地列表失败: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ \(errorMsg)")
        }

        isLoading = false
    }

    /// 加载我的领地（带返回值）
    /// - Returns: 领地数组
    func loadMyTerritories() async throws -> [Territory] {
        print("📥 加载我的领地列表...")

        // 检查用户是否已登录
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "TerritoryManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "未登录"])
        }

        isLoading = true
        errorMessage = nil

        do {
            let response: [Territory] = try await supabase
                .from("territories")
                .select()
                .eq("user_id", value: userId)
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value

            print("✅ 加载成功，共 \(response.count) 块我的领地")

            territories = response
            isLoading = false
            return response

        } catch {
            let errorMsg = "加载领地失败: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ \(errorMsg)")
            isLoading = false
            throw error
        }
    }

    /// 删除领地
    /// - Parameter territory: 要删除的领地
    /// - Returns: 是否删除成功
    func deleteTerritory(_ territory: Territory) async -> Bool {
        print("🗑️ 删除领地: \(territory.displayName)")

        isLoading = true
        errorMessage = nil

        do {
            try await supabase
                .from("territories")
                .delete()
                .eq("id", value: territory.id)
                .execute()

            print("✅ 领地删除成功")

            // 从本地列表移除
            territories.removeAll { $0.id == territory.id }
            allTerritories.removeAll { $0.id == territory.id }

            isLoading = false
            return true

        } catch {
            let errorMsg = "删除领地失败: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ \(errorMsg)")

            isLoading = false
            return false
        }
    }

    /// 更新领地名称
    /// - Parameters:
    ///   - territory: 要更新的领地
    ///   - newName: 新名称
    /// - Returns: 是否更新成功
    func updateTerritoryName(_ territory: Territory, newName: String) async -> Bool {
        print("✏️ 更新领地名称: \(territory.displayName) -> \(newName)")

        isLoading = true
        errorMessage = nil

        do {
            try await supabase
                .from("territories")
                .update(["name": newName])
                .eq("id", value: territory.id)
                .execute()

            print("✅ 领地名称更新成功")

            // 更新本地列表
            if let index = territories.firstIndex(where: { $0.id == territory.id }) {
                // 由于 Territory 的 name 是 let，需要创建新的 Territory
                // 这里简单地重新获取数据
                await fetchMyTerritories()
            }

            isLoading = false
            return true

        } catch {
            let errorMsg = "更新领地名称失败: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ \(errorMsg)")

            isLoading = false
            return false
        }
    }

    // MARK: - 向后兼容方法

    /// 保存新领地到 Supabase（向后兼容 Day17 的接口）
    /// - Parameters:
    ///   - name: 领地名称（可选）
    ///   - path: GPS路径点数组
    ///   - area: 领地面积（平方米）
    /// - Returns: 保存成功的领地对象，失败返回 nil
    func saveTerritory(name: String, path: [CLLocationCoordinate2D], area: Double) async -> Territory? {
        print("💾 开始保存领地: \(name)")

        do {
            try await uploadTerritory(
                coordinates: path,
                area: area,
                startTime: Date()
            )

            // 更新名称（如果提供了名称）
            if let savedTerritory = lastSavedTerritory, !name.isEmpty {
                _ = await updateTerritoryName(savedTerritory, newName: name)
            }

            return lastSavedTerritory
        } catch {
            print("❌ 保存领地失败: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 碰撞检测算法（Day19）

    /// 射线法判断点是否在多边形内
    /// - Parameters:
    ///   - point: 待检测的点
    ///   - polygon: 多边形顶点数组
    /// - Returns: true 表示点在多边形内
    func isPointInPolygon(point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 3 else { return false }

        var inside = false
        let x = point.longitude
        let y = point.latitude

        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let xi = polygon[i].longitude
            let yi = polygon[i].latitude
            let xj = polygon[j].longitude
            let yj = polygon[j].latitude

            // 射线法：从点向右发射水平射线，计算与多边形边的交点数
            let intersect = ((yi > y) != (yj > y)) &&
                           (x < (xj - xi) * (y - yi) / (yj - yi) + xi)

            if intersect {
                inside.toggle()
            }
            j = i
        }

        return inside
    }

    /// 检查起始点是否在他人领地内
    /// - Parameters:
    ///   - location: 待检测的位置
    ///   - currentUserId: 当前用户 ID
    /// - Returns: 碰撞检测结果
    func checkPointCollision(location: CLLocationCoordinate2D, currentUserId: String) -> CollisionResult {
        // 过滤出他人的领地
        let otherTerritories = allTerritories.filter { territory in
            territory.userId.lowercased() != currentUserId.lowercased()
        }

        guard !otherTerritories.isEmpty else {
            return .safe
        }

        for territory in otherTerritories {
            let polygon = territory.toCoordinates()
            guard polygon.count >= 3 else { continue }

            if isPointInPolygon(point: location, polygon: polygon) {
                TerritoryLogger.shared.log("起点碰撞：位于「\(territory.displayName)」内", type: .error)
                return CollisionResult.violation(
                    type: .pointInTerritory,
                    message: "不能在他人领地内开始圈地！",
                    territoryName: territory.displayName
                )
            }
        }

        return .safe
    }

    /// 判断两条线段是否相交（CCW 算法）
    /// - Parameters:
    ///   - p1: 线段1起点
    ///   - p2: 线段1终点
    ///   - p3: 线段2起点
    ///   - p4: 线段2终点
    /// - Returns: true 表示相交
    private func segmentsIntersect(
        p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D,
        p3: CLLocationCoordinate2D, p4: CLLocationCoordinate2D
    ) -> Bool {
        /// CCW（Counter-Clockwise）判断
        func ccw(_ A: CLLocationCoordinate2D, _ B: CLLocationCoordinate2D, _ C: CLLocationCoordinate2D) -> Bool {
            return (C.latitude - A.latitude) * (B.longitude - A.longitude) >
                   (B.latitude - A.latitude) * (C.longitude - A.longitude)
        }

        return ccw(p1, p3, p4) != ccw(p2, p3, p4) && ccw(p1, p2, p3) != ccw(p1, p2, p4)
    }

    /// 检查路径是否穿越他人领地边界
    /// - Parameters:
    ///   - path: 当前路径坐标数组
    ///   - currentUserId: 当前用户 ID
    /// - Returns: 碰撞检测结果
    func checkPathCrossTerritory(path: [CLLocationCoordinate2D], currentUserId: String) -> CollisionResult {
        guard path.count >= 2 else { return .safe }

        // 过滤出他人的领地
        let otherTerritories = allTerritories.filter { territory in
            territory.userId.lowercased() != currentUserId.lowercased()
        }

        guard !otherTerritories.isEmpty else { return .safe }

        // 检查路径的每一段
        for i in 0..<(path.count - 1) {
            let pathStart = path[i]
            let pathEnd = path[i + 1]

            for territory in otherTerritories {
                let polygon = territory.toCoordinates()
                guard polygon.count >= 3 else { continue }

                // 检查与领地每条边的相交
                for j in 0..<polygon.count {
                    let boundaryStart = polygon[j]
                    let boundaryEnd = polygon[(j + 1) % polygon.count]

                    if segmentsIntersect(p1: pathStart, p2: pathEnd, p3: boundaryStart, p4: boundaryEnd) {
                        TerritoryLogger.shared.log("路径碰撞：穿越「\(territory.displayName)」边界", type: .error)
                        return CollisionResult.violation(
                            type: .pathCrossTerritory,
                            message: "轨迹不能穿越他人领地！",
                            territoryName: territory.displayName
                        )
                    }
                }

                // 检查路径终点是否在领地内
                if isPointInPolygon(point: pathEnd, polygon: polygon) {
                    TerritoryLogger.shared.log("路径碰撞：进入「\(territory.displayName)」内部", type: .error)
                    return CollisionResult.violation(
                        type: .pointInTerritory,
                        message: "轨迹不能进入他人领地！",
                        territoryName: territory.displayName
                    )
                }
            }
        }

        return .safe
    }

    /// 计算当前位置到他人领地的最近距离
    /// - Parameters:
    ///   - location: 当前位置
    ///   - currentUserId: 当前用户 ID
    /// - Returns: 最近距离（米），如果没有他人领地返回 Double.infinity
    func calculateMinDistanceToTerritories(location: CLLocationCoordinate2D, currentUserId: String) -> Double {
        // 过滤出他人的领地
        let otherTerritories = allTerritories.filter { territory in
            territory.userId.lowercased() != currentUserId.lowercased()
        }

        guard !otherTerritories.isEmpty else { return Double.infinity }

        var minDistance = Double.infinity
        let currentLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)

        for territory in otherTerritories {
            let polygon = territory.toCoordinates()

            // 计算到每个顶点的距离
            for vertex in polygon {
                let vertexLocation = CLLocation(latitude: vertex.latitude, longitude: vertex.longitude)
                let distance = currentLocation.distance(from: vertexLocation)
                minDistance = min(minDistance, distance)
            }

            // 计算到每条边的距离（更精确）
            for j in 0..<polygon.count {
                let edgeStart = polygon[j]
                let edgeEnd = polygon[(j + 1) % polygon.count]
                let edgeDistance = distanceToLineSegment(point: location, lineStart: edgeStart, lineEnd: edgeEnd)
                minDistance = min(minDistance, edgeDistance)
            }
        }

        return minDistance
    }

    /// 计算点到线段的最近距离
    /// - Parameters:
    ///   - point: 点坐标
    ///   - lineStart: 线段起点
    ///   - lineEnd: 线段终点
    /// - Returns: 距离（米）
    private func distanceToLineSegment(
        point: CLLocationCoordinate2D,
        lineStart: CLLocationCoordinate2D,
        lineEnd: CLLocationCoordinate2D
    ) -> Double {
        let pointLoc = CLLocation(latitude: point.latitude, longitude: point.longitude)
        let startLoc = CLLocation(latitude: lineStart.latitude, longitude: lineStart.longitude)
        let endLoc = CLLocation(latitude: lineEnd.latitude, longitude: lineEnd.longitude)

        let lineLength = startLoc.distance(from: endLoc)

        // 如果线段长度为 0，直接返回点到起点的距离
        if lineLength == 0 {
            return pointLoc.distance(from: startLoc)
        }

        // 计算投影比例 t
        let dx = lineEnd.longitude - lineStart.longitude
        let dy = lineEnd.latitude - lineStart.latitude
        let t = max(0, min(1, (
            (point.longitude - lineStart.longitude) * dx +
            (point.latitude - lineStart.latitude) * dy
        ) / (dx * dx + dy * dy)))

        // 计算投影点
        let projLon = lineStart.longitude + t * dx
        let projLat = lineStart.latitude + t * dy
        let projLoc = CLLocation(latitude: projLat, longitude: projLon)

        return pointLoc.distance(from: projLoc)
    }

    /// 综合碰撞检测（主方法）
    /// - Parameters:
    ///   - path: 当前路径坐标数组
    ///   - currentUserId: 当前用户 ID
    /// - Returns: 碰撞检测结果
    func checkPathCollisionComprehensive(path: [CLLocationCoordinate2D], currentUserId: String) -> CollisionResult {
        guard path.count >= 1 else { return .safe }

        // 1. 如果只有一个点，检查起点碰撞
        if path.count == 1 {
            return checkPointCollision(location: path[0], currentUserId: currentUserId)
        }

        // 2. 检查路径是否穿越他人领地
        let crossResult = checkPathCrossTerritory(path: path, currentUserId: currentUserId)
        if crossResult.hasCollision {
            return crossResult
        }

        // 3. 计算到最近领地的距离
        guard let lastPoint = path.last else { return .safe }
        let minDistance = calculateMinDistanceToTerritories(location: lastPoint, currentUserId: currentUserId)

        // 4. 根据距离确定预警级别和消息
        let warningLevel: WarningLevel
        let message: String?

        if minDistance > 100 {
            warningLevel = .safe
            message = nil
        } else if minDistance > 50 {
            warningLevel = .caution
            message = "注意：距离他人领地 \(Int(minDistance))m"
        } else if minDistance > 25 {
            warningLevel = .warning
            message = "警告：正在靠近他人领地（\(Int(minDistance))m）"
        } else {
            warningLevel = .danger
            message = "危险：即将进入他人领地！（\(Int(minDistance))m）"
        }

        // 记录预警日志
        if warningLevel != .safe {
            TerritoryLogger.shared.log("距离预警：\(warningLevel.description)，距离 \(Int(minDistance))m", type: .warning)
        }

        return CollisionResult(
            hasCollision: false,
            collisionType: nil,
            message: message,
            closestDistance: minDistance,
            warningLevel: warningLevel,
            territoryName: nil
        )
    }

    // MARK: - Helper Methods

    /// 生成默认领地名称
    /// - Returns: 默认名称（格式：领地 #N）
    func generateDefaultName() -> String {
        let count = territories.count + 1
        return "领地 #\(count)"
    }

    /// 计算所有领地的总面积
    var totalArea: Double {
        territories.reduce(0) { $0 + $1.area }
    }

    /// 格式化面积显示
    /// - Parameter area: 面积（平方米）
    /// - Returns: 格式化后的字符串
    static func formatArea(_ area: Double) -> String {
        if area >= 10000 {
            // 超过 1 公顷，显示公顷
            return String(format: "%.2f 公顷", area / 10000)
        } else if area >= 1000 {
            // 超过 1000 平方米，显示千位
            return String(format: "%.1f 千m²", area / 1000)
        } else {
            return String(format: "%.0f m²", area)
        }
    }
}

// MARK: - AnyEncodable Helper

/// 用于包装任意 Encodable 类型
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
