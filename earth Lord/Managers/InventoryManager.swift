//
//  InventoryManager.swift
//  earth Lord
//
//  背包管理器 - 管理背包数据，与 Supabase 同步
//

import Foundation
import Supabase
import Combine

// MARK: - 数据库模型

/// 物品定义（数据库模型）
struct DBItemDefinition: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let weight: Double
    let volume: Double
    let rarity: String
    let description: String?
    let stackable: Bool
    let maxStack: Int
    let hasQuality: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, category, weight, volume, rarity, description, stackable
        case maxStack = "max_stack"
        case hasQuality = "has_quality"
    }

    /// 转换为 UI 模型
    func toItemDefinition() -> ItemDefinition {
        return ItemDefinition(
            id: id,
            name: name,
            category: ItemCategory(rawValue: category) ?? .misc,
            weight: weight,
            volume: volume,
            rarity: ItemRarity(rawValue: rarity) ?? .common,
            description: description ?? "",
            stackable: stackable,
            maxStack: maxStack,
            hasQuality: hasQuality
        )
    }
}

/// 背包物品（数据库模型）
struct DBInventoryItem: Codable, Identifiable {
    let id: String
    let userId: String
    let itemId: String
    var quantity: Int
    let quality: String?
    let obtainedAt: Date?
    let source: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case itemId = "item_id"
        case quantity, quality
        case obtainedAt = "obtained_at"
        case source
    }

    /// 转换为 UI 模型
    func toInventoryItem() -> InventoryItem {
        return InventoryItem(
            id: id,
            itemId: itemId,
            quantity: quantity,
            quality: quality != nil ? ItemQuality(rawValue: quality!) : nil,
            acquiredAt: obtainedAt ?? Date()
        )
    }
}

/// 插入背包物品的请求模型
struct InsertInventoryItem: Codable {
    let userId: String
    let itemId: String
    let quantity: Int
    let quality: String?
    let source: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case itemId = "item_id"
        case quantity, quality, source
    }
}

// MARK: - 背包管理器

@MainActor
class InventoryManager: ObservableObject {

    // MARK: - Singleton

    static let shared = InventoryManager()

    // MARK: - Published Properties

    /// 物品定义缓存
    @Published var itemDefinitions: [String: ItemDefinition] = [:]

    /// 背包物品列表
    @Published var inventoryItems: [InventoryItem] = []

    /// 是否正在加载
    @Published var isLoading: Bool = false

    /// 错误信息
    @Published var errorMessage: String?

    /// 背包最大容量（kg）
    let maxCapacity: Double = 100.0

    // MARK: - Computed Properties

    /// 当前背包重量
    var currentWeight: Double {
        return inventoryItems.reduce(0) { total, item in
            guard let definition = itemDefinitions[item.itemId] else { return total }
            return total + definition.weight * Double(item.quantity)
        }
    }

    /// 容量百分比
    var capacityPercentage: Double {
        return currentWeight / maxCapacity
    }

    // MARK: - Initialization

    private init() {
        print("📦 InventoryManager 初始化")
    }

    // MARK: - 加载物品定义

    /// 从数据库加载所有物品定义
    func loadItemDefinitions() async {
        print("📦 加载物品定义...")

        do {
            let response: [DBItemDefinition] = try await supabase
                .from("item_definitions")
                .select()
                .execute()
                .value

            // 转换为字典缓存
            var definitions: [String: ItemDefinition] = [:]
            for dbItem in response {
                definitions[dbItem.id] = dbItem.toItemDefinition()
            }

            self.itemDefinitions = definitions
            print("✅ 加载了 \(definitions.count) 个物品定义")

        } catch {
            print("❌ 加载物品定义失败: \(error)")
            errorMessage = "加载物品定义失败: \(error.localizedDescription)"

            // 如果数据库加载失败，使用本地假数据作为备份
            loadLocalItemDefinitions()
        }
    }

    /// 使用本地假数据作为备份
    private func loadLocalItemDefinitions() {
        print("📦 使用本地物品定义作为备份...")
        var definitions: [String: ItemDefinition] = [:]
        for item in MockExplorationData.itemDefinitions {
            definitions[item.id] = item
        }
        self.itemDefinitions = definitions
        print("✅ 加载了 \(definitions.count) 个本地物品定义")
    }

    // MARK: - 加载背包

