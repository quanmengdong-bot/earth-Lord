//
//  AuthView.swift
//  earth Lord
//
//  Created by AI Assistant on 2026/01/01.
//

import SwiftUI

// MARK: - 认证页面（登录/注册整合）
struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared

    // Tab 选择
    @State private var selectedTab: AuthTab = .login

    // 登录表单
    @State private var loginEmail: String = ""
    @State private var loginPassword: String = ""

    // 注册表单
    @State private var registerEmail: String = ""
    @State private var otpCode: String = ""
    @State private var registerPassword: String = ""
    @State private var confirmPassword: String = ""

    // 忘记密码
    @State private var showForgotPassword: Bool = false
    @State private var resetEmail: String = ""
    @State private var resetOtpCode: String = ""
    @State private var resetPassword: String = ""
    @State private var resetConfirmPassword: String = ""
    @State private var resetStep: Int = 1

    // 倒计时
    @State private var resendTimer: Int = 0
    @State private var timer: Timer?

    // UI 状态
    @State private var showError: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""

    enum AuthTab {
        case login
        case register
    }

    var body: some View {
        ZStack {
            // 深色渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.10, green: 0.08, blue: 0.12),
                    Color(red: 0.08, green: 0.05, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    // Logo 和标题
                    logoSection

                    // Tab 切换
                    tabSelector

                    // 内容区域
                    if selectedTab == .login {
                        loginSection
                    } else {
                        registerSection
                    }

                    // 分隔线和第三方登录
                    dividerSection
                    thirdPartySection

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }

            // Toast 提示
            if showToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(12)
                        .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showToast)
            }
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "未知错误")
        }
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
        .onChange(of: authManager.errorMessage) {
            if authManager.errorMessage != nil {
                showError = true
            }
        }
        .onChange(of: selectedTab) {
            // 切换 Tab 时重置状态
            resetAuthState()
        }
    }

    // MARK: - Logo 区域
    private var logoSection: some View {
        VStack(spacing: 16) {
            // Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ApocalypseTheme.primary.opacity(0.3),
                                ApocalypseTheme.warning.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ApocalypseTheme.primary, ApocalypseTheme.warning],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // 标题
            Text("地球新主")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Earth Lord")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
    }

    // MARK: - Tab 切换器
    private var tabSelector: some View {
        HStack(spacing: 0) {
            // 登录 Tab
            Button(action: {
                withAnimation(.spring()) {
                    selectedTab = .login
                }
            }) {
                Text("登录")
                    .font(.headline)
                    .foregroundColor(selectedTab == .login ? .white : ApocalypseTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == .login ?
                        AnyView(ApocalypseTheme.primary.opacity(0.8)) :
                        AnyView(Color.clear)
                    )
                    .cornerRadius(12, corners: [.topLeft, .bottomLeft])
            }

            // 注册 Tab
            Button(action: {
                withAnimation(.spring()) {
                    selectedTab = .register
                }
            }) {
                Text("注册")
                    .font(.headline)
                    .foregroundColor(selectedTab == .register ? .white : ApocalypseTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == .register ?
                        AnyView(ApocalypseTheme.primary.opacity(0.8)) :
                        AnyView(Color.clear)
                    )
                    .cornerRadius(12, corners: [.topRight, .bottomRight])
            }
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ApocalypseTheme.textSecondary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - 登录区域
    private var loginSection: some View {
        VStack(spacing: 20) {
            // 邮箱输入框
            InputField(
                icon: "envelope.fill",
                placeholder: "请输入邮箱",
                text: $loginEmail,
                keyboardType: .emailAddress
            )

            // 密码输入框
            SecureInputField(
                icon: "lock.fill",
                placeholder: "请输入密码",
                text: $loginPassword
            )

            // 忘记密码链接
            HStack {
                Spacer()
                Button(action: {
                    showForgotPassword = true
                }) {
                    Text("忘记密码？")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.info)
                }
            }

            // 登录按钮
            PrimaryButton(
                title: "登录",
                icon: "arrow.right.circle.fill",
                isLoading: authManager.isLoading,
                isEnabled: !loginEmail.isEmpty && !loginPassword.isEmpty
            ) {
                Task {
                    await authManager.signIn(email: loginEmail, password: loginPassword)
                }
            }
        }
    }

    // MARK: - 注册区域
    private var registerSection: some View {
        VStack(spacing: 20) {
            // 根据注册状态显示不同步骤
            if !authManager.otpSent {
                // 第一步：输入邮箱
                registerStep1
            } else if authManager.otpSent && !authManager.otpVerified {
                // 第二步：验证 OTP
                registerStep2
            } else if authManager.otpVerified && authManager.needsPasswordSetup {
                // 第三步：设置密码
                registerStep3
            }
        }
    }

    // MARK: - 注册步骤1：输入邮箱
    private var registerStep1: some View {
        VStack(spacing: 20) {
            // 步骤提示
            StepIndicator(currentStep: 1, totalSteps: 3, title: "输入邮箱")

            // 邮箱输入框
            InputField(
                icon: "envelope.fill",
                placeholder: "请输入邮箱",
                text: $registerEmail,
                keyboardType: .emailAddress
            )

            // 发送验证码按钮
            PrimaryButton(
                title: "发送验证码",
                icon: "paperplane.fill",
                isLoading: authManager.isLoading,
                isEnabled: !registerEmail.isEmpty
            ) {
                Task {
                    await authManager.sendRegisterOTP(email: registerEmail)
                    if authManager.otpSent {
                        startResendTimer()
                    }
                }
            }
        }
    }

    // MARK: - 注册步骤2：验证 OTP
    private var registerStep2: some View {
        VStack(spacing: 20) {
            // 步骤提示
            StepIndicator(currentStep: 2, totalSteps: 3, title: "验证邮箱")

            // 提示文字
            VStack(spacing: 8) {
                Text("验证码已发送到")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                Text(registerEmail)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ApocalypseTheme.primary)
            }

            // 验证码输入框
            InputField(
                icon: "number.circle.fill",
                placeholder: "请输入6位验证码",
                text: $otpCode,
                keyboardType: .numberPad
            )

            // 验证按钮
            PrimaryButton(
                title: "验证",
                icon: "checkmark.circle.fill",
                isLoading: authManager.isLoading,
                isEnabled: otpCode.count == 6
            ) {
                Task {
                    await authManager.verifyRegisterOTP(email: registerEmail, code: otpCode)
                }
            }

            // 重新发送倒计时
            if resendTimer > 0 {
                Text("重新发送（\(resendTimer)秒）")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            } else {
                Button(action: {
                    Task {
                        await authManager.sendRegisterOTP(email: registerEmail)
                        if authManager.otpSent {
                            startResendTimer()
                        }
                    }
                }) {
                    Text("重新发送验证码")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.info)
                }
            }
        }
    }

    // MARK: - 注册步骤3：设置密码
    private var registerStep3: some View {
        VStack(spacing: 20) {
            // 步骤提示
            StepIndicator(currentStep: 3, totalSteps: 3, title: "设置密码")

            // 提示
            Text("邮箱验证成功！请设置您的登录密码")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.success)
                .multilineTextAlignment(.center)

            // 密码输入框
            SecureInputField(
                icon: "lock.fill",
                placeholder: "请输入密码（至少6位）",
                text: $registerPassword
            )

            // 确认密码输入框
            SecureInputField(
                icon: "lock.fill",
                placeholder: "请再次输入密码",
                text: $confirmPassword
            )

            // 密码强度提示
            if !registerPassword.isEmpty {
                PasswordStrengthIndicator(password: registerPassword)
            }

            // 密码匹配提示
            if !confirmPassword.isEmpty && registerPassword != confirmPassword {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ApocalypseTheme.danger)
                    Text("两次输入的密码不一致")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.danger)
                }
            }

            // 完成注册按钮
            PrimaryButton(
                title: "完成注册",
                icon: "checkmark.circle.fill",
                isLoading: authManager.isLoading,
                isEnabled: registerPassword.count >= 6 && registerPassword == confirmPassword
            ) {
                Task {
                    await authManager.completeRegistration(password: registerPassword)
                }
            }
        }
    }

    // MARK: - 分隔线
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(ApocalypseTheme.textSecondary.opacity(0.3))

            Text("或者使用以下方式登录")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Rectangle()
                .frame(height: 1)
                .foregroundColor(ApocalypseTheme.textSecondary.opacity(0.3))
        }
        .padding(.top, 20)
    }

    // MARK: - 第三方登录
    private var thirdPartySection: some View {
        VStack(spacing: 12) {
            // Apple 登录按钮
            ThirdPartyButton(
                icon: "apple.logo",
                title: "使用 Apple 登录",
                backgroundColor: .black,
                textColor: .white
            ) {
                showToastMessage("Apple 登录即将开放")
            }

            // Google 登录按钮
            ThirdPartyButton(
                icon: "globe",
                title: "使用 Google 登录",
                backgroundColor: .white,
                textColor: .black
            ) {
                showToastMessage("Google 登录即将开放")
            }
        }
    }

    // MARK: - 忘记密码弹窗
    private var forgotPasswordSheet: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 根据步骤显示内容
                        if resetStep == 1 {
                            forgotPasswordStep1
                        } else if resetStep == 2 {
                            forgotPasswordStep2
                        } else if resetStep == 3 {
                            forgotPasswordStep3
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("找回密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showForgotPassword = false
                        resetStep = 1
                        resetAuthState()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - 忘记密码步骤1
    private var forgotPasswordStep1: some View {
        VStack(spacing: 20) {
            StepIndicator(currentStep: 1, totalSteps: 3, title: "输入邮箱")

            InputField(
                icon: "envelope.fill",
                placeholder: "请输入注册邮箱",
                text: $resetEmail,
                keyboardType: .emailAddress
            )

            PrimaryButton(
                title: "发送验证码",
                icon: "paperplane.fill",
                isLoading: authManager.isLoading,
                isEnabled: !resetEmail.isEmpty
            ) {
                Task {
                    await authManager.sendResetOTP(email: resetEmail)
                    if authManager.otpSent {
                        resetStep = 2
                        startResendTimer()
                    }
                }
            }
        }
    }

    // MARK: - 忘记密码步骤2
    private var forgotPasswordStep2: some View {
        VStack(spacing: 20) {
            StepIndicator(currentStep: 2, totalSteps: 3, title: "验证邮箱")

            VStack(spacing: 8) {
                Text("验证码已发送到")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                Text(resetEmail)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ApocalypseTheme.warning)
            }

            InputField(
                icon: "number.circle.fill",
                placeholder: "请输入6位验证码",
                text: $resetOtpCode,
                keyboardType: .numberPad
            )

            PrimaryButton(
                title: "验证",
                icon: "checkmark.circle.fill",
                isLoading: authManager.isLoading,
                isEnabled: resetOtpCode.count == 6
            ) {
                Task {
                    await authManager.verifyResetOTP(email: resetEmail, code: resetOtpCode)
                    if authManager.otpVerified {
                        resetStep = 3
                    }
                }
            }

            if resendTimer > 0 {
                Text("重新发送（\(resendTimer)秒）")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            } else {
                Button(action: {
                    Task {
                        await authManager.sendResetOTP(email: resetEmail)
                        if authManager.otpSent {
                            startResendTimer()
                        }
                    }
                }) {
                    Text("重新发送验证码")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.info)
                }
            }
        }
    }

    // MARK: - 忘记密码步骤3
    private var forgotPasswordStep3: some View {
        VStack(spacing: 20) {
            StepIndicator(currentStep: 3, totalSteps: 3, title: "设置新密码")

            SecureInputField(
                icon: "lock.fill",
                placeholder: "请输入新密码（至少6位）",
                text: $resetPassword
            )

            SecureInputField(
                icon: "lock.fill",
                placeholder: "请再次输入新密码",
                text: $resetConfirmPassword
            )

            if !resetPassword.isEmpty {
                PasswordStrengthIndicator(password: resetPassword)
            }

            if !resetConfirmPassword.isEmpty && resetPassword != resetConfirmPassword {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ApocalypseTheme.danger)
                    Text("两次输入的密码不一致")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.danger)
                }
            }

            PrimaryButton(
                title: "重置密码",
                icon: "checkmark.circle.fill",
                isLoading: authManager.isLoading,
                isEnabled: resetPassword.count >= 6 && resetPassword == resetConfirmPassword
            ) {
                Task {
                    await authManager.resetPassword(newPassword: resetPassword)
                    if authManager.isAuthenticated {
                        showForgotPassword = false
                        resetStep = 1
                        showToastMessage("密码重置成功")
                    }
                }
            }
        }
    }

    // MARK: - 辅助方法
    private func startResendTimer() {
        resendTimer = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if resendTimer > 0 {
                resendTimer -= 1
            } else {
                timer?.invalidate()
            }
        }
    }

    private func resetAuthState() {
        // 清空表单
        loginEmail = ""
        loginPassword = ""
        registerEmail = ""
        otpCode = ""
        registerPassword = ""
        confirmPassword = ""
        resetEmail = ""
        resetOtpCode = ""
        resetPassword = ""
        resetConfirmPassword = ""

        // 停止倒计时
        timer?.invalidate()
        resendTimer = 0
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// MARK: - 输入框组件
struct InputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .keyboardType(keyboardType)
                .foregroundColor(.white)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground.opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ApocalypseTheme.textSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 密码输入框组件
struct SecureInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 24)

            SecureField(placeholder, text: $text)
                .foregroundColor(.white)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground.opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ApocalypseTheme.textSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 主按钮组件
