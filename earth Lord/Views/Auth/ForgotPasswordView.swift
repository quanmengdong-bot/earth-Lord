//
//  ForgotPasswordView.swift
//  earth Lord
//
//  Created by AI Assistant on 2026/01/01.
//

import SwiftUI

// MARK: - 忘记密码页面
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared

    @State private var email: String = ""
    @State private var otpCode: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false

    enum ResetStep {
        case inputEmail
        case verifyOTP
        case setNewPassword
    }

    @State private var currentStep: ResetStep = .inputEmail

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // 进度指示器
                    progressIndicator

                    // 标题
                    headerSection

                    // 根据步骤显示内容
                    switch currentStep {
                    case .inputEmail:
                        emailInputSection
                    case .verifyOTP:
                        otpVerifySection
                    case .setNewPassword:
                        passwordResetSection
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
        .alert("密码重置成功", isPresented: $showSuccess) {
            Button("返回登录") {
                dismiss()
            }
        } message: {
            Text("您的密码已成功重置，请使用新密码登录")
        }
        .onChange(of: authManager.errorMessage) {
            if let error = authManager.errorMessage {
                errorMessage = error
                showError = true
            }
        }
        .onChange(of: authManager.otpSent) {
            if authManager.otpSent && currentStep == .inputEmail {
                currentStep = .verifyOTP
            }
        }
        .onChange(of: authManager.otpVerified) {
            if authManager.otpVerified {
                currentStep = .setNewPassword
            }
        }
        .onChange(of: authManager.isAuthenticated) {
            if authManager.isAuthenticated && currentStep == .setNewPassword {
                showSuccess = true
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
        case .setNewPassword: currentStepNumber = 3
        }

        return step <= currentStepNumber ? ApocalypseTheme.warning : ApocalypseTheme.textSecondary.opacity(0.3)
    }

    // MARK: - 标题区域
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: stepIcon)
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.warning)
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
        case .setNewPassword: return "lock.rotation"
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case .inputEmail: return "找回密码"
        case .verifyOTP: return "验证身份"
        case .setNewPassword: return "重置密码"
        }
    }

    private var stepDescription: String {
        switch currentStep {
        case .inputEmail: return "输入您的邮箱地址，我们将发送验证码"
        case .verifyOTP: return "请输入发送到您邮箱的 6 位验证码"
        case .setNewPassword: return "设置一个新的密码"
        }
    }

    // MARK: - 步骤1：输入邮箱
    private var emailInputSection: some View {
        VStack(spacing: 20) {
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

            Button(action: sendResetOTP) {
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
                .background(ApocalypseTheme.warning)
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
            Text("验证码已发送到")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Text(email)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ApocalypseTheme.warning)
                .padding(.bottom, 8)

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

            Button(action: verifyResetOTP) {
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

            Button(action: sendResetOTP) {
                Text("没收到验证码？重新发送")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .disabled(authManager.isLoading)
        }
    }

    // MARK: - 步骤3：设置新密码
    private var passwordResetSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("新密码")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    SecureField("至少 6 位字符", text: $newPassword)
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

            VStack(alignment: .leading, spacing: 8) {
                Text("确认新密码")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    SecureField("再次输入新密码", text: $confirmPassword)
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

            if !newPassword.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: passwordStrengthIcon)
                        .foregroundColor(passwordStrengthColor)
                    Text(passwordStrengthText)
                        .font(.caption)
                        .foregroundColor(passwordStrengthColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: resetPassword) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("重置密码")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ApocalypseTheme.success)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canResetPassword || authManager.isLoading)
            .opacity((!canResetPassword || authManager.isLoading) ? 0.6 : 1.0)
        }
    }

    // MARK: - 密码验证
    private var passwordsMatch: Bool {
        !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword == confirmPassword
    }

    private var canResetPassword: Bool {
        newPassword.count >= 6 && passwordsMatch
    }

    private var passwordStrengthIcon: String {
        if newPassword.count < 6 { return "xmark.circle.fill" }
        if newPassword.count < 8 { return "checkmark.circle.fill" }
        return "checkmark.circle.fill"
    }

    private var passwordStrengthColor: Color {
        if newPassword.count < 6 { return ApocalypseTheme.danger }
        if newPassword.count < 8 { return ApocalypseTheme.warning }
        return ApocalypseTheme.success
    }

    private var passwordStrengthText: String {
        if newPassword.count < 6 { return "密码至少需要 6 位字符" }
        if newPassword.count < 8 { return "密码强度：中等" }
        return "密码强度：强"
    }

    // MARK: - 方法
    private func sendResetOTP() {
        Task {
            await authManager.sendResetOTP(email: email)
        }
    }

    private func verifyResetOTP() {
        Task {
            await authManager.verifyResetOTP(email: email, code: otpCode)
        }
    }

    private func resetPassword() {
        guard passwordsMatch else {
            errorMessage = "两次输入的密码不一致"
            showError = true
            return
        }

        Task {
            await authManager.resetPassword(newPassword: newPassword)
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
