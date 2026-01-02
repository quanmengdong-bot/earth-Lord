# 🐛 调试指南 - EarthLord

**版本:** 1.0.0
**更新时间:** 2026-01-01

---

## 🔍 启动画面卡住问题

### 问题描述
应用启动后一直停留在"准备就绪"画面，不会跳转到登录页或主页。

### ✅ 已修复
**修复版本:** dd2fd87

**修复内容:**
1. 重构了 `SplashView` 的加载逻辑
2. 将多个 `DispatchQueue.main.asyncAfter` 改为单个 `Task` 顺序执行
3. 添加了详细的调试日志

---

## 📊 如何查看调试日志

### 在 Xcode 中查看控制台

#### 1️⃣ 运行应用
```
1. 打开 Xcode
2. 选择模拟器或真机
3. 点击 ▶️ Run (⌘ + R)
```

#### 2️⃣ 打开控制台
```
View → Debug Area → Activate Console (⌘ + Shift + C)
```

#### 3️⃣ 查看日志输出

正常的启动流程会显示以下日志：

```
📱 显示启动画面
✅ 会话检查完成
ℹ️ 未检测到有效会话
📦 加载资源中...
✅ 准备就绪
🚀 启动画面完成，isFinished = true
🔄 showSplash 状态变化: true → false
🔐 显示认证页面（未登录）
```

如果用户已登录，会显示：
```
📱 显示启动画面
✅ 会话检查完成
✅ 检测到有效会话，用户已登录
📦 加载资源中...
✅ 准备就绪
🚀 启动画面完成，isFinished = true
🔄 showSplash 状态变化: true → false
🔄 isAuthenticated 状态变化: false → true
🏠 显示主页面（已登录）
```

---

## 🎯 启动流程时间线

```
0.0s  → 📱 显示启动画面
0.0s  → ✅ 开始检查会话
0.1s  → ✅ 会话检查完成
1.1s  → 📦 加载资源中...
2.1s  → ✅ 准备就绪
2.6s  → 🚀 启动画面完成
2.9s  → 🔐 显示认证页面（或主页面）
```

**总时长:** 约 2.5-3 秒

---

## ⚠️ 常见问题排查

### 问题 1: 启动画面卡住不动

#### 症状
- 显示"准备就绪"后不跳转
- 控制台没有"🚀 启动画面完成"日志

#### ✅ 已修复（最新版本）
**原因:** Binding 逻辑错误
- `showSplash = true` → 显示 SplashView
- 完成后设置 `isFinished = true` → `showSplash = true` → 继续显示（卡住）

**修复:** 将 `isFinished = true` 改为 `isFinished = false`
- 完成后设置 `isFinished = false` → `showSplash = false` → 隐藏 SplashView ✓

#### 其他可能原因
1. Task 被取消或阻塞
2. 动画导致状态更新延迟

#### 排查步骤
```
1. 查看控制台日志，确认看到"🚀 启动画面完成"
2. 如果仍然卡住，Clean Build Folder (⌘ + Shift + K)
3. 删除应用重新安装
```

---

### 问题 2: 没有日志输出

#### 症状
- 控制台没有任何日志
- 应用正常运行但看不到调试信息

#### 解决方案
```
1. 确保控制台已打开 (⌘ + Shift + C)
2. 检查日志过滤器是否设置正确
3. 确认是 Debug 构建（不是 Release）
```

---

### 问题 3: 直接跳到主页面（跳过登录）

#### 症状
- 启动后直接显示主页面
- 控制台显示"✅ 检测到有效会话"

#### 原因
- 用户之前登录过，会话仍然有效
- Supabase Token 未过期

#### 解决方案（如果想测试登录流程）
```
1. 在 ProfileTabView 点击"退出登录"
2. 或者删除应用重新安装
```

---

### 问题 4: 认证状态监听器问题

#### 症状
- 登录后不跳转到主页面
- 登出后不返回登录页
- 控制台没有"🔄 isAuthenticated 状态变化"

#### 检查点
```
1. 确认 AuthManager.shared 只在 App 中使用 @StateObject
2. 其他视图使用 @ObservedObject
3. 检查 supabase.auth.authStateChanges 是否正常工作
```

#### 调试方法
在 `AuthManager.swift` 的 `handleAuthStateChange` 中查看日志：
```
🔄 认证状态变化: signedIn
✅ 用户已登录: user@example.com
```

