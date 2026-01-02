//
//  earth_LordApp.swift
//  earth Lord
//
//  Created by 富尔喜悦的孟冬 on 2025/12/24.
//

import SwiftUI
import GoogleSignIn

@main
struct earth_LordApp: App {
    @StateObject private var authManager = AuthManager.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    // 启动画面
                    SplashView(isFinished: $showSplash)
                        .transition(.opacity)
                        .onAppear {
                            print("📱 显示启动画面")
                        }
                } else {
                    // 根据认证状态显示不同页面
                    if authManager.isAuthenticated {
                        // 已登录 → 显示主页面
                        ContentView()
                            .transition(.opacity)
                            .onAppear {
                                print("🏠 显示主页面（已登录）")
                            }
                    } else {
                        // 未登录 → 显示认证页面
                        AuthView()
                            .transition(.opacity)
                            .onAppear {
                                print("🔐 显示认证页面（未登录）")
                            }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSplash)
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
            .onChange(of: showSplash) { oldValue, newValue in
                print("🔄 showSplash 状态变化: \(oldValue) → \(newValue)")
            }
            .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
                print("🔄 isAuthenticated 状态变化: \(oldValue) → \(newValue)")
            }
            // 处理 Google Sign-In 的 URL 回调
            .onOpenURL { url in
                print("📲 收到 URL 回调: \(url.absoluteString)")
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
