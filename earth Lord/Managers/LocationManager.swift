//
//  LocationManager.swift
//  earth Lord
//
//  GPS 定位管理器 - 负责请求定位权限、获取用户位置
//

import Foundation
import CoreLocation
import Combine

/// GPS 定位管理器
class LocationManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// 用户当前位置坐标
    @Published var userLocation: CLLocationCoordinate2D?

    /// 定位权限状态
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// 错误信息
    @Published var locationError: String?

    // MARK: - Private Properties

    /// CoreLocation 管理器
    private let locationManager = CLLocationManager()

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

    override init() {
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

        // 更新用户位置
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.locationError = nil
        }

        print("📍 位置更新: 纬度 \(location.coordinate.latitude), 经度 \(location.coordinate.longitude)")
    }

    /// 定位失败时调用
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
        }

        print("❌ 定位失败: \(error.localizedDescription)")
    }
}
