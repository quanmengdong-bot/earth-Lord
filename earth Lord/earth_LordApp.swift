//
//  earth_LordApp.swift
//  earth Lord
//
//  Created by 富尔喜悦的孟冬 on 2025/12/24.
//

import SwiftUI

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
                } else {
                    // 根据认证状态显示不同页面
                    if authManager.isAuthenticated {
                        // 已登录 → 显示主页面
                        ContentView()
                            .transition(.opacity)
                    } else {
                        // 未登录 → 显示认证页面
                        AuthView()
                            .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSplash)
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        }
    }
}
