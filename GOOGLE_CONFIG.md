# 🔑 Google 登录配置信息

**创建时间:** 2026-01-02
**Client ID:** 812902326396-ghc7gdq361p16akbagrjt0vohu5f73of.apps.googleusercontent.com

---

## 📋 配置信息

### Google OAuth Client ID
```
812902326396-ghc7gdq361p16akbagrjt0vohu5f73of.apps.googleusercontent.com
```

### URL Scheme（去掉后缀）
```
com.googleusercontent.apps.812902326396-ghc7gdq361p16akbagrjt0vohu5f73of
```

---

## 🔧 在 Xcode 中配置步骤

### 步骤 1: 打开项目设置

1. 打开 Xcode
2. 在项目导航器中选择 "earth Lord" 项目（蓝色图标）
3. 在左侧 TARGETS 中选择 "earth Lord"
4. 选择顶部的 "Info" 标签页

### 步骤 2: 添加 GIDClientID

在 **Custom iOS Target Properties** 部分：

1. 找到任意一行，点击旁边的 **"+"** 按钮
2. 在弹出的输入框中输入：`GIDClientID`
3. 按下回车键
4. Type 会自动设置为 `String`
5. 在 Value 列双击，输入：
   ```
   812902326396-ghc7gdq361p16akbagrjt0vohu5f73of.apps.googleusercontent.com
   ```
6. 按下回车保存

### 步骤 3: 添加 URL Scheme

向下滚动到 **URL Types** 部分：

1. 展开 "URL Types"（点击左侧箭头）
2. 点击 **"+"** 按钮添加新的 URL Type
3. 展开新添加的 "Item 0"
4. 配置以下字段：

   - **Identifier**: 输入 `Google Sign-In`
   - **URL Schemes**: 展开后点击 "+" 添加，输入：
     ```
     com.googleusercontent.apps.812902326396-ghc7gdq361p16akbagrjt0vohu5f73of
     ```
   - **Role**: 选择 `Editor`（下拉菜单）

5. 完成后的配置应该类似：
   ```
   URL Types
   └─ Item 0
      ├─ Identifier: Google Sign-In
      ├─ URL Schemes
      │  └─ Item 0: com.googleusercontent.apps.812902326396-ghc7gdq361p16akbagrjt0vohu5f73of
      └─ Role: Editor
   ```

### 步骤 4: 保存配置

1. 按下 `⌘ + S` 保存
2. 或者直接开始编译，Xcode 会自动保存

---

## ✅ 验证配置

### 检查方法 1: 查看 Info.plist 源代码

1. 在项目导航器中找到并选择 "earth Lord" 项目
2. 选择 Target → Info 标签页
3. 右键点击列表区域，选择 "Show Raw Keys/Values"
4. 应该能看到：
   - `GIDClientID` = `812902326396-ghc7gdq361p16akbagrjt0vohu5f73of.apps.googleusercontent.com`
   - `CFBundleURLTypes` 包含 Google URL Scheme

### 检查方法 2: 编译测试

```bash
# 清理构建
⌘ + Shift + K

# 重新编译
⌘ + B

# 应该编译成功，没有错误
```

### 检查方法 3: 运行测试

```bash
# 运行应用
⌘ + R

# 打开控制台
⌘ + Shift + C

# 点击「使用 Google 登录」按钮

# 应该看到日志：
🚀 开始 Google 登录流程...
📱 获取根视图控制器成功
🔑 Google Client ID 已配置
⚙️ Google Sign-In 配置完成
🔐 打开 Google 登录界面...
```

---

## ⚠️ 注意事项

### 1. 不要提交敏感信息到 Git

此配置文件包含 Client ID，虽然 Client ID 不是秘密，但建议：

```bash
# 将此文件添加到 .gitignore（可选）
echo "GOOGLE_CONFIG.md" >> .gitignore
```

### 2. 真机测试

- 模拟器可能无法完全测试 Google 登录
- 建议使用真机测试
- 确保真机已登录 Google 账号

### 3. Bundle ID 匹配

确保 Xcode 中的 Bundle ID 与 Google Cloud Console 中配置的一致：

1. 选择 Target → General
2. 查看 Bundle Identifier
3. 应该与 Google Cloud Console 中配置的 iOS Client Bundle ID 一致

---

## 🔍 故障排查

### 问题: 点击按钮后提示 "未配置 Google Client ID"

**检查:**
```
1. 确认已在 Xcode → Target → Info 中添加 GIDClientID
2. Value 是完整的 Client ID（包含 .apps.googleusercontent.com）
3. Clean Build 并重新运行
```

### 问题: Google 登录界面无法打开

**检查:**
```
1. 确认 URL Scheme 已正确配置
2. URL Scheme 格式: com.googleusercontent.apps.CLIENT_ID_PREFIX
3. 不要包含 .apps.googleusercontent.com 后缀
```

### 问题: 登录后无法返回应用

**检查:**
```
1. 确认 earth_LordApp.swift 中有 .onOpenURL 处理
2. 确认 GoogleSignIn SDK 已安装
3. 查看控制台是否有 "📲 收到 URL 回调" 日志
```

---

## 📚 相关文档

- INSTALL_GOOGLESIGNIN_SDK.md - 安装 GoogleSignIn SDK
- GOOGLE_SIGNIN_SETUP.md - 详细配置指南
- NEXT_STEPS.md - 下一步操作

---

**最后更新:** 2026-01-02
**状态:** 等待在 Xcode 中配置
