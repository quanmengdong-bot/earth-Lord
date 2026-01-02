//
//  ProfileTabView.swift
//  earth Lord
//
//  Created by AI Assistant on 2025/12/28.
//

import SwiftUI

struct ProfileTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 用户头像和信息
                    userInfoSection

                    // 功能菜单
                    menuSection

                    // 退出登录按钮
                    logoutSection

                    Spacer()
                }
                .padding()
            }
        }
        .alert("确认退出", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                Task {
                    await authManager.signOut()
                }
            }
        } message: {
            Text("确定要退出登录吗？")
        }
    }

    // MARK: - 用户信息区域
    private var userInfoSection: some View {
        VStack(spacing: 16) {
            // 头像
            Circle()
                .fill(
                    LinearGradient(
                        colors: [ApocalypseTheme.primary, ApocalypseTheme.warning],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                )
                .shadow(color: ApocalypseTheme.primary.opacity(0.3), radius: 10)

            // 邮箱
            if let email = authManager.currentUser?.email {
                Text(email)
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)
            }

            // 用户ID
            if let userId = authManager.currentUser?.id {
                Text("ID: \(userId.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - 菜单区域
    private var menuSection: some View {
        VStack(spacing: 0) {
            MenuRow(icon: "gearshape.fill", title: "设置", color: .gray)
            Divider().background(ApocalypseTheme.textSecondary.opacity(0.3))

            MenuRow(icon: "bell.fill", title: "通知", color: .blue)
            Divider().background(ApocalypseTheme.textSecondary.opacity(0.3))

            MenuRow(icon: "shield.fill", title: "隐私", color: .green)
            Divider().background(ApocalypseTheme.textSecondary.opacity(0.3))

            MenuRow(icon: "questionmark.circle.fill", title: "帮助", color: .orange)
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 退出登录区域
    private var logoutSection: some View {
        Button(action: {
            showLogoutAlert = true
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.headline)
                Text("退出登录")
                    .fontWeight(.semibold)
                Spacer()
            }
            .foregroundColor(.white)
            .padding()
            .background(ApocalypseTheme.danger)
            .cornerRadius(12)
        }
    }
}

// MARK: - 菜单行组件
struct MenuRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button(action: {
            // TODO: 实现菜单功能
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32)

                Text(title)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .padding()
        }
    }
}

#Preview {
    ProfileTabView()
}
