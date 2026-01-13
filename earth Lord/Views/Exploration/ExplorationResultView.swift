//
//  ExplorationResultView.swift
//  earth Lord
//
//  探索结果弹窗页面
//

import SwiftUI

// MARK: - 探索错误类型

/// 探索失败时的错误信息
struct ExplorationError {
    let title: String
    let message: String
    let icon: String

    /// 预设错误类型
    static let networkError = ExplorationError(
        title: "网络连接失败",
        message: "无法连接到服务器，请检查网络后重试",
        icon: "wifi.slash"
    )

    static let locationError = ExplorationError(
        title: "定位失败",
        message: "无法获取当前位置，请确保已开启定位权限",
        icon: "location.slash"
    )

    static let timeoutError = ExplorationError(
        title: "探索超时",
        message: "探索时间过长，请稍后重试",
        icon: "clock.badge.exclamationmark"
    )

    static let unknownError = ExplorationError(
        title: "探索失败",
        message: "发生未知错误，请稍后重试",
        icon: "exclamationmark.triangle"
    )
}

// MARK: - 探索结果视图

struct ExplorationResultView: View {

    // MARK: - Properties

    /// 探索结果数据（成功时有值）
    let result: ExplorationResult?

    /// 累计统计数据（成功时有值）
    let stats: ExplorationStats?

    /// 错误信息（失败时有值）
    let error: ExplorationError?

    /// 重试回调
    var onRetry: (() -> Void)?

    /// 环境变量：关闭页面
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    /// 动画状态：是否显示内容
    @State private var showContent = false

    /// 动画状态：是否显示物品
    @State private var showItems = false

    /// 数字动画进度 (0-1)
    @State private var numberAnimationProgress: Double = 0

    /// 对勾动画状态（按索引）
    @State private var checkmarkAppeared: Set<Int> = []

    /// 错误图标抖动状态
    @State private var errorIconShake = false

    // MARK: - Computed Properties

