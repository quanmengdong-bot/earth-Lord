//
//  ScavengeResultView.swift
//  earth Lord
//
//  搜刮结果视图 - 显示搜刮获得的物品
//

import SwiftUI

struct ScavengeResultView: View {

    // MARK: - Properties

    let poiName: String
    let items: [FoundItem]
    let onDismiss: () -> Void

    /// 物品定义（用于显示详细信息）
    @ObservedObject private var inventoryManager = InventoryManager.shared

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 顶部成功标题
            VStack(spacing: 12) {
                // 成功图标
                ZStack {
                    Circle()
                        .fill(ApocalypseTheme.success.opacity(0.2))
                        .frame(width: 70, height: 70)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(ApocalypseTheme.success)
                }

                Text("搜刮成功!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text(poiName)
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .padding(.top, 24)

            // 获得物品标题
            HStack {
                Image(systemName: "cube.box.fill")
                    .foregroundColor(ApocalypseTheme.primary)

                Text("获得物品")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                Text("\(items.count) 件")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            // 物品列表
            VStack(spacing: 8) {
                ForEach(items, id: \.itemId) { item in
                    itemRow(item: item)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // 确认按钮
            Button(action: onDismiss) {
                Text("确认")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [ApocalypseTheme.success, ApocalypseTheme.success.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }

    // MARK: - 物品行

    private func itemRow(item: FoundItem) -> some View {
        let definition = inventoryManager.itemDefinitions[item.itemId]
        let itemName = definition?.name ?? item.itemId
        let itemRarity = definition?.rarity ?? .common

        return HStack(spacing: 12) {
            // 物品图标
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(itemRarity.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: itemIcon(for: item))
                    .font(.system(size: 20))
                    .foregroundColor(itemRarity.color)
            }

            // 物品名称和稀有度
            VStack(alignment: .leading, spacing: 4) {
                Text(itemName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text(itemRarity.displayName)
                    .font(.caption)
                    .foregroundColor(itemRarity.color)
            }

            Spacer()

            // 数量
            Text("x\(item.quantity)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.textPrimary)
        }
        .padding(12)
        .background(ApocalypseTheme.background)
        .cornerRadius(12)
    }

    // MARK: - 辅助方法

    /// 获取物品图标
    private func itemIcon(for item: FoundItem) -> String {
        // 尝试从物品定义获取，否则使用默认图标
        if let definition = inventoryManager.itemDefinitions[item.itemId] {
            return definition.category.iconName
        }
        return "shippingbox.fill"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ApocalypseTheme.background
            .ignoresSafeArea()

        ScavengeResultView(
            poiName: "沃尔玛超市",
            items: [
                FoundItem(itemId: "item_water_bottle", quantity: 2, quality: nil),
                FoundItem(itemId: "item_canned_food", quantity: 1, quality: nil),
                FoundItem(itemId: "item_bandage", quantity: 1, quality: nil)
            ],
            onDismiss: { print("关闭") }
        )
    }
}