---

## 🔧 手动测试步骤

### 测试启动流程

#### 1️⃣ 首次启动（未登录）
```
预期日志顺序:
📱 显示启动画面
✅ 会话检查完成
ℹ️ 未检测到有效会话
📦 加载资源中...
✅ 准备就绪
🚀 启动画面完成，isFinished = true
🔄 showSplash 状态变化: true → false
🔐 显示认证页面（未登录）

预期界面:
启动画面 (2.5s) → 登录/注册页面
```

#### 2️⃣ 用户注册
```
预期日志:
📧 发送注册验证码...
✅ 注册验证码已发送到: xxx
📝 验证码验证成功...
✅ 验证码验证成功，等待设置密码
🔐 设置密码...
✅ 注册完成，密码已设置
🔄 认证状态变化: signedIn
✅ 用户已登录: xxx
🔄 isAuthenticated 状态变化: false → true
🏠 显示主页面（已登录）

预期界面:
认证页面 → 主页面（自动切换）
```

#### 3️⃣ 用户登出
```
预期日志:
👋 点击退出登录...
✅ 已退出登录
🔄 认证状态变化: signedOut
👋 用户已登出
🔄 isAuthenticated 状态变化: true → false
🔐 显示认证页面（未登录）

预期界面:
主页面 → 认证页面（自动切换）
```

#### 4️⃣ 会话恢复（重启应用）
```
预期日志:
📱 显示启动画面
✅ 会话检查完成
✅ 检测到有效会话，用户已登录
📦 加载资源中...
✅ 准备就绪
🚀 启动画面完成，isFinished = true
🔄 showSplash 状态变化: true → false
🏠 显示主页面（已登录）

预期界面:
启动画面 (2.5s) → 主页面（跳过登录）
```

---

## 📝 启用/禁用调试日志

### 当前状态
✅ **调试日志已启用**

所有调试日志都使用 `print()` 语句，会在 Debug 构建中显示。

### 如果想禁用日志

在发布版本前，可以将所有 `print()` 改为：
```swift
#if DEBUG
print("调试信息")
#endif
```

或者创建一个全局日志函数：
```swift
func debugLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}
```

---

## 🎯 性能优化建议

### 启动画面时间

当前启动画面显示 **2.5 秒**：
- 会话检查: ~0.1s
- 加载动画: 2.4s

如果觉得太慢，可以调整 `SplashView.swift` 中的时间：
```swift
// 当前设置
try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
try? await Task.sleep(nanoseconds: 500_000_000)   // 0.5秒

// 快速版本（总计 1 秒）
try? await Task.sleep(nanoseconds: 500_000_000)   // 0.5秒
try? await Task.sleep(nanoseconds: 300_000_000)   // 0.3秒
try? await Task.sleep(nanoseconds: 200_000_000)   // 0.2秒
```

---

## 📞 需要帮助？

### 收集信息

如果遇到问题，请提供：
1. **完整的控制台日志**
2. **问题描述**（卡在哪一步）
3. **Xcode 版本**
4. **iOS 版本**
5. **是否已配置 Supabase**

### 常用命令

**清理构建：**
```bash
# 在 Xcode 中
Product → Clean Build Folder (⌘ + Shift + K)

# 命令行
rm -rf ~/Library/Developer/Xcode/DerivedData/earth_Lord-*
```

**重置应用：**
```
1. 删除应用
2. Clean Build Folder
3. 重新运行
```

---

## ✅ 修复历史

### v1.0.1 (最新)
- ✅ **修复启动画面卡住的根本原因**（Binding 逻辑错误）
- ✅ 将 `isFinished = true` 改为 `isFinished = false`
- ✅ 更新调试指南

### v1.0.0 (dd2fd87)
- ✅ 重构 SplashView 加载流程（Task 代替 DispatchQueue）
- ✅ 添加完整调试日志
- ✅ 优化加载流程
- ✅ 添加状态变化追踪

### v0.9.0 (300c345)
- ✅ 修复 SwiftUI 单例警告
- ✅ 正确使用 @StateObject / @ObservedObject

### v0.8.0 (a037c89)
- ✅ 完成认证流程整合
- ✅ 添加认证状态监听
- ✅ 实现会话恢复

---

**最后更新:** 2026-01-01
**状态:** ✅ 启动流程正常工作
