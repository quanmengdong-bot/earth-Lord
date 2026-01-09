//
//  TerritoryDetailView.swift
//  earth Lord
//
//  领地详情页面 - Day17
//

import SwiftUI
import MapKit

struct TerritoryDetailView: View {

    // MARK: - Properties

    /// 领地数据
    let territory: Territory

    /// 领地管理器
    @ObservedObject private var territoryManager = TerritoryManager.shared

    /// 关闭页面
    @Environment(\.dismiss) private var dismiss

    /// 是否显示编辑名称对话框
    @State private var showEditNameDialog = false

    /// 新名称
    @State private var newName = ""

    /// 地图区域
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 地图预览
                        mapPreview
                            .frame(height: 250)
                            .cornerRadius(16)
                            .padding(.horizontal)

                        // 信息卡片
                        infoCard
                            .padding(.horizontal)

                        // 路径点列表
                        pathPointsCard
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(territory.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 关闭按钮
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(ApocalypseTheme.primary)
                }

                // 编辑按钮
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        newName = territory.name
                        showEditNameDialog = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(ApocalypseTheme.primary)
                    }
                }
            }
            .alert("编辑领地名称", isPresented: $showEditNameDialog) {
                TextField("领地名称", text: $newName)
                Button("取消", role: .cancel) {}
                Button("保存") {
                    Task {
                        await territoryManager.updateTerritoryName(territory, newName: newName)
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupMapRegion()
            }
        }
    }

    // MARK: - Subviews

    /// 地图预览
    private var mapPreview: some View {
        Map(coordinateRegion: .constant(mapRegion), annotationItems: [territory]) { t in
            MapAnnotation(coordinate: centerCoordinate) {
                // 中心标记
                Image(systemName: "flag.fill")
                    .foregroundColor(ApocalypseTheme.primary)
                    .font(.title)
            }
        }
        .overlay {
            // 绘制领地边界
            TerritoryPolygonView(coordinates: territory.path.asCoordinates)
        }
        .disabled(true) // 禁止地图交互
    }

    /// 信息卡片
    private var infoCard: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(ApocalypseTheme.primary)
                Text("领地信息")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Spacer()
            }

            Divider()
                .background(ApocalypseTheme.textSecondary.opacity(0.3))

            // 信息行
            infoRow(icon: "square.dashed", title: "面积", value: TerritoryManager.formatArea(territory.area))
            infoRow(icon: "point.topleft.down.to.point.bottomright.curvepath", title: "路径点数", value: "\(territory.path.count) 个")

            if let createdAt = territory.createdAt {
                infoRow(icon: "calendar", title: "创建时间", value: formatFullDate(createdAt))
            }

            // 中心坐标
            infoRow(icon: "location", title: "中心坐标", value: formatCoordinate(centerCoordinate))
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    /// 路径点卡片
    private var pathPointsCard: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .foregroundColor(ApocalypseTheme.primary)
                Text("路径坐标")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Spacer()

                Text("共 \(territory.path.count) 点")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            Divider()
                .background(ApocalypseTheme.textSecondary.opacity(0.3))

            // 路径点列表（最多显示10个）
            let displayPoints = Array(territory.path.prefix(10))
            ForEach(Array(displayPoints.enumerated()), id: \.offset) { index, point in
                HStack {
                    Text("#\(index + 1)")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.primary)
                        .frame(width: 30)

                    Text(formatCoordinate(point.coordinate))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    Spacer()
                }
            }

            if territory.path.count > 10 {
                Text("... 还有 \(territory.path.count - 10) 个点")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    /// 信息行
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textPrimary)
        }
    }

    // MARK: - Helpers

    /// 中心坐标
    private var centerCoordinate: CLLocationCoordinate2D {
        let latitudes = territory.path.map { $0.latitude }
        let longitudes = territory.path.map { $0.longitude }

        let avgLat = latitudes.reduce(0, +) / Double(latitudes.count)
        let avgLon = longitudes.reduce(0, +) / Double(longitudes.count)

        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }

    /// 设置地图区域
    private func setupMapRegion() {
        let coordinates = territory.path.map { $0.coordinate }

        guard !coordinates.isEmpty else { return }

        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5 + 0.002,
            longitudeDelta: (maxLon - minLon) * 1.5 + 0.002
        )

        mapRegion = MKCoordinateRegion(center: center, span: span)
    }

    /// 格式化完整日期
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// 格式化坐标
    private func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }
}

// MARK: - 领地多边形视图

struct TerritoryPolygonView: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        // 简化处理：地图预览中暂不绘制多边形
        // 地图本身会显示中心标记
        EmptyView()
    }
}

#Preview {
    let sampleTerritory = Territory(
        id: UUID(),
        userId: UUID(),
        name: "测试领地",
        path: [
            PathPoint(coordinate: CLLocationCoordinate2D(latitude: 31.23, longitude: 121.47)),
            PathPoint(coordinate: CLLocationCoordinate2D(latitude: 31.24, longitude: 121.47)),
            PathPoint(coordinate: CLLocationCoordinate2D(latitude: 31.24, longitude: 121.48)),
            PathPoint(coordinate: CLLocationCoordinate2D(latitude: 31.23, longitude: 121.48))
        ],
        area: 12500,
        createdAt: Date()
    )

    TerritoryDetailView(territory: sampleTerritory)
}
