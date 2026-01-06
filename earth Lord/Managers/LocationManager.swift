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
        } else {
            print("❌ 闭环检测失败: 距离起点还有 \(Int(distanceToStart - closureDistanceThreshold)) 米")
        }
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