    /// 是否为错误状态
    private var isError: Bool {
        error != nil
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            ApocalypseTheme.background
                .ignoresSafeArea()

            if isError {
                // 错误状态
                errorStateView
            } else {
                // 成功状态
                successStateView
            }
        }
        .onAppear {
            if isError {
                startErrorAnimations()
            } else {
                startAnimations()
            }
        }
    }

    // MARK: - 成功状态视图

    private var successStateView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 成就标题
                achievementHeader
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)

                // 统计数据卡片
                statsCard
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // 奖励物品卡片
                rewardsCard
                    .opacity(showItems ? 1 : 0)
                    .offset(y: showItems ? 0 : 20)

                // 确认按钮
                confirmButton
                    .opacity(showItems ? 1 : 0)
                    .offset(y: showItems ? 0 : 20)
            }
            .padding(20)
            .padding(.top, 20)
        }
    }

    // MARK: - 错误状态视图

    private var errorStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            // 错误图标
            ZStack {
                // 外圈
                Circle()
                    .fill(ApocalypseTheme.danger.opacity(0.1))
                    .frame(width: 140, height: 140)

                // 内圈
                Circle()
                    .fill(ApocalypseTheme.danger.opacity(0.2))
                    .frame(width: 100, height: 100)

                // 图标
                Image(systemName: error?.icon ?? "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(ApocalypseTheme.danger)
                    .rotationEffect(.degrees(errorIconShake ? -5 : 5))
                    .animation(
                        .easeInOut(duration: 0.1).repeatCount(5, autoreverses: true),
                        value: errorIconShake
                    )
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.5)

            // 错误标题
            Text(error?.title ?? "探索失败")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .opacity(showContent ? 1 : 0)

            // 错误信息
            Text(error?.message ?? "发生未知错误")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(showContent ? 1 : 0)

            Spacer()

            // 按钮区域
            VStack(spacing: 12) {
                // 重试按钮
                Button(action: {
                    onRetry?()
                    dismiss()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)

                        Text("重试")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                ApocalypseTheme.primary,
                                ApocalypseTheme.primaryDark
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .opacity(showItems ? 1 : 0)
                .offset(y: showItems ? 0 : 20)

                // 关闭按钮
                Button(action: {
                    dismiss()
                }) {
                    Text("关闭")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
                .opacity(showItems ? 1 : 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - 错误动画控制

    private func startErrorAnimations() {
        // 显示内容
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            showContent = true
        }

        // 图标抖动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            errorIconShake = true
        }

        // 显示按钮
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            showItems = true
        }
    }

    // MARK: - 动画控制

    private func startAnimations() {
        // 第一阶段：显示标题和统计卡片
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            showContent = true
        }

        // 第二阶段：数字跳动动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 1.2)) {
                numberAnimationProgress = 1.0
            }
        }

        // 第三阶段：显示物品卡片
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            showItems = true
        }

        // 第四阶段：依次显示对勾
        let itemCount = result?.itemsFound.count ?? 0
        for i in 0..<itemCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(i) * 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    _ = checkmarkAppeared.insert(i)
                }
            }
        }
    }

    // MARK: - 成就标题

    private var achievementHeader: some View {
        VStack(spacing: 16) {
            // 装饰背景圆环
            ZStack {
                // 外圈光晕（脉冲动画）
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                ApocalypseTheme.primary.opacity(0.3),
                                ApocalypseTheme.primary.opacity(0)
                            ]),
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(showContent ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: showContent
                    )

                // 内圈
                Circle()
                    .fill(ApocalypseTheme.primary.opacity(0.2))
                    .frame(width: 100, height: 100)

                // 图标
                Image(systemName: "map.fill")
                    .font(.system(size: 50))
                    .foregroundColor(ApocalypseTheme.primary)
            }

            // 标题文字
            Text("探索完成！")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 副标题
            Text("你又征服了一片新领域")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .padding(.vertical, 10)
    }

    // MARK: - 统计数据卡片

    private var statsCard: some View {
        VStack(spacing: 16) {
            // 卡片标题
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(ApocalypseTheme.info)

                Text("探索数据")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()
            }

            // 分隔线
            Divider()
                .background(ApocalypseTheme.textMuted)

            // 行走距离
            animatedStatRow(
                icon: "figure.walk",
                iconColor: ApocalypseTheme.success,
                title: "行走距离",
                targetValue: result?.walkDistance ?? 0,
                formatter: { formatDistance($0) },
                total: formatDistance(stats?.totalWalkDistance ?? 0),
                rank: stats?.walkDistanceRank ?? 0
            )

            // 探索时长
            HStack {
                // 图标
                ZStack {
                    Circle()
                        .fill(ApocalypseTheme.warning.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ApocalypseTheme.warning)
                }

                // 标题
                Text("探索时长")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                Spacer()

                // 时长值（动画）
                Text("\(Int(Double(result?.durationMinutes ?? 0) * numberAnimationProgress)) 分钟")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .contentTransition(.numericText())
            }
        }
        .padding(16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    /// 带动画的统计数据行
    private func animatedStatRow(
        icon: String,
        iconColor: Color,
        title: String,
        targetValue: Double,
        formatter: (Double) -> String,
        total: String,
        rank: Int
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            // 标题和数据
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                HStack(spacing: 16) {
                    // 本次（带数字动画）
                    VStack(alignment: .leading, spacing: 2) {
                        Text("本次")
                            .font(.caption2)
                            .foregroundColor(ApocalypseTheme.textMuted)

                        Text(formatter(targetValue * numberAnimationProgress))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                            .contentTransition(.numericText())
                    }

                    // 累计
                    VStack(alignment: .leading, spacing: 2) {
                        Text("累计")
                            .font(.caption2)
                            .foregroundColor(ApocalypseTheme.textMuted)

                        Text(total)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }
            }

            Spacer()

            // 排名（带动画）
            VStack(spacing: 2) {
                Text("排名")
                    .font(.caption2)
                    .foregroundColor(ApocalypseTheme.textMuted)

                Text("#\(max(1, Int(Double(rank) * numberAnimationProgress) + (numberAnimationProgress < 1 ? Int.random(in: 1...100) : 0)))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(rankColor(rank))
                    .contentTransition(.numericText())
            }
        }
    }

    /// 排名颜色
    private func rankColor(_ rank: Int) -> Color {
        if rank <= 10 {
            return Color.yellow  // 金色
        } else if rank <= 50 {
            return ApocalypseTheme.success  // 绿色
        } else if rank <= 100 {
            return ApocalypseTheme.info  // 蓝色
        } else {
            return ApocalypseTheme.textSecondary
        }
    }

    // MARK: - 奖励物品卡片

    private var rewardsCard: some View {
        VStack(spacing: 16) {
            // 卡片标题
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(ApocalypseTheme.primary)

                Text("获得物品")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                // 物品数量
                Text("\(result?.itemsFound.count ?? 0) 种")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            // 分隔线
            Divider()
                .background(ApocalypseTheme.textMuted)

            // 物品列表
            if let itemsFound = result?.itemsFound {
                ForEach(itemsFound.indices, id: \.self) { index in
                    let found = itemsFound[index]
                    if let definition = InventoryManager.shared.getItemDefinition(by: found.itemId) {
                        rewardItemRow(definition: definition, quantity: found.quantity, quality: found.quality, index: index)
                    }
                }
            }

            // 底部提示
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.success)

                Text("已添加到背包")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.success)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
        .padding(16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    /// 奖励物品行
    private func rewardItemRow(definition: ItemDefinition, quantity: Int, quality: ItemQuality?, index: Int) -> some View {
        HStack(spacing: 12) {
            // 物品图标
            ZStack {
                Circle()
                    .fill(definition.category.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: definition.category.iconName)
                    .font(.title3)
                    .foregroundColor(definition.category.color)
            }

            // 物品名称
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(definition.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    // 品质标签（如果有）
                    if let quality = quality {
                        Text(quality.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(quality.color.opacity(0.2))
                            .foregroundColor(quality.color)
                            .cornerRadius(4)
                    }
                }

                // 稀有度
                Text(definition.rarity.displayName)
                    .font(.caption2)
                    .foregroundColor(definition.rarity.color)
            }

            Spacer()

            // 数量
            Text("+\(quantity)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.success)

            // 对勾（带弹跳动画）
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(ApocalypseTheme.success)
                .scaleEffect(checkmarkAppeared.contains(index) ? 1.0 : 0.0)
                .opacity(checkmarkAppeared.contains(index) ? 1.0 : 0.0)
        }
        .padding(.vertical, 6)
        .opacity(showItems ? 1 : 0)
        .offset(x: showItems ? 0 : -20)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8)
                .delay(0.1 + Double(index) * 0.15),
            value: showItems
        )
    }

    // MARK: - 确认按钮

    private var confirmButton: some View {
        Button(action: {
            dismiss()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.headline)

                Text("太棒了！")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        ApocalypseTheme.primary,
                        ApocalypseTheme.primaryDark
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
    }

    // MARK: - Helpers

    /// 格式化距离
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }
}

