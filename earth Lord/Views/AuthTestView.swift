//
//  AuthTestView.swift
//  earth Lord
//
//  Created by AI Assistant on 2026/01/01.
//

import SwiftUI

// MARK: - 认证功能测试视图
struct AuthTestView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @State private var email: String = ""
    @State private var otpCode: String = ""
    @State private var password: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 标题
                    Text("认证功能测试")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                        .padding(.top, 40)

                    // 状态显示
                    statusSection

                    // 输入区域
                    inputSection

                    // 注册流程按钮
                    registrationSection

                    // 登录按钮
                    loginSection

                    // 密码重置流程
                    resetPasswordSection

                    // 退出按钮
                    if authManager.isAuthenticated {
                        signOutSection
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: authManager.errorMessage) {
            if let error = authManager.errorMessage {
                alertMessage = error
                showAlert = true
            }
        }
    }

    // MARK: - 状态显示区域
    private var statusSection: some View {
        VStack(spacing: 12) {
            StatusRow(title: "已登录", value: authManager.isAuthenticated)
            StatusRow(title: "需要设置密码", value: authManager.needsPasswordSetup)
            StatusRow(title: "OTP已发送", value: authManager.otpSent)
            StatusRow(title: "OTP已验证", value: authManager.otpVerified)

            if let user = authManager.currentUser {
                HStack {
                    Text("当前用户:")
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text(user.email ?? "无邮箱")
                        .foregroundColor(ApocalypseTheme.primary)
                        .fontWeight(.medium)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 输入区域
    private var inputSection: some View {
        VStack(spacing: 16) {
            // 邮箱输入
            VStack(alignment: .leading, spacing: 4) {
                Text("邮箱")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                TextField("请输入邮箱", text: $email)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }

            // OTP 输入
            if authManager.otpSent && !authManager.otpVerified {
                VStack(alignment: .leading, spacing: 4) {
                    Text("验证码")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    TextField("请输入6位验证码", text: $otpCode)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                }
            }

            // 密码输入
            if authManager.needsPasswordSetup || (!authManager.isAuthenticated && !authManager.otpSent) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("密码")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    SecureField("请输入密码", text: $password)
                        .textFieldStyle(CustomTextFieldStyle())
                }
            }
        }
    }

    // MARK: - 注册流程区域
    private var registrationSection: some View {
        VStack(spacing: 12) {
            Text("注册流程")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 步骤1: 发送注册验证码
            if !authManager.otpSent {
                Button(action: {
                    Task {
                        await authManager.sendRegisterOTP(email: email)
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("1. 发送注册验证码")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ApocalypseTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(email.isEmpty || authManager.isLoading)
            }

            // 步骤2: 验证OTP
            if authManager.otpSent && !authManager.otpVerified {
                Button(action: {
                    Task {
                        await authManager.verifyRegisterOTP(email: email, code: otpCode)
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                        Text("2. 验证验证码")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ApocalypseTheme.info)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(otpCode.isEmpty || authManager.isLoading)
            }

            // 步骤3: 设置密码完成注册
            if authManager.needsPasswordSetup && authManager.otpVerified {
                Button(action: {
                    Task {
                        await authManager.completeRegistration(password: password)
                        if authManager.isAuthenticated {
                            alertMessage = "✅ 注册成功！"
                            showAlert = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "key.fill")
                        Text("3. 设置密码完成注册")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ApocalypseTheme.warning)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(password.isEmpty || authManager.isLoading)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground.opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - 登录区域
    private var loginSection: some View {
        VStack(spacing: 12) {
            Text("直接登录")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Button(action: {
                Task {
                    await authManager.signIn(email: email, password: password)
                    if authManager.isAuthenticated {
                        alertMessage = "✅ 登录成功！"
                        showAlert = true
                    }
                }
            }) {
                HStack {
                    Image(systemName: "person.fill")
                    Text("邮箱密码登录")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground.opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - 密码重置区域
    private var resetPasswordSection: some View {
        VStack(spacing: 12) {
            Text("找回密码")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Button(action: {
                Task {
                    await authManager.sendResetOTP(email: email)
                }
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("发送密码重置验证码")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(email.isEmpty || authManager.isLoading)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground.opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - 退出登录区域
    private var signOutSection: some View {
        Button(action: {
            Task {
                await authManager.signOut()
                // 清空输入
                email = ""
                otpCode = ""
                password = ""
                alertMessage = "✅ 已退出登录"
                showAlert = true
            }
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("退出登录")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(authManager.isLoading)
    }
}

// MARK: - 状态行组件
struct StatusRow: View {
    let title: String
    let value: Bool

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
            Image(systemName: value ? "checkmark.circle.fill" : "circle")
                .foregroundColor(value ? .green : .gray)
        }
        .font(.caption)
    }
}

// MARK: - 自定义文本框样式
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ApocalypseTheme.textSecondary.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    AuthTestView()
}
