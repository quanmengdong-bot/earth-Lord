//
//  LoginView.swift
//  earth Lord
//
//  Created by AI Assistant on 2026/01/01.
//

import SwiftUI

// MARK: - 登录页面
struct LoginView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showRegister: Bool = false
    @State private var showForgotPassword: Bool = false
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 60)

                        // Logo 区域
                        logoSection

                        // 登录表单
                        loginForm

                        // 忘记密码
                        forgotPasswordButton

                        // 分割线
                        dividerSection

                        // 注册按钮
                        registerButton

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .alert("登录失败", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(authManager.errorMessage ?? "未知错误")
            }
            .onChange(of: authManager.errorMessage) { _ in
                if authManager.errorMessage != nil {
                    showError = true
                }
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    // MARK: - Logo 区域
    private var logoSection: some View {
        VStack(spacing: 16) {
            // 游戏图标
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ApocalypseTheme.primary, ApocalypseTheme.warning],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: ApocalypseTheme.primary.opacity(0.5), radius: 20)

            Text("Earth Lord")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text("征服末日世界")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .padding(.bottom, 20)
    }

    // MARK: - 登录表单
    private var loginForm: some View {
        VStack(spacing: 16) {
            // 邮箱输入
            VStack(alignment: .leading, spacing: 8) {
                Text("邮箱")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    TextField("请输入邮箱", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
                .padding()
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ApocalypseTheme.textSecondary.opacity(0.2), lineWidth: 1)
                )
            }

            // 密码输入
            VStack(alignment: .leading, spacing: 8) {
                Text("密码")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    SecureField("请输入密码", text: $password)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
                .padding()
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ApocalypseTheme.textSecondary.opacity(0.2), lineWidth: 1)
                )
            }

            // 登录按钮
            Button(action: login) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("登录")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [ApocalypseTheme.primary, ApocalypseTheme.primaryDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: ApocalypseTheme.primary.opacity(0.3), radius: 10, y: 5)
            }
            .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
            .opacity((email.isEmpty || password.isEmpty || authManager.isLoading) ? 0.6 : 1.0)
            .padding(.top, 8)
        }
    }

    // MARK: - 忘记密码按钮
    private var forgotPasswordButton: some View {
        Button(action: {
            showForgotPassword = true
        }) {
            Text("忘记密码？")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.info)
        }
    }

    // MARK: - 分割线
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(ApocalypseTheme.textSecondary.opacity(0.3))

            Text("或")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Rectangle()
                .frame(height: 1)
                .foregroundColor(ApocalypseTheme.textSecondary.opacity(0.3))
        }
    }

    // MARK: - 注册按钮
    private var registerButton: some View {
        Button(action: {
            showRegister = true
        }) {
            HStack {
                Image(systemName: "person.badge.plus.fill")
                Text("创建新账号")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(ApocalypseTheme.cardBackground)
            .foregroundColor(ApocalypseTheme.primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ApocalypseTheme.primary, lineWidth: 2)
            )
        }
    }

    // MARK: - 登录方法
    private func login() {
        Task {
            await authManager.signIn(email: email, password: password)
        }
    }
}

#Preview {
    LoginView()
}
