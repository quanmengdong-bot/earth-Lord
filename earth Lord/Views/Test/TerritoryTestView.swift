//
//  TerritoryTestView.swift
//  earth Lord
//
//  圈地功能测试界面 - 显示实时日志
//

import SwiftUI

struct TerritoryTestView: View {

    // MARK: - State Properties

    /// 定位管理器（监听追踪状态）
    @ObservedObject private var locationManager = LocationManager.shared

    /// 日志管理器（监听日志更新）
    @ObservedObject private var logger = TerritoryLogger.shared

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 状态指示器
                statusIndicator
                    .padding(.vertical, 16)
                    .padding(.horizontal)
                    .background(ApocalypseTheme.cardBackground.opacity(0.5))

                Divider()
                    .background(ApocalypseTheme.textSecondary.opacity(0.3))

                // 日志滚动区域
                logScrollView
                    .padding(.vertical, 12)

                Divider()
                    .background(ApocalypseTheme.textSecondary.opacity(0.3))

                // 底部按钮
                actionButtons
                    .padding()
                    .background(ApocalypseTheme.cardBackground.opacity(0.5))
            }
        }
        .navigationTitle("圈地测试")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    /// 状态指示器
    private var statusIndicator: some View {
        HStack(spacing: 12) {
            // 状态圆点
            Circle()
                .fill(locationManager.isTracking ? Color.green : Color.gray)
                .frame(width: 12, height: 12)
                .shadow(color: locationManager.isTracking ? .green.opacity(0.5) : .clear, radius: 4)

            // 状态文字
            Text(locationManager.isTracking ? "追踪中" : "未追踪")
                .font(.headline)
                .foregroundColor(locationManager.isTracking ? .green : ApocalypseTheme.textSecondary)

            Spacer()

            // 路径点数
            if locationManager.isTracking {
                Text("\(locationManager.pathCoordinates.count) 个点")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
    }

    /// 日志滚动区域
    private var logScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(logger.logText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(ApocalypseTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .id("logBottom") // ⭐ 用于自动滚动
                }
            }
            .onChange(of: logger.logText) { _ in
                // 日志更新时自动滚动到底部
                withAnimation {
                    proxy.scrollTo("logBottom", anchor: .bottom)
                }
            }
        }
    }

    /// 底部按钮
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // 清空日志按钮
            Button(action: {
                logger.clear()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("清空日志")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(ApocalypseTheme.danger)
                .cornerRadius(8)
            }

            // 导出日志按钮
            ShareLink(item: logger.export()) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("导出日志")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(ApocalypseTheme.info)
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TerritoryTestView()
    }
}
