//
//  AuthManager.swift
//  earth Lord
//
//  Created by AI Assistant on 2026/01/01.
//

import Foundation
import Combine
import Supabase
#if canImport(GoogleSignIn)
import GoogleSignIn
import UIKit
#endif

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
            for await (event, session) in supabase.auth.authStateChanges {
                handleAuthStateChange(event: event, session: session)
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
                // 检查会话是否过期
                if session.isExpired {
                    print("⚠️ 会话已过期，需要重新登录")
                    isAuthenticated = false
                    needsPasswordSetup = false
                    currentUser = nil
                    return
                }

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
    /// - Note: 使用 Google Sign-In SDK 获取 ID Token，然后通过 Supabase OAuth 登录
    func signInWithGoogle() async {
        #if canImport(GoogleSignIn)
        print("🚀 开始 Google 登录流程...")
        isLoading = true
        errorMessage = nil

        do {
            // 1. 获取顶层视图控制器
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                print("❌ 无法获取根视图控制器")
                errorMessage = "无法初始化 Google 登录"
                isLoading = false
                return
            }

            print("📱 获取根视图控制器成功")

            // 2. 获取 Supabase 项目的 Google Client ID（从环境配置）
            // 注意：这里使用你在 Supabase 中配置的 Google OAuth Client ID
            guard let clientID = getGoogleClientID() else {
                print("❌ 未配置 Google Client ID")
                errorMessage = "Google 登录配置错误"
                isLoading = false
                return
            }

            print("🔑 Google Client ID 已配置")

            // 3. 配置 Google Sign-In
            let configuration = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = configuration

            print("⚙️ Google Sign-In 配置完成")

            // 4. 执行 Google 登录
            print("🔐 打开 Google 登录界面...")
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            print("✅ Google 登录成功，获取用户信息...")

            // 5. 获取 ID Token
            guard let idToken = result.user.idToken?.tokenString else {
                print("❌ 无法获取 Google ID Token")
                errorMessage = "Google 登录失败：无法获取凭证"
                isLoading = false
                return
            }

            print("🎫 获取 ID Token 成功")

            // 6. 使用 ID Token 通过 Supabase 登录
            print("🔄 使用 ID Token 登录 Supabase...")
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken
                )
            )

            // 7. 登录成功，更新状态
            isAuthenticated = true
            needsPasswordSetup = false

            // 更新用户信息
            currentUser = User(
                id: session.user.id.uuidString,
                email: session.user.email,
                createdAt: session.user.createdAt
            )

            print("✅ Google 登录完成！用户: \(session.user.email ?? "unknown")")

        } catch let error as NSError {
            // 处理用户取消登录的情况
            if error.domain == "com.google.GIDSignIn" && error.code == -5 {
                print("ℹ️ 用户取消了 Google 登录")
                errorMessage = nil // 不显示错误，用户主动取消
            } else {
                print("❌ Google 登录失败: \(error.localizedDescription)")
                errorMessage = "Google 登录失败: \(error.localizedDescription)"
            }
        }

        isLoading = false
        #else
        print("⚠️ GoogleSignIn SDK 未安装")
        errorMessage = "Google 登录功能需要安装 GoogleSignIn SDK"
        #endif
    }

    /// 获取 Google Client ID
    /// - Returns: Google OAuth Client ID
    /// - Note: 在实际项目中，应该从配置文件或环境变量中读取
    private func getGoogleClientID() -> String? {
        #if canImport(GoogleSignIn)
        // 方法 1: 从 Info.plist 读取（推荐）
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
            return clientID
        }

        // 方法 2: 从 Supabase 项目配置读取（如果你在 Supabase 中配置了 Google Provider）
        // 请替换为你在 Supabase Dashboard 中配置的 Google Client ID
        // 格式: "YOUR_CLIENT_ID.apps.googleusercontent.com"

        // TODO: 在这里填入你的 Google Client ID
        // return "YOUR_CLIENT_ID.apps.googleusercontent.com"

        return nil
        #else
        return nil
        #endif
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

            // 检查会话是否过期
            if session.isExpired {
                print("⚠️ 本地会话已过期，保持未登录状态")
                isAuthenticated = false
                needsPasswordSetup = false
                currentUser = nil
                return
            }

            // 如果有会话且未过期，说明用户已登录
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

    // MARK: - 删除账户

    /// 删除用户账户
    /// - Note: 这是一个不可逆操作，会永久删除用户数据
    func deleteAccount() async throws {
        print("🗑️ 开始删除账户流程...")
        isLoading = true
        errorMessage = nil

        do {
            // 1. 获取当前会话的访问令牌
            print("🔑 获取访问令牌...")
            let session = try await supabase.auth.session
            let accessToken = session.accessToken

            print("✅ 访问令牌已获取")

            // 2. 构建请求
            let functionUrl = URL(string: "https://uxkyrcyyuxtvgasqplua.supabase.co/functions/v1/delete-account")!
            var request = URLRequest(url: functionUrl)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            print("📡 发送删除请求到边缘函数...")

            // 3. 发送请求
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(
                    domain: "DeleteAccount",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "无效的响应"]
                )
            }

            // 4. 处理响应
            if httpResponse.statusCode == 200 {
                print("✅ 账户删除成功")

                // 解析响应
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📝 删除详情: \(json)")
                }

                // 清空本地状态
                print("🧹 清理本地状态...")
                isAuthenticated = false
                needsPasswordSetup = false
                currentUser = nil
                otpSent = false
                otpVerified = false

                print("✅ 账户删除流程完成")

            } else {
                // 解析错误信息
                var errorMsg = "删除账户失败"

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String {
                    errorMsg = error
                }

                print("❌ 删除账户失败 (HTTP \(httpResponse.statusCode)): \(errorMsg)")

                throw NSError(
                    domain: "DeleteAccount",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorMsg]
                )
            }

        } catch {
            print("❌ 删除账户异常: \(error.localizedDescription)")
            errorMessage = "删除账户失败: \(error.localizedDescription)"
            isLoading = false
            throw error
        }

        isLoading = false
    }
}
