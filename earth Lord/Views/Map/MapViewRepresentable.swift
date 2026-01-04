//
//  MapViewRepresentable.swift
//  earth Lord
//
//  MKMapView 的 SwiftUI 包装器 - 显示苹果地图并应用末世滤镜
//

import SwiftUI
import MapKit

/// MKMapView 的 SwiftUI 包装器
struct MapViewRepresentable: UIViewRepresentable {

    // MARK: - Bindings

    /// 用户位置（双向绑定）
    @Binding var userLocation: CLLocationCoordinate2D?

    /// 是否已完成首次定位（防止重复居中）
    @Binding var hasLocatedUser: Bool

    // MARK: - UIViewRepresentable Methods

    /// 创建 MKMapView
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        // MARK: 地图类型和样式
        mapView.mapType = .hybrid // 卫星图 + 道路标签（末世废土风格）
        mapView.pointOfInterestFilter = .excludingAll // 隐藏所有POI（星巴克、麦当劳等）
        mapView.showsBuildings = false // 隐藏3D建筑
        mapView.showsCompass = true // 显示指南针
        mapView.showsScale = true // 显示比例尺

        // MARK: 用户位置
        mapView.showsUserLocation = true // ⭐ 关键：显示用户位置蓝点，触发位置更新

        // MARK: 交互设置
        mapView.isZoomEnabled = true // 允许双指缩放
        mapView.isScrollEnabled = true // 允许单指拖动
        mapView.isRotateEnabled = true // 允许旋转
        mapView.isPitchEnabled = false // 禁止倾斜（保持平面视图）

        // MARK: 设置代理（⭐ 关键：接收位置更新回调）
        mapView.delegate = context.coordinator

        // MARK: 应用末世滤镜
        applyApocalypseFilter(to: mapView)

        print("🗺️ MKMapView 创建完成")

        return mapView
    }

    /// 更新 MKMapView
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 当用户位置更新且还未完成首次居中时，手动居中地图
        // 这对于模拟器特别重要，因为模拟器的位置服务可能不会触发 delegate 回调
        if let location = userLocation, !hasLocatedUser {
            print("🗺️ updateUIView: 检测到位置更新，手动居中地图")
            print("🗺️ updateUIView: 位置坐标: \(location.latitude), \(location.longitude)")

            let region = MKCoordinateRegion(
                center: location,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )

            uiView.setRegion(region, animated: true)

            // 标记已完成首次居中（直接修改 Binding，会触发父视图更新）
            hasLocatedUser = true

            print("🎯 updateUIView: 地图已手动居中到: \(location.latitude), \(location.longitude)")
        }
    }

    /// 创建 Coordinator（处理 MKMapViewDelegate 回调）
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Private Methods

    /// 应用末世滤镜效果（泛黄、降低饱和度）
    private func applyApocalypseFilter(to mapView: MKMapView) {
        // 色调控制：降低饱和度和亮度
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls?.setValue(-0.15, forKey: kCIInputBrightnessKey) // 稍微变暗
        colorControls?.setValue(0.5, forKey: kCIInputSaturationKey) // 降低饱和度

        // 棕褐色调：废土的泛黄效果
        let sepiaFilter = CIFilter(name: "CISepiaTone")
        sepiaFilter?.setValue(0.65, forKey: kCIInputIntensityKey) // 泛黄强度

        // 应用滤镜到地图图层
        mapView.layer.filters = [colorControls!, sepiaFilter!]

        print("🎨 末世滤镜已应用")
    }

    // MARK: - Coordinator

    /// Coordinator 类 - 处理 MKMapViewDelegate 回调
    class Coordinator: NSObject, MKMapViewDelegate {

        // MARK: - Properties

        var parent: MapViewRepresentable

        // MARK: - Initialization

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        // MARK: - MKMapViewDelegate Methods

        /// ⭐ 关键方法：用户位置更新时调用
        /// 这个方法会在 MKMapView 获取到用户位置时自动触发（主要用于真机）
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            // 获取用户位置
            guard let location = userLocation.location else { return }

            print("🗺️ Coordinator: 用户位置更新: \(location.coordinate.latitude), \(location.coordinate.longitude)")

            // 更新绑定的位置坐标
            DispatchQueue.main.async {
                self.parent.userLocation = location.coordinate
            }

            // 如果已完成首次居中，不再自动居中（避免影响用户手动拖动）
            guard !parent.hasLocatedUser else {
                print("🗺️ Coordinator: 已完成首次居中，跳过自动居中")
                return
            }

            // 创建居中区域（约1公里范围）
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000, // 南北方向1公里
                longitudinalMeters: 1000 // 东西方向1公里
            )

            // ⭐ 平滑居中地图到用户位置
            mapView.setRegion(region, animated: true)

            // 更新外部状态
            DispatchQueue.main.async {
                self.parent.hasLocatedUser = true
            }

            print("🎯 Coordinator: 地图已自动居中到用户位置")
        }

        /// 地图区域改变时调用
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // 可以在这里处理地图移动后的逻辑
        }

        /// 地图加载完成时调用
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            print("🗺️ 地图加载完成")
        }

        /// 地图加载失败时调用
        func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
            print("❌ 地图加载失败: \(error.localizedDescription)")
        }
    }
}
