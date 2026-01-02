# 🔐 Google 登录配置指南 - EarthLord

**版本:** 1.0.0
**更新时间:** 2026-01-02

---

## 📋 前置条件

✅ **已完成的配置：**
1. GoogleSignIn SDK 已手动添加到项目
2. Supabase Google Provider 已启用
3. Authorized Client IDs 已填入 Supabase
4. Skip nonce check 已开启

---

## 🚀 配置步骤

### 步骤 1: 获取 Google Client ID

#### 1️⃣ 访问 Google Cloud Console
```
https://console.cloud.google.com/
```

#### 2️⃣ 创建或选择项目
- 如果已有项目，选择现有项目
- 如果没有，点击「新建项目」

#### 3️⃣ 启用 Google Sign-In API
```
1. 在左侧菜单选择「API 和服务」→「启用的 API 和服务」
2. 点击「+ 启用 API 和服务」
3. 搜索「Google Sign-In」
4. 点击「启用」
```

#### 4️⃣ 创建 OAuth 2.0 凭据
```
1. 进入「API 和服务」→「凭据」
2. 点击「+ 创建凭据」→「OAuth 客户端 ID」
3. 应用类型：选择「iOS」
4. 名称：填写「EarthLord iOS」
5. Bundle ID：填写项目的 Bundle Identifier
   例如: com.yourcompany.earthlord
```

#### 5️⃣ 获取 Client ID
创建成功后，你会得到一个 Client ID，格式如下：
```
123456789-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com
```

**⚠️ 重要：** 保存这个 Client ID，后续步骤需要用到！

---

### 步骤 2: 配置 Info.plist

#### 📝 打开 Info.plist 文件
```
路径: earth Lord/Info.plist
```

#### 🔧 替换配置

找到以下两处 `YOUR_CLIENT_ID`，替换为你的实际 Client ID：

```xml
<!-- 1. GIDClientID（完整的 Client ID）-->
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>

<!-- 2. URL Schemes（只需要 Client ID 部分）-->
<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
</array>
```

#### ✅ 配置示例

假设你的 Client ID 是：
```
123456789-abcdefg.apps.googleusercontent.com
```

那么配置应该是：

```xml
<!-- GIDClientID 配置（完整 ID）-->
<key>GIDClientID</key>
<string>123456789-abcdefg.apps.googleusercontent.com</string>

<!-- URL Scheme 配置（反转的格式）-->
<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.123456789-abcdefg</string>
</array>
```

---

### 步骤 3: 配置 Supabase（已完成✅）

你已经在 Supabase Dashboard 中完成了以下配置：

#### ✅ 已启用 Google Provider
```
Supabase Dashboard → Authentication → Providers → Google → Enabled
```

#### ✅ 已填入 Authorized Client IDs
```
填入的是同一个 Google Client ID:
123456789-abcdefg.apps.googleusercontent.com
```

#### ✅ 已开启 Skip nonce check
```
这个选项对 iOS 原生应用是必需的
```

---

## 🧪 测试步骤

### 1️⃣ 清理并重新构建
```bash
# 在 Xcode 中
Product → Clean Build Folder (⌘ + Shift + K)

# 然后重新运行
Product → Run (⌘ + R)
```

### 2️⃣ 测试 Google 登录流程

#### 预期日志：
```
👆 点击 Google 登录按钮
🚀 开始 Google 登录流程...
📱 获取根视图控制器成功
🔑 Google Client ID 已配置
⚙️ Google Sign-In 配置完成
🔐 打开 Google 登录界面...
✅ Google 登录成功，获取用户信息...
🎫 获取 ID Token 成功
🔄 使用 ID Token 登录 Supabase...
✅ Google 登录完成！用户: user@gmail.com
🔄 认证状态变化: signedIn
✅ 用户已登录: user@gmail.com
🔄 isAuthenticated 状态变化: false → true
🏠 显示主页面（已登录）
```

#### 预期界面流程：
```
1. 认证页面 → 点击「使用 Google 登录」
2. 打开 Google 登录界面（浏览器或 Google 应用）
3. 选择 Google 账号
4. 授权应用访问
5. 自动返回应用
6. 自动跳转到主页面（已登录状态）
```

---

## ⚠️ 常见问题

### 问题 1: 点击按钮没反应

#### 检查点：
```
1. Info.plist 中 GIDClientID 是否正确配置
2. 控制台是否显示「❌ 未配置 Google Client ID」
```

#### 解决方案：
```
1. 检查 Info.plist 中的 GIDClientID 配置
2. 确保格式正确（包含 .apps.googleusercontent.com）
3. Clean Build Folder 并重新运行
```

---

### 问题 2: Google 登录界面无法打开

