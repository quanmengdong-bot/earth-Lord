//
//  ExplorationManager.swift
//  earth Lord
//
//  探索管理器 - 管理探索状态、GPS追踪、距离计算、速度检测
//

import Foundation
import CoreLocation
import Combine
import Supabase

// MARK: - 探索状态枚举

/// 探索状态
enum ExplorationState: Equatable {
    case idle           // 空闲
    case exploring      // 探索中
    case speedWarning   // 速度警告中
    case calculating    // 计算奖励中
    case completed      // 已完成
    case failed         // 探索失败（超速等原因）
    case error          // 出错
}

// MARK: - 探索失败原因

enum ExplorationFailReason {
    case speedViolation     // 超速违规
    case cancelled          // 用户取消
    case unknown            // 未知原因

    var message: String {
        switch self {
        case .speedViolation:
            return "检测到速度异常，探索已终止"
        case .cancelled:
            return "探索已取消"
        case .unknown:
            return "探索失败"
        }
    }
}

// MARK: - 探索会话数据库模型

/// 探索会话（数据库模型）
struct DBExplorationSession: Codable {
    let id: String?
    let userId: String
    let startTime: Date
    var endTime: Date?
    var durationSeconds: Int?
    var startLat: Double?
    var startLng: Double?
    var endLat: Double?
    var endLng: Double?
    var totalDistance: Double?
    var exploredArea: Double?
    var rewardTier: String?
    var itemsRewarded: String?
    var status: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case durationSeconds = "duration_seconds"
        case startLat = "start_lat"
        case startLng = "start_lng"
        case endLat = "end_lat"
        case endLng = "end_lng"
        case totalDistance = "total_distance"
        case exploredArea = "explored_area"
        case rewardTier = "reward_tier"
        case itemsRewarded = "items_rewarded"
        case status
    }
}

/// 插入探索会话的请求
struct InsertExplorationSession: Codable {
    let userId: String
    let startTime: Date
    let startLat: Double?
    let startLng: Double?
    let status: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case startTime = "start_time"
        case startLat = "start_lat"
        case startLng = "start_lng"
        case status
    }
}

/// 更新探索会话的请求
struct UpdateExplorationSession: Codable {
    let endTime: Date
    let durationSeconds: Int
    let endLat: Double?
    let endLng: Double?
    let totalDistance: Double
    let rewardTier: String
    let itemsRewarded: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case endTime = "end_time"
        case durationSeconds = "duration_seconds"
        case endLat = "end_lat"
        case endLng = "end_lng"
        case totalDistance = "total_distance"
        case rewardTier = "reward_tier"
        case itemsRewarded = "items_rewarded"
        case status
    }
}

/// 探索历史记录项（用于UI展示）
struct ExplorationHistoryItem: Identifiable {
    let id: String
    let date: Date
    let distance: Double
    let duration: Int
    let rewardTier: RewardTier
    let itemCount: Int

    /// 格式化日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }

    /// 格式化距离
    var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        }
        return String(format: "%.0f m", distance)
    }

    /// 格式化时长
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 探索管理器

