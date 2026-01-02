//
//  AuthManager.swift
//  earth Lord
//
//  Created by AI Assistant on 2026/01/01.
//

import Foundation
import Combine
import Supabase

// MARK: - 认证管理器
@MainActor
class AuthManager: ObservableObject {

    // MARK: - Published 属性

    /// 用户是否已完成认证（已登录且完成所有必需流程）
    @Published var isAuthenticated: Bool = false

    /// 是否需要设置密码（OTP验证后的强制步骤）
    @Published var needsPasswordSetup: Bool = false

    /// 当前用户信息
    @Published var currentUser: User? = nil

    /// 是否正在加载
    @Published var isLoading: Bool = false

    /// 错误信息
    @Published var errorMessage: String? = nil

    /// OTP 验证码是否已发送
    @Published var otpSent: Bool = false

    /// OTP 验证码是否已验证（等待设置密码）
    @Published var otpVerified: Bool = false

    // MARK: - 单例
    static let shared = AuthManager()

    // 认证状态监听任务
    private var authStateTask: Task<Void, Never>?

    private init() {
        // 启动时检查会话
        Task {
            await checkSession()
            // 启动认证状态监听
            await startAuthStateListener()
        }
    }

    deinit {
        // 取消监听任务
        authStateTask?.cancel()
    }

    // MARK: - 认证状态监听

    /// 监听认证状态变化
    private func startAuthStateListener() async {
        authStateTask = Task {
            for await (event, session) in await supabase.auth.authStateChanges {
                await handleAuthStateChange(event: event, session: session)
            }
        }
    }