#### 检查点：
```
1. URL Schemes 配置是否正确
2. 控制台是否显示「❌ 无法获取根视图控制器」
```

#### 解决方案：
```
1. 检查 Info.plist 中的 CFBundleURLSchemes
2. 确保格式为: com.googleusercontent.apps.YOUR_CLIENT_ID
3. 确保模拟器或真机有网络连接
```

---

### 问题 3: 登录后无法返回应用

#### 症状：
```
在浏览器中完成 Google 登录，但应用没有响应
```

#### 检查点：
```
1. earth_LordApp.swift 中是否有 .onOpenURL 修饰符
2. 控制台是否显示「📲 收到 URL 回调」
```

#### 解决方案：
```swift
// 确保 App 中有这段代码
.onOpenURL { url in
    print("📲 收到 URL 回调: \(url.absoluteString)")
    GIDSignIn.sharedInstance.handle(url)
}
```

---

### 问题 4: Supabase 登录失败

#### 症状：
```
控制台显示:
✅ Google 登录成功，获取用户信息...
🎫 获取 ID Token 成功
🔄 使用 ID Token 登录 Supabase...
❌ Google 登录失败: ...
```

#### 检查点：
```
1. Supabase Google Provider 是否启用
2. Authorized Client IDs 是否正确
3. Skip nonce check 是否开启
```

#### 解决方案：
```
1. 访问 Supabase Dashboard
2. Authentication → Providers → Google
3. 确认以下设置：
   - Enabled: ✅
   - Authorized Client IDs: 填入你的 Google Client ID
   - Skip nonce check: ✅
4. 保存设置
5. 重新测试
```

---

### 问题 5: 用户取消登录

#### 症状：
```
控制台显示:
ℹ️ 用户取消了 Google 登录
```

#### 说明：
```
这是正常行为，用户在 Google 登录界面点击了取消或返回
不会显示错误提示
```

---

## 📝 调试日志说明

### 成功流程的完整日志：

```
# 1. 点击按钮
👆 点击 Google 登录按钮

# 2. 初始化
🚀 开始 Google 登录流程...
📱 获取根视图控制器成功
🔑 Google Client ID 已配置
⚙️ Google Sign-In 配置完成

# 3. 打开 Google 登录界面
🔐 打开 Google 登录界面...

# 4. 用户授权（在 Google 界面）
# （此时用户在 Google 界面选择账号并授权）

# 5. 获取凭证
✅ Google 登录成功，获取用户信息...
🎫 获取 ID Token 成功

# 6. Supabase 登录
🔄 使用 ID Token 登录 Supabase...
✅ Google 登录完成！用户: user@gmail.com

# 7. 状态更新
🔄 认证状态变化: signedIn
✅ 用户已登录: user@gmail.com
🔄 isAuthenticated 状态变化: false → true

# 8. 界面跳转
🏠 显示主页面（已登录）
```

---

## 🎯 配置检查清单

在开始测试前，请确认以下项目：

### Google Cloud Console
- [ ] 已创建 OAuth 2.0 凭据（iOS 类型）
- [ ] Bundle ID 正确匹配项目
- [ ] 已获取 Client ID

### Info.plist 配置
- [ ] `GIDClientID` 已填入完整 Client ID
- [ ] `CFBundleURLSchemes` 已配置正确的 URL Scheme
- [ ] 格式正确（com.googleusercontent.apps.YOUR_CLIENT_ID）

### Supabase 配置
- [ ] Google Provider 已启用
- [ ] Authorized Client IDs 已填入
- [ ] Skip nonce check 已开启

### 代码集成
- [ ] AuthManager.swift 已导入 GoogleSignIn
- [ ] earth_LordApp.swift 已添加 .onOpenURL
- [ ] AuthView.swift Google 按钮已连接

---

## 📞 需要帮助？

### 收集调试信息

如果遇到问题，请提供：
1. **完整的控制台日志**（从点击按钮开始）
2. **Info.plist 配置**（隐藏敏感信息）
3. **Supabase Dashboard 截图**（Google Provider 配置）
4. **错误信息**（如果有）

### 有用的链接

- [Google Sign-In iOS 官方文档](https://developers.google.com/identity/sign-in/ios)
- [Supabase Google OAuth 文档](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [GoogleSignIn SDK GitHub](https://github.com/google/GoogleSignIn-iOS)

---

## ✅ 完成标志

当你看到以下日志，说明 Google 登录已成功配置：

```
✅ Google 登录完成！用户: your-email@gmail.com
🏠 显示主页面（已登录）
```

---

**最后更新:** 2026-01-02
**状态:** ✅ Google 登录功能已实现，等待配置测试
