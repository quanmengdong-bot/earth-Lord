//
//  TerritoryDetailView.swift
//  earth Lord
//
//  领地详情页面 - Day18
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

    /// 是否显示删除确认
    @State private var showDeleteAlert = false

    /// 删除后的回调
    var onDelete: (() -> Void)?

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

                        // 占位功能区
                        futureFeatureCard
                            .padding(.horizontal)

                        // 路径点列表
                        pathPointsCard
                            .padding(.horizontal)

                        // 删除按钮
                        deleteButton
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(territory.displayName)
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
                        newName = territory.name ?? ""
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
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    Task {
                        let success = await territoryManager.deleteTerritory(territory)
                        if success {
                            onDelete?()
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("确定要删除「\(territory.displayName)」吗？\n此操作无法撤销。")
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
            TerritoryPolygonView(coordinates: territory.toCoordinates())
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

            infoRow(icon: "calendar", title: "创建时间", value: territory.formattedCreatedAt)

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

                    if let lat = point["lat"], let lon = point["lon"] {
                        Text(formatCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: lon)))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }

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

    /// 占位功能区
    private var futureFeatureCard: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(ApocalypseTheme.primary)
                Text("更多功能")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Spacer()
            }

            Divider()
                .background(ApocalypseTheme.textSecondary.opacity(0.3))

            // 占位功能
            futureFeatureRow(icon: "building.2", title: "建筑系统", description: "在领地上建造建筑")
            futureFeatureRow(icon: "arrow.triangle.swap", title: "领地交易", description: "与其他玩家交易领地")
            futureFeatureRow(icon: "shield.lefthalf.filled", title: "领地防御", description: "设置领地防御系统")
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    /// 占位功能行
    private func futureFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            Spacer()

            Text("敬请期待")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.warning)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ApocalypseTheme.warning.opacity(0.2))
                .cornerRadius(8)
        }
    }

    /// 删除按钮
    private var deleteButton: some View {
        Button(action: {
            showDeleteAlert = true
        }) {
            HStack {
                Image(systemName: "trash")
                Text("删除领地")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(ApocalypseTheme.danger)
            .cornerRadius(12)
        }
    }

    // MARK: - Helpers

    /// 中心坐标
    private var centerCoordinate: CLLocationCoordinate2D {
        let coordinates = territory.toCoordinates()
        guard !coordinates.isEmpty else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }

        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        let avgLat = latitudes.reduce(0, +) / Double(latitudes.count)
        let avgLon = longitudes.reduce(0, +) / Double(longitudes.count)

        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }

    /// 设置地图区域
    private func setupMapRegion() {
        let coordinates = territory.toCoordinates()

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
        id: "preview-id",
        userId: "preview-user",
        name: "测试领地",
        path: [
            ["lat": 31.23, "lon": 121.47],
            ["lat": 31.24, "lon": 121.47],
            ["lat": 31.24, "lon": 121.48],
            ["lat": 31.23, "lon": 121.48]
        ],
        area: 12500,
        pointCount: 4,
        isActive: true,
        completedAt: nil,
        startedAt: nil,
        createdAt: "2026-01-12T08:00:00.000Z"
    )

    TerritoryDetailView(territory: sampleTerritory)
}
