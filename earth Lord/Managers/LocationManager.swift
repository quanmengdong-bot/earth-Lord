//
//  LocationManager.swift
//  earth Lord
//
//  GPS 定位管理器 - 负责请求定位权限、获取用户位置
//

import Foundation
import CoreLocation
import Combine

/// GPS 定位管理器（单例模式）
class LocationManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = LocationManager()

    // MARK: - Published Properties

    /// 用户当前位置坐标
    @Published var userLocation: CLLocationCoordinate2D?

    /// 定位权限状态
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// 错误信息
    @Published var locationError: String?

    /// 是否正在追踪路径
    @Published var isTracking: Bool = false

    /// 路径坐标数组（存储原始 WGS-84 坐标）
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []

    /// 路径更新版本号（每次路径变化时 +1，用于触发 SwiftUI 更新）
    @Published var pathUpdateVersion: Int = 0

    /// 路径是否闭合（Day16 会用到）
    @Published var isPathClosed: Bool = false

    /// 速度警告信息（Day16）
    @Published var speedWarning: String?

    /// 是否超速（Day16）
    @Published var isOverSpeed: Bool = false

    /// 领地验证是否通过（Day17）
    @Published var territoryValidationPassed: Bool = false

    /// 领地验证错误信息（Day17）
    @Published var territoryValidationError: String? = nil

    /// 计算出的领地面积（平方米）（Day17）
    @Published var calculatedArea: Double = 0

    // MARK: - Private Properties

    /// CoreLocation 管理器
    private let locationManager = CLLocationManager()

    /// 当前位置（用于 Timer 采点）
    private var currentLocation: CLLocation?

    /// 路径更新定时器（每 2 秒检查一次）
    private var pathUpdateTimer: Timer?

    /// 上次位置的时间戳（用于速度检测）
    private var lastLocationTimestamp: Date?

    // MARK: - Constants

    /// 闭环距离阈值（米）
    private let closureDistanceThreshold: Double = 30.0

    /// 最少路径点数
    private let minimumPathPoints: Int = 10

    /// 最少路径总长度（米）- Day17
    private let minimumTotalDistance: Double = 50.0

    /// 最小封闭面积（平方米）- Day17
    private let minimumEnclosedArea: Double = 100.0

    // MARK: - Computed Properties

    /// 是否已授权定位
    var isAuthorized: Bool {
        return authorizationStatus == .authorizedWhenInUse ||
               authorizationStatus == .authorizedAlways
    }

    /// 是否被拒绝定位
    var isDenied: Bool {
        return authorizationStatus == .denied ||
               authorizationStatus == .restricted
    }

    // MARK: - Initialization

    private override init() {
        super.init()

        // 配置 LocationManager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // 最高精度
        locationManager.distanceFilter = 10 // 移动10米才更新位置

        // 获取当前授权状态
        authorizationStatus = locationManager.authorizationStatus

        print("📍 LocationManager 初始化完成，当前授权状态: \(authorizationStatusString)")
    }

    // MARK: - Public Methods

    /// 请求定位权限
    func requestPermission() {
        print("📍 请求定位权限...")
        locationManager.requestWhenInUseAuthorization()
    }

    /// 开始定位
    func startUpdatingLocation() {
        guard isAuthorized else {
            print("⚠️ 未授权，无法开始定位")
            locationError = "未授权定位权限"
            return
        }

        print("📍 开始获取用户位置...")
        locationManager.startUpdatingLocation()
    }

    /// 停止定位
    func stopUpdatingLocation() {
        print("📍 停止获取用户位置")
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Path Tracking Methods

    /// 开始路径追踪
    func startPathTracking() {
        guard isAuthorized else {
            print("⚠️ 未授权，无法开始追踪")
            locationError = "需要定位权限才能开始圈地"
            return
        }

        print("🚩 开始路径追踪")
        isTracking = true
        isPathClosed = false

        // Day16B: 记录日志
        TerritoryLogger.shared.log("开始圈地追踪", type: .info)

        // 启动定时器，每 2 秒检查一次位置
        pathUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.recordPathPoint()
        }

        // 确保定位服务正在运行
        startUpdatingLocation()
    }

    /// 停止路径追踪
    func stopPathTracking() {
        print("🛑 停止路径追踪，当前路径点数: \(pathCoordinates.count)")
        isTracking = false

        // Day16B: 记录日志
        TerritoryLogger.shared.log("停止追踪，共 \(pathCoordinates.count) 个点", type: .info)

        // 停止定时器
        pathUpdateTimer?.invalidate()
        pathUpdateTimer = nil
    }

    /// 清除路径
    func clearPath() {
        print("🧹 清除路径")
        pathCoordinates.removeAll()
        pathUpdateVersion += 1
        isPathClosed = false
        isTracking = false
        pathUpdateTimer?.invalidate()
        pathUpdateTimer = nil
    }

    /// 记录路径点（定时器回调）
    private func recordPathPoint() {
        guard isTracking, let location = currentLocation else {
            return
        }

        // ⭐ Day16: 速度检测（超速则不记录该点）
        if !validateMovementSpeed(newLocation: location) {
            return
        }

        let coordinate = location.coordinate

        // 如果是第一个点，直接记录
        if pathCoordinates.isEmpty {
            pathCoordinates.append(coordinate)
            pathUpdateVersion += 1
            lastLocationTimestamp = Date()
            print("📍 记录第一个路径点: \(coordinate.latitude), \(coordinate.longitude)")
            return
        }

        // 计算与上一个点的距离
        guard let lastCoordinate = pathCoordinates.last else { return }
        let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        let distance = location.distance(from: lastLocation)

        // 只有移动超过 10 米才记录新点
        if distance > 10 {
            pathCoordinates.append(coordinate)
            pathUpdateVersion += 1
            lastLocationTimestamp = Date()
            print("📍 记录新路径点 #\(pathCoordinates.count): 距离上个点 \(Int(distance))米")

            // Day16B: 记录日志
            TerritoryLogger.shared.log("记录第 \(pathCoordinates.count) 个点，距上点 \(Int(distance))m", type: .info)

            // ⭐ Day16: 每次添加新坐标后检查闭环
            checkPathClosure()
        }
    }

    // MARK: - Day16: 闭环检测

    /// 检查路径是否已闭合
    private func checkPathClosure() {
        // 已经闭合则不再检测
        guard !isPathClosed else { return }

        // 检查点数是否足够
        guard pathCoordinates.count >= minimumPathPoints else {
            print("🔍 闭环检测: 点数不足（当前 \(pathCoordinates.count)，需要 \(minimumPathPoints)）")
            return
        }

        // 获取起点和当前位置
        guard let firstCoordinate = pathCoordinates.first,
              let currentCoordinate = pathCoordinates.last else {
            return
        }

        // 计算当前位置到起点的距离
        let firstLocation = CLLocation(latitude: firstCoordinate.latitude, longitude: firstCoordinate.longitude)
        let currentLocationPoint = CLLocation(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude)
        let distanceToStart = currentLocationPoint.distance(from: firstLocation)

        print("🔍 闭环检测: 当前位置距离起点 \(Int(distanceToStart)) 米（阈值 \(Int(closureDistanceThreshold)) 米）")

        // Day16B: 记录日志（点数足够且未闭环时）
        TerritoryLogger.shared.log("距起点 \(Int(distanceToStart))m (需≤30m)", type: .info)

        // 判断是否闭环
        if distanceToStart <= closureDistanceThreshold {
            isPathClosed = true
            pathUpdateVersion += 1
            print("✅ 闭环检测成功！路径已闭合，共 \(pathCoordinates.count) 个点")

            // Day16B: 记录成功日志
            TerritoryLogger.shared.log("闭环成功！距起点 \(Int(distanceToStart))m", type: .success)

            // Day17: 触发领地验证（闭环成功 ≠ 圈地成功）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let _ = self.validateTerritory()
            }
        } else {
            print("❌ 闭环检测失败: 距离起点还有 \(Int(distanceToStart - closureDistanceThreshold)) 米")
        }
    }

    // MARK: - Day17: 领地验证

    /// 计算路径总长度（米）
    private func calculateTotalPathDistance() -> Double {
        guard pathCoordinates.count >= 2 else {
            return 0
        }

        var totalDistance: Double = 0

        for i in 0..<(pathCoordinates.count - 1) {
            let coordinate1 = pathCoordinates[i]
            let coordinate2 = pathCoordinates[i + 1]

            let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
            let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)

            totalDistance += location1.distance(from: location2)
        }

        return totalDistance
    }

    /// 计算多边形面积（平方米）- 使用 Shoelace 公式 + 球面校正
    private func calculatePolygonArea() -> Double {
        guard pathCoordinates.count >= 3 else {
            return 0
        }

        let earthRadius: Double = 6371000 // 地球平均半径（米）

        var area: Double = 0

        for i in 0..<pathCoordinates.count {
            let current = pathCoordinates[i]
            let next = pathCoordinates[(i + 1) % pathCoordinates.count]

            // Shoelace 公式：Area = 0.5 * |Σ(xi * yi+1 - xi+1 * yi)|
            // 注意：经度 = X，纬度 = Y
            let term = current.longitude * next.latitude - next.longitude * current.latitude
            area += term
        }

        area = abs(area) / 2.0

        // 球面校正：将度数转换为实际距离
        // 1 度纬度 ≈ 111,111 米
        // 1 度经度 ≈ 111,111 * cos(纬度) 米
        let avgLatitude = pathCoordinates.map { $0.latitude }.reduce(0, +) / Double(pathCoordinates.count)
        let latitudeCorrection = 111111.0 // 米/度
        let longitudeCorrection = 111111.0 * cos(avgLatitude * .pi / 180.0) // 米/度

        // 校正面积（度² → 米²）
        area = area * latitudeCorrection * longitudeCorrection

        return area
    }

    /// 判断两线段是否相交 - CCW 算法
    /// - Parameters:
    ///   - p1: 线段1的起点
    ///   - p2: 线段1的终点
    ///   - p3: 线段2的起点
    ///   - p4: 线段2的终点
    /// - Returns: true 表示相交
    private func segmentsIntersect(p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D,
                                   p3: CLLocationCoordinate2D, p4: CLLocationCoordinate2D) -> Bool {
        /// CCW（Counter-Clockwise）判断：判断三点是否逆时针排列
        /// - Returns: true 表示逆时针
        func ccw(_ A: CLLocationCoordinate2D, _ B: CLLocationCoordinate2D, _ C: CLLocationCoordinate2D) -> Bool {
            // 叉积公式：(C.y - A.y) * (B.x - A.x) - (B.y - A.y) * (C.x - A.x)
            // 注意：经度 = X，纬度 = Y
            let crossProduct = (C.latitude - A.latitude) * (B.longitude - A.longitude) -
                              (B.latitude - A.latitude) * (C.longitude - A.longitude)
            return crossProduct > 0
        }

        // 两线段相交的充要条件：
        // 1. p1-p2 线段两端的点在 p3-p4 线段的两侧
        // 2. p3-p4 线段两端的点在 p1-p2 线段的两侧
        return ccw(p1, p3, p4) != ccw(p2, p3, p4) && ccw(p1, p2, p3) != ccw(p1, p2, p4)
    }

    /// 检测路径是否存在自相交
    /// - Returns: true 表示存在自相交
    func hasPathSelfIntersection() -> Bool {
        // 防御性检查：至少需要 4 个点才能形成自相交
        guard pathCoordinates.count >= 4 else {
            return false
        }

        // ⭐ 防御性编程：深拷贝数组（避免并发修改）
        let pathSnapshot = Array(pathCoordinates)

        // 再次检查（防止拷贝后数组为空）
        guard pathSnapshot.count >= 4 else {
            return false
        }

        // 计算线段数量
        let segmentCount = pathSnapshot.count - 1

        // 防御性检查：至少需要 2 条线段
        guard segmentCount >= 2 else {
            return false
        }

        // ⭐ 关键：跳过首尾线段的比较（避免闭环误判）
        let skipHeadCount = 2
        let skipTailCount = 2

        // 遍历所有线段对
        for i in 0..<segmentCount {
            // 防御性检查：确保索引有效
            guard i < pathSnapshot.count - 1 else {
                break
            }

            let p1 = pathSnapshot[i]
            let p2 = pathSnapshot[i + 1]

            // 检测与后续非相邻线段的相交
            for j in (i + 2)..<segmentCount {
                // 防御性检查：确保索引有效
                guard j < pathSnapshot.count - 1 else {
                    break
                }

                // ⭐ 跳过首尾线段的比较
                let isHeadSegment = i < skipHeadCount
                let isTailSegment = j >= segmentCount - skipTailCount

                if isHeadSegment && isTailSegment {
                    continue
                }

                let p3 = pathSnapshot[j]
                let p4 = pathSnapshot[j + 1]

                // 判断是否相交
                if segmentsIntersect(p1: p1, p2: p2, p3: p3, p4: p4) {
                    let message = "自交检测: 线段\(i)-\(i+1) 与 线段\(j)-\(j+1) 相交"
                    TerritoryLogger.shared.log(message, type: .error)
                    print("❌ \(message)")
                    return true
                }
            }
        }

        TerritoryLogger.shared.log("自交检测: 无交叉 ✓", type: .info)
        print("✅ 自交检测: 无交叉")
        return false
    }

    /// 综合验证领地
    /// - Returns: (是否有效, 错误信息)
    func validateTerritory() -> (isValid: Bool, errorMessage: String?) {
        TerritoryLogger.shared.log("开始领地验证", type: .info)
        print("🔍 开始领地验证...")

        // 1️⃣ 检查点数
        if pathCoordinates.count < minimumPathPoints {
            let message = "点数不足：当前 \(pathCoordinates.count) 个点，需要至少 \(minimumPathPoints) 个点"
            TerritoryLogger.shared.log(message, type: .error)
            print("❌ \(message)")

            DispatchQueue.main.async {
                self.territoryValidationPassed = false
                self.territoryValidationError = "点数不足（需要≥\(self.minimumPathPoints)个点）"
                self.calculatedArea = 0
            }
            return (false, message)
        }
        TerritoryLogger.shared.log("点数检查: \(pathCoordinates.count) 个点 ✓", type: .info)
        print("✅ 点数检查: \(pathCoordinates.count) 个点")

        // 2️⃣ 检查路径总长度
        let totalDistance = calculateTotalPathDistance()
        if totalDistance < minimumTotalDistance {
            let message = "路径过短：当前 \(Int(totalDistance)) 米，需要至少 \(Int(minimumTotalDistance)) 米"
            TerritoryLogger.shared.log(message, type: .error)
            print("❌ \(message)")

            DispatchQueue.main.async {
                self.territoryValidationPassed = false
                self.territoryValidationError = "路径过短（需要≥\(Int(self.minimumTotalDistance))米）"
                self.calculatedArea = 0
            }
            return (false, message)
        }
        TerritoryLogger.shared.log("距离检查: \(Int(totalDistance)) 米 ✓", type: .info)
        print("✅ 距离检查: \(Int(totalDistance)) 米")

        // 3️⃣ 检查是否存在自相交
        if hasPathSelfIntersection() {
            let message = "路径自相交：存在\"8字型\"交叉"
            TerritoryLogger.shared.log(message, type: .error)
            print("❌ \(message)")

            DispatchQueue.main.async {
                self.territoryValidationPassed = false
                self.territoryValidationError = "路径不能交叉（8字型）"
                self.calculatedArea = 0
            }
            return (false, message)
        }

        // 4️⃣ 检查封闭面积
        let area = calculatePolygonArea()
        if area < minimumEnclosedArea {
            let message = "面积过小：当前 \(Int(area)) m²，需要至少 \(Int(minimumEnclosedArea)) m²"
            TerritoryLogger.shared.log(message, type: .error)
            print("❌ \(message)")

            DispatchQueue.main.async {
                self.territoryValidationPassed = false
                self.territoryValidationError = "面积过小（需要≥\(Int(self.minimumEnclosedArea))m²）"
                self.calculatedArea = area
            }
            return (false, message)
        }
        TerritoryLogger.shared.log("面积检查: \(Int(area)) m² ✓", type: .success)
        print("✅ 面积检查: \(Int(area)) m²")

        // ✅ 所有检查通过
        let successMessage = "领地验证成功！面积: \(Int(area)) m²"
        TerritoryLogger.shared.log(successMessage, type: .success)
        print("✅ \(successMessage)")

        DispatchQueue.main.async {
            self.territoryValidationPassed = true
            self.territoryValidationError = nil
            self.calculatedArea = area
        }

        return (true, nil)
    }

    // MARK: - Day16: 速度检测

    /// 验证移动速度（防止作弊）
    /// - Parameter newLocation: 新位置
    /// - Returns: true 表示速度正常，false 表示超速
    private func validateMovementSpeed(newLocation: CLLocation) -> Bool {
        // 第一个点或没有上次时间戳，直接通过
        guard let lastTimestamp = lastLocationTimestamp,
              let lastCoordinate = pathCoordinates.last else {
            return true
        }

        // 计算距离（米）
        let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        let distance = newLocation.distance(from: lastLocation)

        // 计算时间差（秒）
        let timeInterval = Date().timeIntervalSince(lastTimestamp)

        // 避免除以 0
        guard timeInterval > 0 else { return true }

        // 计算速度（km/h）
        let speed = (distance / timeInterval) * 3.6

        print("🚗 速度检测: \(String(format: "%.1f", speed)) km/h")

        // 速度 > 30 km/h → 暂停追踪
        if speed > 30 {
            DispatchQueue.main.async {
                self.speedWarning = "⚠️ 速度过快！已暂停追踪（\(Int(speed)) km/h）"
                self.isOverSpeed = true
                self.stopPathTracking()
            }
            print("❌ 速度超限: \(String(format: "%.1f", speed)) km/h > 30 km/h，暂停追踪")

            // Day16B: 记录错误日志
            TerritoryLogger.shared.log("超速 \(Int(speed)) km/h，已停止追踪", type: .error)

            return false
        }

        // 速度 > 15 km/h → 警告
        if speed > 15 {
            DispatchQueue.main.async {
                self.speedWarning = "⚠️ 速度过快！请步行（\(Int(speed)) km/h）"
                self.isOverSpeed = true
            }
            print("⚠️ 速度警告: \(String(format: "%.1f", speed)) km/h > 15 km/h")

            // Day16B: 记录警告日志
            TerritoryLogger.shared.log("速度较快 \(Int(speed)) km/h", type: .warning)

            return false
        }

        // 速度正常，清除警告
        if isOverSpeed {
            DispatchQueue.main.async {
                self.speedWarning = nil
                self.isOverSpeed = false
            }
        }

        return true
    }

    // MARK: - Private Helpers

    /// 授权状态的字符串描述
    private var authorizationStatusString: String {
        switch authorizationStatus {
        case .notDetermined:
            return "未确定"
        case .restricted:
            return "受限"
        case .denied:
            return "已拒绝"
        case .authorizedAlways:
            return "始终允许"
        case .authorizedWhenInUse:
            return "使用期间允许"
        @unknown default:
            return "未知"
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    /// 授权状态改变时调用
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        print("📍 授权状态变更: \(authorizationStatusString)")

        // 如果已授权，自动开始定位
        if isAuthorized {
            startUpdatingLocation()
        } else if isDenied {
            locationError = "定位权限被拒绝，请在设置中允许定位"
        }
    }

    /// 成功获取位置时调用
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // ⭐ 关键：保存当前位置供 Timer 使用
        currentLocation = location

        // 更新用户位置
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.locationError = nil
        }

        print("📍 位置更新: 纬度 \(location.coordinate.latitude), 经度 \(location.coordinate.longitude)")
    }

    /// 定位失败时调用
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as NSError

        // 忽略临时错误（Code 0）和延迟错误，这些通常是模拟器的正常行为
        if clError.code == 0 || clError.code == CLError.locationUnknown.rawValue {
            print("ℹ️ 定位临时错误（可忽略）: \(error.localizedDescription)")
            return
        }

        // 只记录真正需要用户关注的错误
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
        }

        print("❌ 定位失败: \(error.localizedDescription)")
    }
}