    /// 从数据库加载用户背包
    func loadInventory() async {
        guard let userId = AuthManager.shared.currentUser?.id else {
            print("⚠️ 用户未登录，无法加载背包")
            return
        }

        isLoading = true
        errorMessage = nil
        print("📦 加载用户背包...")

        do {
            let response: [DBInventoryItem] = try await supabase
                .from("inventory_items")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            // 转换为 UI 模型
            self.inventoryItems = response.map { $0.toInventoryItem() }
            print("✅ 加载了 \(inventoryItems.count) 个背包物品")

        } catch {
            print("❌ 加载背包失败: \(error)")
            errorMessage = "加载背包失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 添加物品

    /// 添加物品到背包
    /// - Parameters:
    ///   - itemId: 物品定义ID
    ///   - quantity: 数量
    ///   - quality: 品质（可选）
    ///   - source: 来源（exploration/trade/purchase/reward）
    func addItem(itemId: String, quantity: Int, quality: ItemQuality? = nil, source: String = "exploration") async -> Bool {
        guard let userId = AuthManager.shared.currentUser?.id else {
            print("⚠️ 用户未登录，无法添加物品")
            return false
        }

        print("📦 添加物品: \(itemId) x\(quantity)")

        do {
            // 检查是否已有该物品（同用户、同物品、同品质）
            let existingItems: [DBInventoryItem] = try await supabase
                .from("inventory_items")
                .select()
                .eq("user_id", value: userId)
                .eq("item_id", value: itemId)
                .execute()
                .value

            // 筛选品质匹配的物品
            let qualityStr = quality?.rawValue
            let matchingItem = existingItems.first { item in
                if qualityStr == nil && item.quality == nil {
                    return true
                }
                return item.quality == qualityStr
            }

            if let existing = matchingItem {
                // 更新数量
                let newQuantity = existing.quantity + quantity
                try await supabase
                    .from("inventory_items")
                    .update(["quantity": newQuantity])
                    .eq("id", value: existing.id)
                    .execute()

                print("✅ 更新物品数量: \(existing.quantity) -> \(newQuantity)")
            } else {
                // 插入新物品
                let newItem = InsertInventoryItem(
                    userId: userId,
                    itemId: itemId,
                    quantity: quantity,
                    quality: quality?.rawValue,
                    source: source
                )

                try await supabase
                    .from("inventory_items")
                    .insert(newItem)
                    .execute()

                print("✅ 插入新物品")
            }

            // 重新加载背包
            await loadInventory()
            return true

        } catch {
            print("❌ 添加物品失败: \(error)")
            errorMessage = "添加物品失败: \(error.localizedDescription)"
            return false
        }
    }

    /// 批量添加物品（用于探索奖励）
    func addItems(_ items: [FoundItem], source: String = "exploration") async -> Bool {
        var allSuccess = true

        for item in items {
            let success = await addItem(
                itemId: item.itemId,
                quantity: item.quantity,
                quality: item.quality,
                source: source
            )
            if !success {
                allSuccess = false
            }
        }

        return allSuccess
    }

    // MARK: - 移除物品

    /// 从背包移除物品
    /// - Parameters:
    ///   - inventoryItemId: 背包物品实例ID
    ///   - quantity: 移除数量（nil 表示全部移除）
    func removeItem(inventoryItemId: String, quantity: Int? = nil) async -> Bool {
        print("📦 移除物品: \(inventoryItemId), 数量: \(quantity ?? -1)")

        do {
            // 获取当前物品信息
            let items: [DBInventoryItem] = try await supabase
                .from("inventory_items")
                .select()
                .eq("id", value: inventoryItemId)
                .execute()
                .value

            guard let item = items.first else {
                print("⚠️ 物品不存在")
                return false
            }

            let removeQuantity = quantity ?? item.quantity

            if removeQuantity >= item.quantity {
                // 删除整条记录
                try await supabase
                    .from("inventory_items")
                    .delete()
                    .eq("id", value: inventoryItemId)
                    .execute()

                print("✅ 删除物品记录")
            } else {
                // 减少数量
                let newQuantity = item.quantity - removeQuantity
                try await supabase
                    .from("inventory_items")
                    .update(["quantity": newQuantity])
                    .eq("id", value: inventoryItemId)
                    .execute()

                print("✅ 更新物品数量: \(item.quantity) -> \(newQuantity)")
            }

            // 重新加载背包
            await loadInventory()
            return true

        } catch {
            print("❌ 移除物品失败: \(error)")
            errorMessage = "移除物品失败: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 辅助方法

    /// 获取物品定义
    func getItemDefinition(by id: String) -> ItemDefinition? {
        // 优先从数据库缓存获取
        if let definition = itemDefinitions[id] {
            return definition
        }
        // 备用：从本地假数据获取
        return MockExplorationData.getItemDefinition(by: id)
    }

    /// 计算背包总重量
    func calculateTotalWeight() -> Double {
        return inventoryItems.reduce(0) { total, item in
            guard let definition = getItemDefinition(by: item.itemId) else { return total }
            return total + definition.weight * Double(item.quantity)
        }
    }

    /// 初始化（加载物品定义和背包）
    func initialize() async {
        await loadItemDefinitions()
        await loadInventory()
    }
}
