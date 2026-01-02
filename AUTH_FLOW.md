# 🔐 EarthLord 认证流程说明

## 📋 架构概览

```
应用启动
    ↓
SplashView (启动画面)
    ↓
检查登录状态 (checkSession)
    ↓
    ├─ 已登录 → ContentView (主页面)
    └─ 未登录 → AuthView (认证页面)
```

---

## 🎯 核心文件

### 1️⃣ **earth_LordApp.swift** - 应用入口
```swift
@StateObject private var authManager = AuthManager.shared
@State private var showSplash = true

// 页面切换逻辑
if showSplash {
    SplashView(isFinished: $showSplash)
} else if authManager.isAuthenticated {
    ContentView()  // 已登录 → 主页面
} else {
    AuthView()     // 未登录 → 认证页面
}
```

**职责：**
- 控制应用根视图
- 根据 `authManager.isAuthenticated` 自动切换页面
- 带动画的页面转场

---

### 2️⃣ **AuthManager.swift** - 认证管理器

#### 发布属性
```swift
@Published var isAuthenticated: Bool = false
@Published var needsPasswordSetup: Bool = false
@Published var currentUser: User? = nil
@Published var isLoading: Bool = false
@Published var errorMessage: String? = nil
@Published var otpSent: Bool = false
@Published var otpVerified: Bool = false
```

#### 核心功能

**A. 会话检查**
```swift
func checkSession() async {
    // 启动时调用
    // 检查是否有有效的 Supabase 会话
    // 如果有 → isAuthenticated = true
}
```

**B. 认证状态监听**
```swift
private func startAuthStateListener() async {
    // 监听 Supabase auth.authStateChanges
    // 自动响应：登录、登出、Token刷新、用户更新
}
```

**监听的事件：**
- ✅ `.signedIn` - 用户登录
- ✅ `.signedOut` - 用户登出
- ✅ `.tokenRefreshed` - Token 刷新
- ✅ `.userUpdated` - 用户信息更新

**C. 注册流程**
```swift
// 1. 发送验证码
await sendRegisterOTP(email: "user@example.com")

// 2. 验证验证码（用户已登录但无密码）
await verifyRegisterOTP(email: "user@example.com", code: "123456")

// 3. 设置密码完成注册
await completeRegistration(password: "password")
```

**D. 登录流程**
```swift
await signIn(email: "user@example.com", password: "password")
```

**E. 密码重置流程**
```swift
// 1. 发送重置验证码
await sendResetOTP(email: "user@example.com")

// 2. 验证验证码（type: .recovery）
await verifyResetOTP(email: "user@example.com", code: "123456")

// 3. 设置新密码
await resetPassword(newPassword: "newPassword")
```

**F. 退出登录**
```swift
await signOut()
```

---

### 3️⃣ **SplashView.swift** - 启动画面

#### 功能
```swift
启动画面显示 (2.5秒)
    ├─ 0.0s: "正在检查登录状态..." → checkSession()
    ├─ 1.0s: "正在加载资源..."
    ├─ 2.0s: "准备就绪"
    └─ 2.5s: isFinished = true → 进入主界面
```

#### UI 元素
- 🌍 Logo 渐变动画
- ✨ 呼吸光晕效果
- 📝 加载进度提示
- ⏱️ 三点加载动画

---

### 4️⃣ **AuthView.swift** - 认证页面

#### Tab 切换
- 登录 Tab
- 注册 Tab

#### 登录 Tab
```
📧 邮箱输入
🔒 密码输入
➡️ 登录按钮
🔗 忘记密码？链接
```

#### 注册 Tab（三步流程）
```
步骤1: 输入邮箱 → 发送验证码
    ↓
步骤2: 验证 OTP（60秒倒计时）
    ↓
步骤3: 设置密码（密码强度提示）
    ↓
完成注册 → 自动登录
```

#### 忘记密码（Sheet 弹窗）
```
步骤1: 输入邮箱 → 发送验证码
    ↓
步骤2: 验证 OTP（60秒倒计时）
    ↓
步骤3: 设置新密码
    ↓
密码重置成功 → 返回登录
```

#### 第三方登录
- 🍎 Apple 登录（即将开放）
- 🌍 Google 登录（即将开放）

---

## 🔄 认证状态自动切换

### 场景1：用户登录
```
用户在 AuthView 输入邮箱密码 → 点击登录
    ↓
authManager.signIn() 调用 Supabase API
    ↓
Supabase 触发 .signedIn 事件
    ↓
authStateListener 接收事件
    ↓
isAuthenticated = true
    ↓
earth_LordApp 自动切换到 ContentView
```

### 场景2：用户注册
```
用户在 AuthView 完成三步注册流程
    ↓
authManager.completeRegistration() 设置密码
    ↓
Supabase 触发 .signedIn 事件
    ↓
authStateListener 接收事件
    ↓
isAuthenticated = true
    ↓
earth_LordApp 自动切换到 ContentView
```

### 场景3：用户登出
```
用户在 ProfileTabView 点击退出登录
    ↓
authManager.signOut() 调用 Supabase API
    ↓
Supabase 触发 .signedOut 事件
    ↓
authStateListener 接收事件
    ↓
isAuthenticated = false
    ↓
earth_LordApp 自动切换到 AuthView
```

