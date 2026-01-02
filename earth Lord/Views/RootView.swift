//
//  RootView.swift
//  earth Lord
//
//  Created by AI Assistant on 2025/12/28.
//

import SwiftUI

/// 根视图：控制启动页、登录页与主界面的切换
struct RootView: View {
    @ObservedObject private var authManager = AuthManager.shared

    /// 启动页是否完成
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            if !splashFinished {
                // 显示启动页
                SplashView(isFinished: $splashFinished)
                    .transition(.opacity)
            } else if authManager.isAuthenticated {
                // 已登录，显示主界面
                MainTabView()
                    .transition(.opacity)
            } else {
                // 未登录，显示认证页
                AuthView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: splashFinished)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}

#Preview {
    RootView()
}