struct PrimaryButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: icon)
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isEnabled ?
                LinearGradient(
                    colors: [ApocalypseTheme.primary, ApocalypseTheme.primaryDark],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [ApocalypseTheme.textSecondary.opacity(0.3), ApocalypseTheme.textSecondary.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - 第三方登录按钮
struct ThirdPartyButton: View {
    let icon: String
    let title: String
    let backgroundColor: Color
    let textColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(textColor.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - 步骤指示器
struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            // 步骤圆点
            HStack(spacing: 12) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary.opacity(0.3))
                        .frame(width: 10, height: 10)

                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }

            // 标题
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

// MARK: - 密码强度指示器
struct PasswordStrengthIndicator: View {
    let password: String

    var strength: (color: Color, text: String, icon: String) {
        if password.count < 6 {
            return (ApocalypseTheme.danger, "密码至少需要6位", "xmark.circle.fill")
        } else if password.count < 8 {
            return (ApocalypseTheme.warning, "密码强度：中等", "checkmark.circle.fill")
        } else {
            return (ApocalypseTheme.success, "密码强度：强", "checkmark.circle.fill")
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: strength.icon)
                .foregroundColor(strength.color)
            Text(strength.text)
                .font(.caption)
                .foregroundColor(strength.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    AuthView()
}