// MARK: - 便捷初始化

extension ExplorationResultView {
    /// 成功状态初始化
    init(result: ExplorationResult, stats: ExplorationStats) {
        self.result = result
        self.stats = stats
        self.error = nil
        self.onRetry = nil
    }

    /// 错误状态初始化
    init(error: ExplorationError, onRetry: (() -> Void)? = nil) {
        self.result = nil
        self.stats = nil
        self.error = error
        self.onRetry = onRetry
    }

    /// 使用假数据初始化（用于测试成功状态）
    init() {
        self.result = MockExplorationData.mockExplorationResult
        self.stats = MockExplorationData.mockExplorationStats
        self.error = nil
        self.onRetry = nil
    }
}

// MARK: - Preview

#Preview("成功状态") {
    ExplorationResultView()
}

#Preview("成功状态 - 自定义数据") {
    ExplorationResultView(
        result: MockExplorationData.mockExplorationResult,
        stats: MockExplorationData.mockExplorationStats
    )
}

#Preview("错误状态 - 网络错误") {
    ExplorationResultView(
        error: .networkError,
        onRetry: { print("重试") }
    )
}

#Preview("错误状态 - 定位错误") {
    ExplorationResultView(
        error: .locationError,
        onRetry: { print("重试") }
    )
}

#Preview("错误状态 - 超时") {
    ExplorationResultView(
        error: .timeoutError,
        onRetry: { print("重试") }
    )
}
