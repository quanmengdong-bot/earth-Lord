//
//  ProfileTabView.swift
//  earth Lord
//
//  Created by AI Assistant on 2025/12/28.
//

import SwiftUI

struct ProfileTabView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showLogoutAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""

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

                    // 删除账户按钮
                    deleteAccountSection

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
        .alert("确认删除账户", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("⚠️ 此操作不可逆！删除后您的所有数据将永久丢失，且无法恢复。")
        }
        .alert("删除失败", isPresented: $showDeleteError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage)
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

    // MARK: - 删除账户区域
    private var deleteAccountSection: some View {
        Button(action: {
            print("👆 点击删除账户按钮")
            showDeleteConfirmation = true
        }) {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.headline)
                Text("删除账户")
                    .fontWeight(.semibold)
                Spacer()
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
            )
        }
    }

    // MARK: - 删除账户方法
    private func deleteAccount() async {
        print("👆 用户确认删除账户")

        do {
            try await authManager.deleteAccount()
            print("✅ 账户删除成功，自动返回登录页")
            // 成功后会自动返回登录页（因为 isAuthenticated = false）
        } catch {
            print("❌ 删除账户失败: \(error.localizedDescription)")
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
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