    /// 处理认证状态变化
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) {
        print("🔄 认证状态变化: \(event)")

        switch event {
        case .signedIn:
            // 用户登录
            if let session = session {
                isAuthenticated = true
                needsPasswordSetup = false
                currentUser = User(
                    id: session.user.id.uuidString,
                    email: session.user.email,
                    createdAt: session.user.createdAt
                )
                print("✅ 用户已登录: \(session.user.email ?? "unknown")")
            }

        case .signedOut:
            // 用户登出
            isAuthenticated = false
            needsPasswordSetup = false
            currentUser = nil
            otpSent = false
            otpVerified = false
            print("👋 用户已登出")

        case .tokenRefreshed:
            // Token 刷新
            if let session = session {
                print("🔄 Token 已刷新")
                currentUser = User(
                    id: session.user.id.uuidString,
                    email: session.user.email,
                    createdAt: session.user.createdAt
                )
            }

        case .userUpdated:
            // 用户信息更新
            if let session = session {
                print("📝 用户信息已更新")
                currentUser = User(
                    id: session.user.id.uuidString,
                    email: session.user.email,
                    createdAt: session.user.createdAt
                )
            }

        default:
            print("ℹ️ 其他认证事件: \(event)")
        }
    }

    // MARK: - 注册流程

    /// 第一步：发送注册验证码
    /// - Parameter email: 用户邮箱
    func sendRegisterOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 发送 OTP 验证码（创建新用户）
            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true
            )

            otpSent = true
            print("✅ 注册验证码已发送到: \(email)")

        } catch {
            errorMessage = "发送验证码失败: \(error.localizedDescription)"
            print("❌ 发送注册验证码失败: \(error)")
        }

        isLoading = false
    }

    /// 第二步：验证注册验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 6位验证码
    /// - Note: 验证成功后用户已登录，但需要设置密码
    func verifyRegisterOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 验证 OTP（type 为 .email）
            let response = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )

            // 验证成功，用户已登录但未设置密码
            otpVerified = true
            needsPasswordSetup = true
            isAuthenticated = false // 必须设置密码后才算完成认证

            // 更新用户信息
            let supaUser = response.user
            currentUser = User(
                id: supaUser.id.uuidString,
                email: supaUser.email,
                createdAt: supaUser.createdAt
            )

            print("✅ 验证码验证成功，等待设置密码")

        } catch {
            errorMessage = "验证码验证失败: \(error.localizedDescription)"
            print("❌ 验证注册验证码失败: \(error)")
        }

        isLoading = false
    }

    /// 第三步：完成注册（设置密码）
    /// - Parameter password: 用户密码
    /// - Note: 注册流程的最后一步，完成后用户才算真正完成认证
    func completeRegistration(password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            try await supabase.auth.update(
                user: UserAttributes(password: password)
            )

            // 密码设置成功，完成注册流程
            needsPasswordSetup = false
            isAuthenticated = true

            print("✅ 注册完成，密码已设置")

        } catch {
            errorMessage = "设置密码失败: \(error.localizedDescription)"
            print("❌ 完成注册失败: \(error)")
        }

        isLoading = false
    }

    // MARK: - 登录

    /// 邮箱密码登录
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - password: 用户密码
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 使用邮箱和密码登录
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            // 登录成功
            isAuthenticated = true
            needsPasswordSetup = false

            // 更新用户信息
            let supaUser = response.user
            currentUser = User(
                id: supaUser.id.uuidString,
                email: supaUser.email,
                createdAt: supaUser.createdAt
            )

            print("✅ 登录成功: \(email)")

        } catch {
            errorMessage = "登录失败: \(error.localizedDescription)"
            print("❌ 登录失败: \(error)")
        }

        isLoading = false
    }

    // MARK: - 找回密码流程

    /// 第一步：发送密码重置验证码
    /// - Parameter email: 用户邮箱
    /// - Note: 这会触发 Supabase 的 Reset Password 邮件模板
    func sendResetOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 发送密码重置邮件
            try await supabase.auth.resetPasswordForEmail(email)

            otpSent = true
            print("✅ 密码重置验证码已发送到: \(email)")

        } catch {
            errorMessage = "发送重置验证码失败: \(error.localizedDescription)"
            print("❌ 发送密码重置验证码失败: \(error)")
        }

        isLoading = false
    }

    /// 第二步：验证密码重置验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 6位验证码
    /// - Note: ⚠️ 注意 type 是 .recovery 不是 .email
    func verifyResetOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 验证 OTP（type 为 .recovery，用于密码重置）
            let response = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .recovery  // ⚠️ 密码重置使用 .recovery 类型
            )

            // 验证成功，用户已登录，等待设置新密码
            otpVerified = true
            needsPasswordSetup = true
            isAuthenticated = false

            // 更新用户信息
            let supaUser = response.user
            currentUser = User(
                id: supaUser.id.uuidString,
                email: supaUser.email,
                createdAt: supaUser.createdAt
            )

            print("✅ 重置验证码验证成功，等待设置新密码")

        } catch {
            errorMessage = "验证码验证失败: \(error.localizedDescription)"
            print("❌ 验证重置验证码失败: \(error)")
        }

        isLoading = false
    }

    /// 第三步：设置新密码
    /// - Parameter newPassword: 新密码
    func resetPassword(newPassword: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            try await supabase.auth.update(
                user: UserAttributes(password: newPassword)
            )

            // 密码重置成功
            needsPasswordSetup = false
            isAuthenticated = true

            print("✅ 密码重置成功")

        } catch {
            errorMessage = "密码重置失败: \(error.localizedDescription)"
            print("❌ 重置密码失败: \(error)")
        }

        isLoading = false
    }

    // MARK: - 第三方登录（预留）

    /// Apple 登录
    /// - Note: TODO: 实现 Apple Sign In
    func signInWithApple() async {
        // TODO: 实现 Apple Sign In 集成
        print("⚠️ Apple Sign In 尚未实现")
        errorMessage = "Apple 登录功能开发中"
    }

    /// Google 登录
    /// - Note: TODO: 实现 Google Sign In
    func signInWithGoogle() async {
        // TODO: 实现 Google Sign In 集成
        print("⚠️ Google Sign In 尚未实现")
        errorMessage = "Google 登录功能开发中"
    }

    // MARK: - 其他方法

    /// 退出登录
    func signOut() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.signOut()

            // 清空状态
            isAuthenticated = false
            needsPasswordSetup = false
            currentUser = nil
            otpSent = false
            otpVerified = false

            print("✅ 已退出登录")

        } catch {
            errorMessage = "退出登录失败: \(error.localizedDescription)"
            print("❌ 退出登录失败: \(error)")
        }

        isLoading = false
    }

    /// 检查会话状态
    /// - Note: 应用启动时调用，检查是否有有效的会话
    func checkSession() async {
        do {
            // 获取当前会话
            let session = try await supabase.auth.session

            // 如果有会话，说明用户已登录
            isAuthenticated = true
            needsPasswordSetup = false

            // 更新用户信息
            currentUser = User(
                id: session.user.id.uuidString,
                email: session.user.email,
                createdAt: session.user.createdAt
            )

            print("✅ 检测到有效会话，用户已登录")

        } catch {
            // 没有有效会话，保持未登录状态
            isAuthenticated = false
            currentUser = nil
            print("ℹ️ 未检测到有效会话")
        }
    }
}
