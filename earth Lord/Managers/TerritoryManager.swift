//
//  TerritoryManager.swift
//  earth Lord
//
//  领地管理器 - Day17
//  负责领地的 CRUD 操作（与 Supabase 交互）
//

import Foundation
import CoreLocation
import Combine
import Supabase

// MARK: - 领地管理器

@MainActor
class TerritoryManager: ObservableObject {

    // MARK: - Singleton

    static let shared = TerritoryManager()

    // MARK: - Published Properties

    /// 当前用户的领地列表
    @Published var territories: [Territory] = []

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

    // MARK: - CRUD Operations

    /// 保存新领地到 Supabase
    /// - Parameters:
    ///   - name: 领地名称
    ///   - path: GPS路径点数组
    ///   - area: 领地面积（平方米）
    /// - Returns: 保存成功的领地对象，失败返回 nil
    func saveTerritory(name: String, path: [CLLocationCoordinate2D], area: Double) async -> Territory? {
        print("💾 开始保存领地: \(name)")

        // 检查用户是否已登录
        guard let userId = AuthManager.shared.currentUser?.id,
              let userUUID = UUID(uuidString: userId) else {
            errorMessage = "请先登录后再圈地"
            print("❌ 保存失败：用户未登录")
            return nil
        }

        isLoading = true
        errorMessage = nil

        do {
            // 创建请求数据
            let request = CreateTerritoryRequest(
                userId: userUUID,
                name: name,
                path: path.asPathPoints,
                area: area
            )

            print("📤 发送保存请求到 Supabase...")

            // 插入数据并返回新记录
            let response: Territory = try await supabase
                .from("territories")
                .insert(request)
                .select()
                .single()
                .execute()
                .value

            print("✅ 领地保存成功！ID: \(response.id)")

            // 更新本地列表
            territories.insert(response, at: 0)
            lastSavedTerritory = response

            // 记录日志
            TerritoryLogger.shared.log("领地保存成功: \(name), 面积: \(Int(area))m²", type: .success)

            isLoading = false
            return response

        } catch {
            let errorMsg = "保存领地失败: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ \(errorMsg)")

            // 记录日志
            TerritoryLogger.shared.log(errorMsg, type: .error)

            isLoading = false
            return nil
        }
    }

    /// 获取当前用户的所有领地
    func fetchMyTerritories() async {
        print("📥 获取我的领地列表...")

        // 检查用户是否已登录
        guard let userId = AuthManager.shared.currentUser?.id,
              let userUUID = UUID(uuidString: userId) else {
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
                .eq("user_id", value: userUUID.uuidString)
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

    /// 删除领地
    /// - Parameter territory: 要删除的领地
    /// - Returns: 是否删除成功
    func deleteTerritory(_ territory: Territory) async -> Bool {
        print("🗑️ 删除领地: \(territory.name)")

        isLoading = true
        errorMessage = nil

        do {
            try await supabase
                .from("territories")
                .delete()
                .eq("id", value: territory.id.uuidString)
                .execute()

            print("✅ 领地删除成功")

            // 从本地列表移除
            territories.removeAll { $0.id == territory.id }

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
        print("✏️ 更新领地名称: \(territory.name) -> \(newName)")

        isLoading = true
        errorMessage = nil

        do {
            try await supabase
                .from("territories")
                .update(["name": newName])
                .eq("id", value: territory.id.uuidString)
                .execute()

            print("✅ 领地名称更新成功")

            // 更新本地列表
            if let index = territories.firstIndex(where: { $0.id == territory.id }) {
                var updated = territories[index]
                updated.name = newName
                territories[index] = updated
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