### 场景4：Token 自动刷新
```
Supabase 自动刷新 Token（后台）
    ↓
Supabase 触发 .tokenRefreshed 事件
    ↓
authStateListener 接收事件
    ↓
更新 currentUser 信息
    ↓
用户无感知，继续使用应用
```

---

## 🎨 用户体验流程

### 首次使用
```
1. 打开应用
    ↓
2. 显示 SplashView（启动画面）
    ↓ (2.5秒)
3. 检查登录状态 → 未登录
    ↓
4. 显示 AuthView（认证页面）
    ↓
5. 用户注册/登录
    ↓
6. 自动切换到 ContentView（主页面）
```

### 再次使用（已登录）
```
1. 打开应用
    ↓
2. 显示 SplashView（启动画面）
    ↓ (2.5秒)
3. checkSession() 检测到有效会话
    ↓
4. isAuthenticated = true
    ↓
5. 直接显示 ContentView（主页面）
```

### 退出登录
```
1. 在 ProfileTabView 点击退出
    ↓
2. authManager.signOut()
    ↓
3. isAuthenticated = false
    ↓
4. 自动切换到 AuthView（认证页面）
```

---

## 🛡️ 安全特性

### 1. 会话持久化
- Supabase 自动管理 Token
- 应用重启后自动恢复登录状态
- Token 过期自动刷新

### 2. 注册流程强制密码
```
验证 OTP → otpVerified = true
    ↓
用户已登录但 isAuthenticated = false
    ↓
必须设置密码
    ↓
isAuthenticated = true → 进入主页
```

### 3. 密码重置安全
- 使用 `.recovery` 类型验证码
- 验证码 60 秒倒计时
- 密码强度提示

---

## 📊 状态流转图

```
┌─────────────┐
│  应用启动   │
└──────┬──────┘
       ↓
┌─────────────┐
│ SplashView  │
│ checkSession│
└──────┬──────┘
       ↓
   有会话？
       ├─ YES → isAuthenticated = true
       └─ NO  → isAuthenticated = false
       ↓
┌──────────────────────────────┐
│ earth_LordApp 根据状态切换   │
│                              │
│ isAuthenticated = true       │
│     ↓                        │
│ ContentView (主页面)         │
│                              │
│ isAuthenticated = false      │
│     ↓                        │
│ AuthView (认证页面)          │
└──────────────────────────────┘
       ↑                ↓
       │                │
   登出事件          登录事件
       │                │
       └────────────────┘
    authStateListener 监听
```

---

## 🔧 调试日志

AuthManager 会在控制台输出以下日志：

```
✅ 用户已登录: user@example.com
👋 用户已登出
🔄 Token 已刷新
📝 用户信息已更新
🔄 认证状态变化: signedIn
ℹ️ 未检测到有效会话
```

---

## 🚀 测试流程

### 测试注册
1. 运行应用 → 启动画面
2. 进入 AuthView → 切换到"注册" Tab
3. 输入邮箱 → 发送验证码
4. 输入验证码 → 验证
5. 设置密码 → 完成注册
6. 自动跳转到主页面 ✅

### 测试登录
1. 运行应用 → 启动画面
2. 进入 AuthView → "登录" Tab
3. 输入邮箱密码 → 登录
4. 自动跳转到主页面 ✅

### 测试会话恢复
1. 登录后关闭应用
2. 重新打开应用
3. 启动画面检查会话
4. 直接进入主页面（无需重新登录）✅

### 测试登出
1. 在主页面 → 进入 ProfileTabView
2. 点击退出登录
3. 自动跳转到 AuthView ✅

---

## 📝 配置要求

### Supabase 配置
1. 访问：https://supabase.com/dashboard
2. **Authentication** → **Providers** → 启用 **Email OTP**
3. 配置邮件模板（见 SUPABASE_EMAIL_SETUP.md）

### 环境变量
```swift
// SupabaseTestView.swift
let supabaseURL = "https://uxkyrcyyuxtvgasqplua.supabase.co"
let supabaseKey = "sb_publishable_m3zrsYu4axfZhCo6RD-bKw_mNsd8Nq9"
```

---

## 🎯 总结

### 核心优势
✅ 自动化认证状态管理
✅ 无缝页面切换
✅ 会话持久化
✅ Token 自动刷新
✅ 统一的错误处理
✅ 优雅的用户体验

### 文件结构
```
earth Lord/
├── earth_LordApp.swift           # 应用入口，控制根视图
├── Managers/
│   └── AuthManager.swift         # 认证管理器（单例）
├── Models/
│   └── User.swift                # 用户模型
└── Views/
    ├── SplashView.swift          # 启动画面
    ├── Auth/
    │   └── AuthView.swift        # 认证页面（登录/注册）
    ├── ContentView.swift         # 主页面
    └── Tabs/
        └── ProfileTabView.swift  # 个人中心（包含退出登录）
```

---

**最后更新：** 2026-01-01
**版本：** 1.0.0
