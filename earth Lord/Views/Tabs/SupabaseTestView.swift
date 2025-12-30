//
//  SupabaseTestView.swift
//  earth Lord
//
//  Created by AI Assistant on 2025/12/29.
//

import SwiftUI
import Supabase

// MARK: - Supabase Client 初始化
let supabaseURL = "https://uxkyrcyyuxtvgasqplua.supabase.co"
let supabaseKey = "sb_publishable_m3zrsYu4axfZhCo6RD-bKw_mNsd8Nq9"

let supabase = SupabaseClient(
    supabaseURL: URL(string: supabaseURL)!,
    supabaseKey: supabaseKey
)

// MARK: - 测试状态枚举
enum ConnectionStatus {
    case idle
    case testing
    case success
    case failure

    var icon: String {
        switch self {
        case .idle: return "circle"
        case .testing: return "arrow.triangle.2.circlepath"
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .idle: return .gray
        case .testing: return .blue
        case .success: return .green
        case .failure: return .red
        }
    }
}

// MARK: - Supabase 测试视图
struct SupabaseTestView: View {
    @State private var status: ConnectionStatus = .idle
    @State private var logMessages: [String] = []
    @State private var isRotating = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 顶部标题
                Text("Supabase 连接测试")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .padding(.top, 40)

                // 状态图标
                Image(systemName: status.icon)
                    .font(.system(size: 80))
                    .foregroundColor(status.color)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(
                        status == .testing ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default,
                        value: isRotating
                    )
                    .padding(.vertical, 20)

                // 日志显示框
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(logMessages.enumerated()), id: \.offset) { index, message in
                                Text(message)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(ApocalypseTheme.textSecondary)
                                    .id(index)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .onChange(of: logMessages.count) {
                            if let lastIndex = logMessages.indices.last {
                                withAnimation {
                                    proxy.scrollTo(lastIndex, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .frame(height: 200)
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                // 测试按钮
                Button(action: {
                    testConnection()
                }) {
                    HStack {
                        Image(systemName: "network")
                        Text("测试连接")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ApocalypseTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(status == .testing)
                .opacity(status == .testing ? 0.6 : 1.0)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - 测试连接方法
    private func testConnection() {
        // 重置状态
        status = .testing
        isRotating = true
        logMessages = []

        addLog("🔄 开始测试连接...")
        addLog("📡 Supabase URL: \(supabaseURL)")
        addLog("🔑 使用 Publishable Key")
        addLog("⏳ 发送测试请求...")

        Task {
            do {
                // 故意查询一个不存在的表来测试连接
                addLog("📤 查询不存在的表: non_existent_table")

                let _: [String] = try await supabase
                    .from("non_existent_table")
                    .select()
                    .execute()
                    .value

                // 如果没有报错（理论上不会执行到这里）
                await MainActor.run {
                    status = .success
                    isRotating = false
                    addLog("✅ 连接成功！")
                }

            } catch {
                await MainActor.run {
                    handleError(error)
                    isRotating = false
                }
            }
        }
    }

    // MARK: - 错误处理
    private func handleError(_ error: Error) {
        let errorDescription = error.localizedDescription

        addLog("⚠️ 收到错误响应:")
        addLog("   \(errorDescription)")

        // 判断错误类型
        if errorDescription.contains("PGRST") ||
           errorDescription.contains("PGRST205") ||
           errorDescription.contains("Could not find the table") ||
           errorDescription.contains("relation") && errorDescription.contains("does not exist") {
            // 收到 PostgreSQL 错误 = 连接成功
            status = .success
            addLog("✅ 连接成功！")
            addLog("✅ 服务器已响应（表不存在是预期行为）")
            addLog("✅ Supabase 配置正确")

        } else if errorDescription.contains("hostname") ||
                  errorDescription.contains("URL") ||
                  errorDescription.contains("NSURLErrorDomain") ||
                  errorDescription.contains("network") ||
                  errorDescription.contains("Internet") {
            // 网络或 URL 错误
            status = .failure
            addLog("❌ 连接失败：URL 错误或无网络")
            addLog("💡 请检查:")
            addLog("   1. Supabase URL 是否正确")
            addLog("   2. 网络连接是否正常")
            addLog("   3. Supabase 项目是否已启动")

        } else {
            // 其他未知错误
            status = .failure
            addLog("❌ 连接失败：未知错误")
            addLog("📋 错误详情:")
            addLog("   \(errorDescription)")
        }
    }

    // MARK: - 添加日志
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logMessages.append("[\(timestamp)] \(message)")
    }
}

#Preview {
    SupabaseTestView()
}
