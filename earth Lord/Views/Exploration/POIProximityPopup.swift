//
//  POIProximityPopup.swift
//  earth Lord
//
//  POI 接近弹窗 - 玩家进入 POI 范围时显示
//

import SwiftUI
import CoreLocation

struct POIProximityPopup: View {

    // MARK: - Properties

    let poi: GamePOI
    let onScavenge: () -> Void
    let onDismiss: () -> Void

    /// 用户当前位置（计算距离用）
    @ObservedObject private var locationManager = LocationManager.shared

    // MARK: - Computed Properties

    /// 计算与 POI 的距离
    private var distanceToPOI: Int {
        guard let userLocation = locationManager.userLocation else { return 0 }
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let poiLocation = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
        return Int(userCLLocation.distance(from: poiLocation))
    }

    /// POI 类型颜色
    private var typeColor: Color {
        switch poi.type {
        case .hospital, .pharmacy:
            return Color.red
        case .gasStation:
            return Color.orange
        case .restaurant, .cafe:
            return Color.yellow
        case .store, .convenience, .supermarket:
            return Color.blue
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 顶部图标和标题
            VStack(spacing: 12) {
                // 类型图标
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.2))
                        .frame(width: 70, height: 70)

                    Image(systemName: poi.type.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(typeColor)
                }

                // 发现废墟标题
                Text(poi.ruinName)
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .multilineTextAlignment(.center)

                // 距离显示
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.success)

                    Text("距离: \(distanceToPOI) 米")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                // 类型标签
                Text(poi.type.ruinDescription)
                    .font(.caption)
                    .foregroundColor(typeColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(typeColor.opacity(0.15))
                    .cornerRadius(12)
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)

            // 提示文字
            Text("这里可能有幸存者留下的物资...")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textMuted)
                .padding(.top, 16)

            // 按钮区域
            HStack(spacing: 16) {
                // 稍后再说按钮
                Button(action: onDismiss) {
                    Text("稍后再说")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ApocalypseTheme.textMuted, lineWidth: 1)
                        )
                }

                // 立即搜刮按钮
                Button(action: onScavenge) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.subheadline)

                        Text("立即搜刮")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [ApocalypseTheme.primary, ApocalypseTheme.primaryDark]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
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
}

// MARK: - Preview

#Preview {
    ZStack {
        ApocalypseTheme.background
            .ignoresSafeArea()

        POIProximityPopup(
            poi: GamePOI(
                id: "test",
                name: "沃尔玛超市",
                type: .supermarket,
                coordinate: CLLocationCoordinate2D(latitude: 22.54, longitude: 114.06)
            ),
            onScavenge: { print("搜刮") },
            onDismiss: { print("关闭") }
        )
    }
}