@MainActor
class ExplorationManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ExplorationManager()

    // MARK: - Published Properties

    /// 探索状态
    @Published var state: ExplorationState = .idle

    /// 是否正在探索
    @Published var isExploring: Bool = false

    /// 当前累计距离（米）
    @Published var currentDistance: Double = 0

    /// 当前探索时长（秒）
    @Published var currentDuration: Int = 0

    /// 探索开始时间
    @Published var startTime: Date?

    /// 探索结果
    @Published var explorationResult: ExplorationResult?

    /// 累计统计
    @Published var explorationStats: ExplorationStats?

    /// 探索历史记录
    @Published var explorationHistory: [ExplorationHistoryItem] = []

    /// 错误信息
    @Published var errorMessage: String?

    /// 奖励等级（实时预览）
    @Published var previewTier: RewardTier = .none

    /// 当前速度（km/h）
    @Published var currentSpeed: Double = 0

    /// 是否处于超速状态
    @Published var isOverSpeed: Bool = false

    /// 超速倒计时（秒）
    @Published var speedWarningCountdown: Int = 0

    /// 探索失败原因
    @Published var failReason: ExplorationFailReason?

    // MARK: - Private Properties

    /// 当前探索会话ID
    private var currentSessionId: String?

    /// 起点坐标
    private var startCoordinate: CLLocationCoordinate2D?

    /// 上一个位置
    private var lastLocation: CLLocation?

    /// 上一次位置更新时间
    private var lastLocationTime: Date?

    /// 计时器
    private var durationTimer: Timer?

    /// 超速警告计时器
    private var speedWarningTimer: Timer?

    /// 位置更新取消器
    private var locationCancellable: AnyCancellable?

    // MARK: - Constants

    /// 位置更新最小距离阈值（米）
    private let minimumDistanceThreshold: Double = 3.0

    /// 位置精度阈值（米）
    private let accuracyThreshold: Double = 50.0

    /// 最大位置跳变阈值（米）- 防止GPS跳点
    private let maxJumpThreshold: Double = 80.0

    /// 最大允许速度（km/h）
    private let maxAllowedSpeed: Double = 30.0

    /// 超速警告持续时间（秒）- 超过这个时间停止探索
    private let speedWarningDuration: Int = 10

    // MARK: - Initialization

    private init() {
        log("📱 ExplorationManager 初始化")
        setupLocationObserver()
    }

    // MARK: - 日志方法

    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(timestamp)] [Exploration] \(message)")
    }

    // MARK: - 设置位置监听

    private func setupLocationObserver() {
        log("🔧 设置位置监听器")
        // 监听完整的CLLocation对象（包含速度信息）
        locationCancellable = LocationManager.shared.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                Task { @MainActor in
                    self?.handleLocationUpdate(location: location)
                }
            }
    }

    // MARK: - 开始探索

    /// 开始探索
    func startExploration() async {
        guard !isExploring else {
            log("⚠️ 已经在探索中，忽略开始请求")
            return
        }

        guard let userId = AuthManager.shared.currentUser?.id else {
            log("❌ 用户未登录，无法开始探索")
            errorMessage = "请先登录"
            return
        }

        log("🚀 ========== 开始探索 ==========")
        log("👤 用户ID: \(userId)")

        // 重置状态
        state = .exploring
        isExploring = true
        currentDistance = 0
        currentDuration = 0
        currentSpeed = 0
        isOverSpeed = false
        speedWarningCountdown = 0
        startTime = Date()
        explorationResult = nil
        errorMessage = nil
        failReason = nil
        previewTier = .none
        lastLocation = nil
        lastLocationTime = nil

        // 获取起点坐标
        startCoordinate = LocationManager.shared.userLocation
        if let start = startCoordinate {
            log("📍 起点坐标: (\(String(format: "%.6f", start.latitude)), \(String(format: "%.6f", start.longitude)))")
        } else {
            log("⚠️ 无法获取起点坐标，等待GPS定位...")
        }

        // 创建数据库记录
        do {
            let session = InsertExplorationSession(
                userId: userId,
                startTime: startTime!,
                startLat: startCoordinate?.latitude,
                startLng: startCoordinate?.longitude,
                status: "active"
            )

            let response: [DBExplorationSession] = try await supabase
                .from("exploration_sessions")
                .insert(session)
                .select()
                .execute()
                .value

            currentSessionId = response.first?.id
            log("💾 数据库会话创建成功: \(currentSessionId ?? "unknown")")

        } catch {
            log("❌ 创建数据库会话失败: \(error.localizedDescription)")
        }

        // 确保定位服务运行（启用高精度探索模式）
        LocationManager.shared.enableExplorationMode()
        log("📡 GPS定位服务已启动（高精度探索模式）")

        // 启动计时器
        startDurationTimer()
        log("⏱️ 计时器已启动")

        log("✅ 探索开始成功")
    }

    // MARK: - 结束探索

    /// 结束探索并计算奖励
    func stopExploration() async {
        guard isExploring else {
            log("⚠️ 当前没有在探索，忽略停止请求")
            return
        }

        log("🏁 ========== 结束探索 ==========")
        log("📊 最终数据: 距离=\(Int(currentDistance))m, 时长=\(currentDuration)秒")

        // 更新状态
        state = .calculating
        isExploring = false

        // 停止计时器
        stopDurationTimer()
        stopSpeedWarningTimer()

        // 禁用高精度探索模式
        LocationManager.shared.disableExplorationMode()

        // 获取终点坐标
        let endCoordinate = LocationManager.shared.userLocation
        let endTime = Date()

        if let end = endCoordinate {
            log("📍 终点坐标: (\(String(format: "%.6f", end.latitude)), \(String(format: "%.6f", end.longitude)))")
        }

        // 生成奖励
        let tier = RewardGenerator.shared.calculateTier(distance: currentDistance)
        let rewards = RewardGenerator.shared.generateReward(distance: currentDistance)

        log("🎁 奖励等级: \(tier.displayName)")
        log("🎁 获得物品数量: \(rewards.count)")
        for reward in rewards {
            log("   - \(reward.itemId) x\(reward.quantity)")
        }

        // 创建探索结果
        let result = ExplorationResult(
            id: currentSessionId ?? UUID().uuidString,
            startTime: startTime ?? Date(),
            endTime: endTime,
            walkDistance: currentDistance,
            exploredArea: 0,  // 不再使用探索面积
            itemsFound: rewards
        )

        self.explorationResult = result

        // 更新数据库记录
        if let sessionId = currentSessionId {
            do {
                let itemsJson = try JSONEncoder().encode(rewards)
                let itemsJsonString = String(data: itemsJson, encoding: .utf8) ?? "[]"

                let update = UpdateExplorationSession(
                    endTime: endTime,
                    durationSeconds: currentDuration,
                    endLat: endCoordinate?.latitude,
                    endLng: endCoordinate?.longitude,
                    totalDistance: currentDistance,
                    rewardTier: tier.rawValue,
                    itemsRewarded: itemsJsonString,
                    status: "completed"
                )

                try await supabase
                    .from("exploration_sessions")
                    .update(update)
                    .eq("id", value: sessionId)
                    .execute()

                log("💾 数据库记录更新成功")

            } catch {
                log("❌ 更新数据库记录失败: \(error.localizedDescription)")
            }
        }

        // 将奖励物品添加到背包
        if !rewards.isEmpty {
            log("📦 正在将物品添加到背包...")
            let success = await InventoryManager.shared.addItems(rewards, source: "exploration")
            if success {
                log("✅ 物品已成功添加到背包")
            } else {
                log("⚠️ 部分物品添加失败")
            }
        }

        // 加载累计统计
        await loadExplorationStats()

        // 更新状态
        state = .completed

        log("✅ ========== 探索完成 ==========")
    }

    // MARK: - 探索失败（超速等原因）

    /// 因超速等原因导致探索失败
    func failExploration(reason: ExplorationFailReason) async {
        log("❌ ========== 探索失败 ==========")
        log("❌ 失败原因: \(reason.message)")

        isExploring = false
        state = .failed
        failReason = reason

        // 停止计时器
        stopDurationTimer()
        stopSpeedWarningTimer()

        // 禁用高精度探索模式
        LocationManager.shared.disableExplorationMode()

        // 更新数据库记录状态为失败
        if let sessionId = currentSessionId {
            do {
                try await supabase
                    .from("exploration_sessions")
                    .update(["status": "failed"])
                    .eq("id", value: sessionId)
                    .execute()

                log("💾 数据库记录已标记为失败")

            } catch {
                log("❌ 更新数据库记录失败: \(error.localizedDescription)")
            }
        }

        // 重置状态
        resetState()

        log("❌ ========== 探索失败处理完成 ==========")
    }

    // MARK: - 取消探索

    /// 取消探索（不计算奖励）
    func cancelExploration() async {
        guard isExploring else { return }

        log("🚫 用户取消探索")

        isExploring = false
        state = .idle

        // 停止计时器
        stopDurationTimer()
        stopSpeedWarningTimer()

        // 禁用高精度探索模式
        LocationManager.shared.disableExplorationMode()

        // 更新数据库记录状态为取消
        if let sessionId = currentSessionId {
            do {
                try await supabase
                    .from("exploration_sessions")
                    .update(["status": "cancelled"])
                    .eq("id", value: sessionId)
                    .execute()

                log("💾 探索记录已取消")

            } catch {
                log("❌ 取消探索记录失败: \(error.localizedDescription)")
            }
        }

        // 重置状态
        resetState()
    }

    // MARK: - 位置更新处理

    private func handleLocationUpdate(location: CLLocation) {
        guard isExploring else { return }

        let coordinate = location.coordinate

        // 检查 GPS 精度，过滤掉精度太差的点
        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > 50 {
            log("⚠️ GPS精度不佳: \(Int(location.horizontalAccuracy))m，忽略此点")
            return
        }

        // 使用 CLLocation 自带的速度信息（更准确）
        // speed 属性单位是 m/s，负值表示速度无效
        var speedKMH: Double = 0
        if location.speed >= 0 {
            speedKMH = location.speed * 3.6  // m/s -> km/h
        }

        // 更新当前速度
        currentSpeed = speedKMH

        // 第一个点
        if lastLocation == nil {
            lastLocation = location
            lastLocationTime = Date()
            log("📍 记录起始位置: (\(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude)))")
            log("📍 GPS精度: \(Int(location.horizontalAccuracy))m, GPS速度: \(String(format: "%.1f", speedKMH))km/h")
            return
        }

        guard let previousLocation = lastLocation else { return }

        // 计算与上一个点的距离
        let distance = location.distance(from: previousLocation)

        // 日志：位置更新
        log("📍 位置更新: 距离=\(String(format: "%.1f", distance))m, GPS速度=\(String(format: "%.1f", speedKMH))km/h, 精度=\(Int(location.horizontalAccuracy))m")

        // 检查速度是否超标（使用GPS速度）
        if speedKMH > maxAllowedSpeed {
            handleOverSpeed(speed: speedKMH)
            // 超速时不累加距离，但继续记录位置用于下次计算
            lastLocation = location
            lastLocationTime = Date()
            return
        } else {
            // 速度恢复正常
            if isOverSpeed {
                handleSpeedNormalized()
            }
        }

        // 过滤无效位置
        // 1. 距离跳变太大（GPS 跳点）
        if distance > maxJumpThreshold {
            log("⚠️ GPS跳点检测: 距离=\(Int(distance))m > 阈值=\(Int(maxJumpThreshold))m，忽略此点")
            lastLocation = location
            lastLocationTime = Date()
            return
        }

        // 2. 距离太小（没移动）- 降低阈值到2米
        if distance < minimumDistanceThreshold {
            // 不记录日志，避免刷屏
            return
        }

        // 累加距离
        currentDistance += distance
        lastLocation = location
        lastLocationTime = Date()

        // 更新奖励预览
        previewTier = RewardGenerator.shared.calculateTier(distance: currentDistance)

        log("✅ 距离累加: +\(String(format: "%.1f", distance))m = 总计 \(Int(currentDistance))m [奖励等级: \(previewTier.displayName)]")
    }

    // MARK: - 速度检测

    /// 处理超速情况
    private func handleOverSpeed(speed: Double) {
        log("🚨 超速检测: \(String(format: "%.1f", speed))km/h > \(maxAllowedSpeed)km/h")

        if !isOverSpeed {
            // 首次超速，开始警告倒计时
            isOverSpeed = true
            state = .speedWarning
            speedWarningCountdown = speedWarningDuration

            log("⚠️ 开始超速警告倒计时: \(speedWarningDuration)秒")
            startSpeedWarningTimer()
        }
    }

    /// 处理速度恢复正常
    private func handleSpeedNormalized() {
        log("✅ 速度恢复正常: \(String(format: "%.1f", currentSpeed))km/h")

        isOverSpeed = false
        speedWarningCountdown = 0
        state = .exploring

        stopSpeedWarningTimer()
    }

    // MARK: - 计时器

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.currentDuration += 1
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    private func startSpeedWarningTimer() {
        stopSpeedWarningTimer()

        speedWarningTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }

                if self.speedWarningCountdown > 0 {
                    self.speedWarningCountdown -= 1
                    self.log("⏱️ 超速倒计时: \(self.speedWarningCountdown)秒")

                    if self.speedWarningCountdown == 0 && self.isOverSpeed {
                        // 倒计时结束，仍然超速，探索失败
                        self.log("❌ 超速时间过长，探索失败")
                        await self.failExploration(reason: .speedViolation)
                    }
                }
            }
        }
    }

    private func stopSpeedWarningTimer() {
        speedWarningTimer?.invalidate()
        speedWarningTimer = nil
    }

    // MARK: - 辅助方法

    /// 重置状态
    private func resetState() {
        currentDistance = 0
        currentDuration = 0
        currentSpeed = 0
        isOverSpeed = false
        speedWarningCountdown = 0
        startTime = nil
        currentSessionId = nil
        startCoordinate = nil
        lastLocation = nil
        lastLocationTime = nil
        previewTier = .none
    }

    /// 加载累计探索统计
    func loadExplorationStats() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }

        log("📊 加载累计探索统计...")

        do {
            let sessions: [DBExplorationSession] = try await supabase
                .from("exploration_sessions")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: "completed")
                .execute()
                .value

            // 计算累计统计
            let totalDistance = sessions.compactMap { $0.totalDistance }.reduce(0, +)
            let totalDuration = sessions.compactMap { $0.durationSeconds }.reduce(0, +)
            let totalItems = sessions.count * 2

            // 创建统计对象
            self.explorationStats = ExplorationStats(
                totalWalkDistance: totalDistance,
                totalExploredArea: 0,  // 不再使用
                totalDurationMinutes: totalDuration / 60,
                totalPOIsDiscovered: 0,
                totalItemsCollected: totalItems,
                walkDistanceRank: 1,
                exploredAreaRank: 1
            )

            log("✅ 累计统计: 总距离=\(Int(totalDistance))m, 总时长=\(totalDuration / 60)分钟, 探索次数=\(sessions.count)")

        } catch {
            log("❌ 加载累计统计失败: \(error.localizedDescription)")
            self.explorationStats = MockExplorationData.mockExplorationStats
        }
    }

    /// 加载探索历史记录
    func loadExplorationHistory() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }

        log("📜 加载探索历史记录...")

        do {
            let sessions: [DBExplorationSession] = try await supabase
                .from("exploration_sessions")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: "completed")
                .order("start_time", ascending: false)
                .limit(20)
                .execute()
                .value

            // 转换为历史记录项
            var history: [ExplorationHistoryItem] = []
            for session in sessions {
                // 解析奖励等级
                let tier = RewardTier(rawValue: session.rewardTier ?? "none") ?? .none

                // 计算物品数量
                var itemCount = 0
                if let itemsJson = session.itemsRewarded,
                   let data = itemsJson.data(using: .utf8),
                   let items = try? JSONDecoder().decode([FoundItem].self, from: data) {
                    itemCount = items.reduce(0) { $0 + $1.quantity }
                }

                let item = ExplorationHistoryItem(
                    id: session.id ?? UUID().uuidString,
                    date: session.startTime,
                    distance: session.totalDistance ?? 0,
                    duration: session.durationSeconds ?? 0,
                    rewardTier: tier,
                    itemCount: itemCount
                )
                history.append(item)
            }

            self.explorationHistory = history
            log("✅ 加载了 \(history.count) 条探索历史")

        } catch {
            log("❌ 加载探索历史失败: \(error.localizedDescription)")
            self.explorationHistory = []
        }
    }

    // MARK: - 格式化方法

    /// 格式化距离
    func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }

    /// 格式化时长
    func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    /// 格式化速度
    func formatSpeed(_ kmh: Double) -> String {
        return String(format: "%.1f km/h", kmh)
    }
}
