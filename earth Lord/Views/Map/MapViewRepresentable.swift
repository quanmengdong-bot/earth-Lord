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

    /// 追踪路径（双向绑定）
    @Binding var trackingPath: [CLLocationCoordinate2D]

    /// 路径更新版本号（用于触发更新）
    var pathUpdateVersion: Int

    /// 是否正在追踪
    var isTracking: Bool

    /// 路径是否已闭合（Day16）
    var isPathClosed: Bool

    /// Day18: 已加载的领地列表
    var territories: [Territory]

    /// Day18: 当前用户 ID（用于区分自己和他人的领地）
    var currentUserId: String?

    /// Day18: 领地版本号（用于触发更新）
    var territoriesVersion: Int

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

        print("🗺️ updateUIView 被调用 - userLocation: \(userLocation != nil ? "有位置" : "无位置"), hasLocatedUser: \(hasLocatedUser)")

        if let location = userLocation, !hasLocatedUser {
            print("🗺️ updateUIView: 当前位置坐标: \(location.latitude), \(location.longitude)")
            print("🗺️ updateUIView: 检测到位置更新且未完成首次居中，准备居中地图")

            // 使用更小的范围（200米），让居中效果更明显
            let region = MKCoordinateRegion(
                center: location,
                latitudinalMeters: 200,  // 南北方向200米
                longitudinalMeters: 200  // 东西方向200米
            )

            print("🗺️ updateUIView: 设置地图区域 center: \(region.center.latitude), \(region.center.longitude), span: 200m")
            print("🗺️ updateUIView: 当前地图中心: \(uiView.region.center.latitude), \(uiView.region.center.longitude)")

            // 只调用一次 setRegion，使用动画让效果更明显
            uiView.setRegion(region, animated: true)

            // 等待地图区域设置完成后再标记（延迟 0.5 秒确保生效）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.hasLocatedUser = true
                print("🎯 updateUIView: 地图已手动居中，hasLocatedUser 设置为 true")
                print("🗺️ updateUIView: 居中后地图中心: \(uiView.region.center.latitude), \(uiView.region.center.longitude)")
            }
        }

        // ⭐ 更新追踪路径（当 pathUpdateVersion 变化时）
        updateTrackingPath(uiView)

        // ⭐ Day18: 绘制所有领地
        print("🗺️ updateUIView: territories.count = \(territories.count), version = \(territoriesVersion)")
        drawTerritories(on: uiView)
    }

    /// 创建 Coordinator（处理 MKMapViewDelegate 回调）
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Private Methods

    /// 更新追踪路径显示
    private func updateTrackingPath(_ mapView: MKMapView) {
        // ⭐ Day18: 只移除轨迹线和当前圈地多边形，保留领地多边形
        let trackingOverlays = mapView.overlays.filter { overlay in
            // 移除 MKPolyline（轨迹线）
            if overlay is MKPolyline {
                return true
            }
            // 移除没有 title 或 title 为 "tracking" 的多边形（当前圈地）
            if let polygon = overlay as? MKPolygon {
                return polygon.title == nil || polygon.title == "tracking"
            }
            return false
        }
        mapView.removeOverlays(trackingOverlays)

        // 如果路径点少于 2 个，不绘制
        guard trackingPath.count >= 2 else {
            return
        }

        // ⭐ 关键：坐标转换 WGS-84 → GCJ-02
        var convertedCoordinates = CoordinateConverter.wgs84ToGcj02(trackingPath)

        print("🗺️ 更新轨迹路径: \(convertedCoordinates.count) 个点, 闭环状态: \(isPathClosed)")

        // 创建 MKPolyline（轨迹线）- 使用 & 传入指针
        let polyline = MKPolyline(coordinates: &convertedCoordinates, count: convertedCoordinates.count)

        // 添加轨迹线到地图
        mapView.addOverlay(polyline)

        // ⭐ Day16: 如果闭环且点数 ≥ 3，添加多边形填充
        if isPathClosed && convertedCoordinates.count >= 3 {
            let polygon = MKPolygon(coordinates: &convertedCoordinates, count: convertedCoordinates.count)
            polygon.title = "tracking" // Day18: 标记为当前圈地，区别于已保存的领地
            mapView.addOverlay(polygon)
            print("✅ 已添加多边形填充（闭环）")
        }

        print("✅ 轨迹已添加到地图")
    }

    /// Day18: 绘制所有领地
    private func drawTerritories(on mapView: MKMapView) {
        // 没有领地时直接返回
        guard !territories.isEmpty else { return }

        // 移除旧的领地多边形（保留轨迹线和当前圈地多边形）
        let territoryOverlays = mapView.overlays.filter { overlay in
            if let polygon = overlay as? MKPolygon {
                return polygon.title == "mine" || polygon.title == "others"
            }
            return false
        }
        mapView.removeOverlays(territoryOverlays)

        // 绘制每个领地
        for territory in territories {
            var coords = territory.toCoordinates()

            print("🗺️ Day18: 领地 \(territory.displayName) 有 \(coords.count) 个坐标点")

            // 坐标点数不足，跳过
            guard coords.count >= 3 else {
                print("⚠️ Day18: 领地 \(territory.displayName) 坐标点不足，跳过")
                continue
            }

            // ⚠️ 中国大陆需要坐标转换 WGS-84 → GCJ-02
            coords = CoordinateConverter.wgs84ToGcj02(coords)

            // ⭐ 关键：使用 & 传入坐标数组指针
            let polygon = MKPolygon(coordinates: &coords, count: coords.count)

            // ⚠️ 关键：比较 userId 时必须统一大小写！
            // 数据库存的是小写 UUID，但 iOS 的 uuidString 返回大写
            let isMine = territory.userId.lowercased() == currentUserId?.lowercased()
            polygon.title = isMine ? "mine" : "others"

            mapView.addOverlay(polygon, level: .aboveRoads)
            print("✅ Day18: 已添加领地多边形 \(territory.displayName), isMine: \(isMine)")
        }

        print("🗺️ Day18: 已绘制 \(territories.count) 个领地")
    }

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
            print("🗺️ Coordinator: didUpdate 被调用")

            // 获取用户位置
            guard let location = userLocation.location else {
                print("🗺️ Coordinator: location 为 nil，跳过")
                return
            }

            print("🗺️ Coordinator: 用户位置更新: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("🗺️ Coordinator: 当前 hasLocatedUser = \(parent.hasLocatedUser)")

            // 更新绑定的位置坐标
            DispatchQueue.main.async {
                self.parent.userLocation = location.coordinate
                print("🗺️ Coordinator: 已更新 parent.userLocation")
            }

            // 如果已完成首次居中，不再自动居中（避免影响用户手动拖动）
            guard !parent.hasLocatedUser else {
                print("🗺️ Coordinator: 已完成首次居中，跳过自动居中")
                return
            }

            print("🗺️ Coordinator: 准备居中地图...")

            // 使用更小的范围（200米），让居中效果更明显
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 200,  // 南北方向200米
                longitudinalMeters: 200  // 东西方向200米
            )

            print("🗺️ Coordinator: 设置地图区域 center: \(region.center.latitude), \(region.center.longitude), span: 200m")
            print("🗺️ Coordinator: 当前地图中心: \(mapView.region.center.latitude), \(mapView.region.center.longitude)")

            // 只调用一次 setRegion，使用动画让效果更明显
            mapView.setRegion(region, animated: true)

            // 等待地图区域设置完成后再标记（延迟 0.5 秒确保生效）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.parent.hasLocatedUser = true
                print("🎯 Coordinator: 地图已自动居中，hasLocatedUser 设置为 true")
                print("🗺️ Coordinator: 居中后地图中心: \(mapView.region.center.latitude), \(mapView.region.center.longitude)")
            }
        }

        /// 地图区域改变时调用
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // 打印地图区域变化，用于调试居中是否生效
            print("🗺️ regionDidChange: 地图区域已改变到 center: \(mapView.region.center.latitude), \(mapView.region.center.longitude), animated: \(animated)")
        }

        /// 地图加载完成时调用
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            print("🗺️ 地图加载完成")
        }

        /// 地图加载失败时调用
        func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
            print("❌ 地图加载失败: \(error.localizedDescription)")
        }

        /// ⭐ 关键方法：渲染轨迹线和多边形（必须实现，否则不显示！）
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Day16: 渲染轨迹线（根据闭环状态变色）
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)

                // ⭐ Day16: 轨迹变色
                if parent.isPathClosed {
                    renderer.strokeColor = UIColor.systemGreen // 闭环：绿色轨迹
                    print("🎨 渲染轨迹线: 绿色（已闭环）, 宽度 5pt")
                } else {
                    renderer.strokeColor = UIColor.cyan // 未闭环：青色轨迹
                    print("🎨 渲染轨迹线: 青色（未闭环）, 宽度 5pt")
                }

                renderer.lineWidth = 5 // 线宽 5pt
                renderer.lineCap = .round // 圆头
                renderer.lineJoin = .round // 圆角连接

                return renderer
            }

            // Day16 & Day18: 渲染多边形填充
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)

                // Day18: 根据 title 区分颜色
                if polygon.title == "mine" {
                    // 自己的领地：绿色
                    renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.25)
                    renderer.strokeColor = UIColor.systemGreen
                } else if polygon.title == "others" {
                    // 他人的领地：橙色
                    renderer.fillColor = UIColor.systemOrange.withAlphaComponent(0.25)
                    renderer.strokeColor = UIColor.systemOrange
                } else {
                    // 当前圈地（tracking）或未标记：绿色
                    renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.25)
                    renderer.strokeColor = UIColor.systemGreen
                }

                renderer.lineWidth = 2.0

                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
