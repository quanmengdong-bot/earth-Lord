//
//  MapTabView.swift
//  earth Lord
//
//  地图页面 - 显示真实地图、用户位置、定位权限管理
//

import SwiftUI
import MapKit

struct MapTabView: View {

    // MARK: - State Properties

    /// 定位管理器
    @StateObject private var locationManager = LocationManager()

    /// 语言管理器
    @ObservedObject private var languageManager = LanguageManager.shared

    /// 是否已完成首次定位（防止重复居中）
    @State private var hasLocatedUser = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // MARK: 地图视图
            MapViewRepresentable(
                userLocation: $locationManager.userLocation,
                hasLocatedUser: $hasLocatedUser,
                trackingPath: $locationManager.pathCoordinates,
                pathUpdateVersion: locationManager.pathUpdateVersion,
                isTracking: locationManager.isTracking
            )
            .ignoresSafeArea()

            // MARK: 顶部状态栏（定位权限提示）
            VStack {
                if locationManager.authorizationStatus == .notDetermined {
                    // 未请求权限时的提示
                    requestPermissionBanner
                        .padding(.top, 60)
                } else if locationManager.isDenied {
                    // 权限被拒绝时的提示
                    permissionDeniedBanner
                        .padding(.top, 60)
                } else if let error = locationManager.locationError {
                    // 定位错误提示
                    errorBanner(message: error)
                        .padding(.top, 60)
                }

                Spacer()

                // MARK: 底部信息栏（坐标显示）
                if let location = locationManager.userLocation {
                    locationInfoPanel(location: location)
                        .padding(.bottom, 100) // 留出 Tab Bar 空间
                }
            }

            // MARK: 右下角按钮组
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // 圈地按钮
                        trackingButton

                        // 定位按钮
                        locateButton
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 120) // 留出 Tab Bar 空间
                }
            }
        }
        .onAppear {
            // 页面出现时请求定位权限
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            } else if locationManager.isAuthorized {
                locationManager.startUpdatingLocation()
            }
        }
        .id(languageManager.currentLanguage) // 强制刷新以支持语言切换
    }

    // MARK: - Subviews

    /// 请求权限横幅
    private var requestPermissionBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(ApocalypseTheme.primary)
                    .font(.title2)

                Text("需要定位权限".localized)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }

            Text("《地球新主》需要获取您的位置来显示您在末日世界中的坐标".localized)
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.leading)

            Button(action: {
                locationManager.requestPermission()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("允许定位".localized)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ApocalypseTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            ApocalypseTheme.cardBackground.opacity(0.95)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    /// 权限被拒绝横幅
    private var permissionDeniedBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(ApocalypseTheme.warning)
                    .font(.title2)

                Text("定位权限被拒绝".localized)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }

            Text("请在设置中允许《地球新主》访问您的位置".localized)
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.leading)

            Button(action: {
                // 打开系统设置
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("前往设置".localized)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ApocalypseTheme.warning)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            ApocalypseTheme.cardBackground.opacity(0.95)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    /// 错误提示横幅
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(ApocalypseTheme.danger)

            Text(message)
                .font(.caption)
                .foregroundColor(.white)

            Spacer()
        }
        .padding()
        .background(
            ApocalypseTheme.danger.opacity(0.2)
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }

    /// 位置信息面板（显示坐标）
    private func locationInfoPanel(location: CLLocationCoordinate2D) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(ApocalypseTheme.primary)
                Text("当前位置".localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            HStack(spacing: 20) {
                // 纬度
                VStack(alignment: .leading, spacing: 4) {
                    Text("纬度".localized)
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text(String(format: "%.6f", location.latitude))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                }

                Divider()
                    .frame(height: 30)
                    .background(ApocalypseTheme.textSecondary)

                // 经度
                VStack(alignment: .leading, spacing: 4) {
                    Text("经度".localized)
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text(String(format: "%.6f", location.longitude))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            ApocalypseTheme.cardBackground.opacity(0.9)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    /// 圈地按钮（右下角）
    private var trackingButton: some View {
        Button(action: {
            if locationManager.isTracking {
                // 正在追踪，点击停止
                locationManager.stopPathTracking()
            } else {
                // 未追踪，点击开始
                if locationManager.isAuthorized {
                    locationManager.startPathTracking()
                } else {
                    // 未授权，请求权限
                    locationManager.requestPermission()
                }
            }
        }) {
            HStack(spacing: 8) {
                // 图标
                Image(systemName: locationManager.isTracking ? "stop.fill" : "flag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                // 文字
                Text(locationManager.isTracking ? "停止圈地" : "开始圈地")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                // 点数显示（追踪时）
                if locationManager.isTracking {
                    Text("(\(locationManager.pathCoordinates.count))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(locationManager.isTracking ?
                          ApocalypseTheme.danger :
                          ApocalypseTheme.primary)
            )
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }

    /// 定位按钮（右下角）
    private var locateButton: some View {
        Button(action: {
            // 如果已授权，重新开始定位
            if locationManager.isAuthorized {
                // 重置首次居中标志，允许再次自动居中
                hasLocatedUser = false

                // 重新获取位置（会触发地图居中）
                locationManager.stopUpdatingLocation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    locationManager.startUpdatingLocation()
                }
            } else {
                // 未授权时请求权限
                locationManager.requestPermission()
            }
        }) {
            ZStack {
                Circle()
                    .fill(ApocalypseTheme.cardBackground.opacity(0.95))
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)

                Image(systemName: locationManager.isAuthorized ? "location.fill" : "location.slash.fill")
                    .foregroundColor(locationManager.isAuthorized ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
                    .font(.title3)
            }
        }
    }
}

#Preview {
    MapTabView()
}
