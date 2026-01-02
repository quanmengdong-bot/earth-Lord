# Supabase 邮件配置指南

## 📧 为什么收不到验证邮件？

如果您在测试认证功能时收不到验证邮件，请按照以下步骤检查配置：

---

## ✅ 配置检查清单

### 1️⃣ 访问 Supabase Dashboard
```
https://supabase.com/dashboard/project/uxkyrcyyuxtvgasqplua
```

### 2️⃣ 启用 Email Provider 和 Email OTP

1. 左侧菜单：**Authentication** → **Providers**
2. 找到 **Email** 选项
3. 确保以下选项已启用：

```
✅ Enable Email provider (启用邮件登录)
✅ Enable Email OTP (启用邮件验证码) ← 重要！这个必须开启
```

4. 其他可选设置：
```
⬜ Confirm email (需要邮箱确认)
⬜ Secure email change (安全的邮箱修改)
```

**截图位置：**
```
Authentication → Providers → Email
```

---

### 3️⃣ 检查 Email Templates（邮件模板）

1. 左侧菜单：**Authentication** → **Email Templates**
2. 您会看到4个默认模板：

#### 📨 Confirm signup（注册确认）
- 用途：新用户注册时发送
- 包含：确认链接或OTP验证码
- **我们使用这个模板进行注册！**

#### 🔗 Magic Link（魔法链接）
- 用途：无密码登录
- 包含：一次性登录链接

#### ✏️ Change Email Address（修改邮箱）
- 用途：用户修改邮箱时
- 包含：确认新邮箱的验证码

#### 🔐 Reset Password（重置密码）
- 用途：用户忘记密码时
- 包含：重置密码的验证码
- **我们使用这个模板进行密码重置！**

**截图位置：**
```
Authentication → Email Templates
```

---

### 4️⃣ 检查 SMTP 设置（最重要！）

1. 左侧菜单：**Project Settings** → **Auth**
2. 滚动到 **SMTP Settings** 部分

#### 🆓 默认配置（Supabase 内置邮件服务）
```
- 免费版限制：每小时 3 封邮件
- 发件人：noreply@mail.app.supabase.io
- 仅用于测试，生产环境不推荐
```

#### ⚠️ 限制说明
如果您在 1 小时内发送超过 3 封邮件，会出现以下错误：
```
Error: Email rate limit exceeded
```

#### 🎯 如果需要更多邮件额度
需要配置自定义 SMTP：
```
- Gmail SMTP
- SendGrid
- Amazon SES
- 其他 SMTP 服务
```

**截图位置：**
```
Project Settings → Auth → SMTP Settings
```

---

### 5️⃣ 检查垃圾邮件箱

📮 **重要提示：**
- Supabase 的默认邮件服务经常被标记为垃圾邮件
- 请检查您的垃圾邮件/垃圾箱文件夹
- 发件人通常是：`noreply@mail.app.supabase.io`

---

### 6️⃣ 查看 Auth Logs（认证日志）

1. 左侧菜单：**Authentication** → **Logs**
2. 查看最近的认证事件
3. 检查是否有邮件发送记录

**可以看到的信息：**
```
- 邮件发送时间
- 收件人邮箱
- 邮件类型（signup/recovery）
- 发送状态（成功/失败）
```

**截图位置：**
```
Authentication → Logs
```

---

## 🧪 测试步骤

### 使用测试页面验证配置

1. 在 Xcode 中打开项目
2. 找到 `AuthTestView.swift`
3. 将其添加到某个导航页面（例如 MoreTabView）
4. 运行应用

### 测试注册流程：

```
1. 输入您的真实邮箱（建议使用 Gmail）
2. 点击 "1. 发送注册验证码"
3. 检查邮箱（包括垃圾邮件箱！）
4. 输入收到的 6 位验证码
5. 点击 "2. 验证验证码"
6. 输入密码
7. 点击 "3. 设置密码完成注册"
```

---

## 🔍 常见问题排查

### ❌ 问题1：没有收到邮件
**可能原因：**
- Email OTP 未启用
- SMTP 配置错误
- 邮件在垃圾箱
- 超过免费版限制（每小时3封）

**解决方案：**
1. 检查 Authentication → Providers → Enable Email OTP
2. 检查垃圾邮件箱
3. 等待 1 小时后重试
4. 配置自定义 SMTP

### ❌ 问题2：收到邮件但没有验证码
**可能原因：**
- 邮件模板配置错误
- 使用了 Magic Link 而不是 OTP

**解决方案：**
1. 检查 Email Templates
2. 确保使用的是 OTP 模式，不是 Magic Link

### ❌ 问题3：验证码无效
**可能原因：**
- 验证码过期（通常 60 秒）
- 输入错误

**解决方案：**
1. 重新发送验证码
2. 仔细输入 6 位数字

---

## 📝 代码中的关键方法

### 注册流程
```swift
// 1. 发送验证码
await authManager.sendRegisterOTP(email: "user@example.com")

// 2. 验证验证码（此时用户已登录但无密码）
await authManager.verifyRegisterOTP(email: "user@example.com", code: "123456")

// 3. 设置密码完成注册
await authManager.completeRegistration(password: "securePassword")
```

### 密码重置流程
```swift
// 1. 发送重置验证码
await authManager.sendResetOTP(email: "user@example.com")

// 2. 验证验证码（type 为 .recovery）
await authManager.verifyResetOTP(email: "user@example.com", code: "123456")

// 3. 设置新密码
await authManager.resetPassword(newPassword: "newSecurePassword")
```

---

## 🎯 推荐配置（生产环境）

### 使用自定义 SMTP

#### 选项1: SendGrid（推荐）
```
- 免费额度：每天 100 封
- 配置简单
- 送达率高
```

#### 选项2: Gmail SMTP
```
- 免费
- 每天限制 500 封
- 需要应用专用密码
```

#### 选项3: Amazon SES
```
- 免费额度：每月 62,000 封
- 配置稍复杂
- 适合大规模使用
```

---

## 📞 需要帮助？

如果按照以上步骤仍无法解决问题：

1. 访问 Supabase Discord: https://discord.supabase.com
2. 查看 Supabase Docs: https://supabase.com/docs/guides/auth
3. 检查项目的 Auth Logs 获取详细错误信息

---

**最后更新：** 2026-01-01
**项目 URL：** https://uxkyrcyyuxtvgasqplua.supabase.co
