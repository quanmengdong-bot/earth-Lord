//
//  RegisterView.swift
//  earth Lord
//
//  Created by AI Assistant on 2026/01/01.
//

import SwiftUI

// MARK: - 注册页面
struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared

    @State private var email: String = ""
    @State private var otpCode: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // 注册步骤
    enum RegisterStep {
        case inputEmail      // 输入邮箱
        case verifyOTP       // 验证验证码
        case setPassword     // 设置密码
    }

    @State private var currentStep: RegisterStep = .inputEmail

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // 顶部进度指示
                    progressIndicator

                    // 标题
                    headerSection

                    // 根据步骤显示不同内容
                    switch currentStep {
                    case .inputEmail:
                        emailInputSection
                    case .verifyOTP:
                        otpVerifySection
                    case .setPassword:
                        passwordSetupSection
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
        }
        .navigationBarBackButtonHidden(authManager.isLoading)
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: authManager.errorMessage) {
            if let error = authManager.errorMessage {
                errorMessage = error
                showError = true
            }
        }
        .onChange(of: authManager.otpSent) {
            if authManager.otpSent {
                currentStep = .verifyOTP
            }
        }
        .onChange(of: authManager.otpVerified) {
            if authManager.otpVerified {
                currentStep = .setPassword
            }
        }
        .onChange(of: authManager.isAuthenticated) {
            if authManager.isAuthenticated {
                // 注册成功，返回
                dismiss()
            }
        }
    }

    // MARK: - 进度指示器
    private var progressIndicator: some View {
        HStack(spacing: 12) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(stepColor(for: step))
                    .frame(width: 12, height: 12)

                if step < 3 {
                    Rectangle()
                        .fill(stepColor(for: step))
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal)
    }

    private func stepColor(for step: Int) -> Color {
        let currentStepNumber: Int
        switch currentStep {
        case .inputEmail: currentStepNumber = 1
        case .verifyOTP: currentStepNumber = 2
        case .setPassword: currentStepNumber = 3
        }

        return step <= currentStepNumber ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary.opacity(0.3)
    }

    // MARK: - 标题区域
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: stepIcon)
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.primary)
                .padding(.bottom, 8)

            Text(stepTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text(stepDescription)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var stepIcon: String {
        switch currentStep {
        case .inputEmail: return "envelope.circle.fill"
        case .verifyOTP: return "checkmark.shield.fill"
        case .setPassword: return "key.fill"
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case .inputEmail: return "创建账号"
        case .verifyOTP: return "验证邮箱"
        case .setPassword: return "设置密码"
        }
    }

    private var stepDescription: String {
        switch currentStep {
        case .inputEmail: return "输入您的邮箱地址，我们将发送验证码"
        case .verifyOTP: return "请输入发送到您邮箱的 6 位验证码"
        case .setPassword: return "设置一个安全的密码来保护您的账号"
        }
    }

    // MARK: - 步骤1：输入邮箱
    private var emailInputSection: some View {
        VStack(spacing: 20) {
            // 邮箱输入框
            VStack(alignment: .leading, spacing: 8) {
                Text("邮箱地址")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    TextField("your@email.com", text: $email)
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

            // 发送验证码按钮
            Button(action: sendOTP) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("发送验证码")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ApocalypseTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(email.isEmpty || authManager.isLoading)
            .opacity((email.isEmpty || authManager.isLoading) ? 0.6 : 1.0)
        }
    }

    // MARK: - 步骤2：验证OTP
    private var otpVerifySection: some View {
        VStack(spacing: 20) {
            // 显示发送到的邮箱
            Text("验证码已发送到")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Text(email)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ApocalypseTheme.primary)
                .padding(.bottom, 8)

            // 验证码输入框
            VStack(alignment: .leading, spacing: 8) {
                Text("验证码")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                HStack {
                    Image(systemName: "number.circle.fill")
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    TextField("6位数字", text: $otpCode)
                        .keyboardType(.numberPad)
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

            // 验证按钮
            Button(action: verifyOTP) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("验证")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ApocalypseTheme.info)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(otpCode.count != 6 || authManager.isLoading)
            .opacity((otpCode.count != 6 || authManager.isLoading) ? 0.6 : 1.0)

            // 重新发送
            Button(action: sendOTP) {
                Text("没收到验证码？重新发送")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .disabled(authManager.isLoading)
        }
    }

    // MARK: - 步骤3：设置密码
    private var passwordSetupSection: some View {
        VStack(spacing: 20) {
            // 密码输入框
            VStack(alignment: .leading, spacing: 8) {
                Text("密码")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    SecureField("至少 6 位字符", text: $password)
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

            // 确认密码输入框
            VStack(alignment: .leading, spacing: 8) {
                Text("确认密码")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    SecureField("再次输入密码", text: $confirmPassword)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
                .padding()
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(passwordsMatch ? ApocalypseTheme.success.opacity(0.5) : ApocalypseTheme.textSecondary.opacity(0.2), lineWidth: 1)
                )
            }

            // 密码强度提示
            if !password.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: passwordStrengthIcon)
                        .foregroundColor(passwordStrengthColor)
                    Text(passwordStrengthText)
                        .font(.caption)
                        .foregroundColor(passwordStrengthColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 完成注册按钮
            Button(action: completeRegistration) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("完成注册")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ApocalypseTheme.success)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canCompleteRegistration || authManager.isLoading)
            .opacity((!canCompleteRegistration || authManager.isLoading) ? 0.6 : 1.0)
        }
    }

    // MARK: - 密码验证
    private var passwordsMatch: Bool {
        !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }

    private var canCompleteRegistration: Bool {
        password.count >= 6 && passwordsMatch
    }

    private var passwordStrengthIcon: String {
        if password.count < 6 { return "xmark.circle.fill" }
        if password.count < 8 { return "checkmark.circle.fill" }
        return "checkmark.circle.fill"
    }

    private var passwordStrengthColor: Color {
        if password.count < 6 { return ApocalypseTheme.danger }
        if password.count < 8 { return ApocalypseTheme.warning }
        return ApocalypseTheme.success
    }

    private var passwordStrengthText: String {
        if password.count < 6 { return "密码至少需要 6 位字符" }
        if password.count < 8 { return "密码强度：中等" }
        return "密码强度：强"
    }

    // MARK: - 方法
    private func sendOTP() {
        Task {
            await authManager.sendRegisterOTP(email: email)
        }
    }

    private func verifyOTP() {
        Task {
            await authManager.verifyRegisterOTP(email: email, code: otpCode)
        }
    }

    private func completeRegistration() {
        guard passwordsMatch else {
            errorMessage = "两次输入的密码不一致"
            showError = true
            return
        }

        Task {
            await authManager.completeRegistration(password: password)
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
    }
}
