# 🌍 App 内语言切换功能使用指南

**创建时间:** 2026-01-03
**状态:** 已实现

---

## ✅ 已完成的功能

### 1. LanguageManager（语言管理器）

**文件:** `earth Lord/Managers/LanguageManager.swift`

**功能:**
- 管理三种语言选项：跟随系统、简体中文、English
- 使用 `@Published` 属性自动通知 UI 更新
- 使用 UserDefaults 持久化存储用户选择
- 提供单例模式访问：`LanguageManager.shared`

**核心 API:**
```swift
// 获取当前语言
LanguageManager.shared.currentLanguage

// 切换语言
LanguageManager.shared.changeLanguage(to: .english)

// 获取本地化字符串
LanguageManager.shared.localizedString("删除账户")
```

### 2. String Extension（字符串扩展）

**位置:** `LanguageManager.swift` 底部

**用法:**
```swift
// 简单本地化
"删除账户".localized  // → "Delete Account" (英文) 或 "删除账户" (中文)

// 带参数的本地化
"ID: %@...".localized(with: userId)
```

### 3. ProfileTabView UI（设置页面）

**文件:** `earth Lord/Views/Tabs/ProfileTabView.swift`

**新增功能:**
- 在菜单中添加"语言"选项
- 显示当前选择的语言
- 点击后弹出语言选择面板
- 支持实时预览当前语言

**使用方式:**
1. 运行 App
2. 进入 Profile 标签页
3. 点击"语言"菜单项
4. 选择期望的语言
5. 点击"完成"

---

## 📝 如何在现有视图中应用本地化

### 方法 1: 使用 .localized 扩展（推荐）

**之前的代码:**
```swift
Text("删除账户")
```

**修改后:**
```swift
Text("删除账户".localized)
```

**优点:**
- 简单直接
- 代码改动最小
- 自动响应语言变化

### 方法 2: 使用 LanguageManager

```swift
@ObservedObject private var languageManager = LanguageManager.shared

var body: some View {
    Text(languageManager.localizedString("删除账户"))
}
```

### 方法 3: 带参数的本地化

```swift
// Localizable.xcstrings 中的键: "ID: %@..."
Text("ID: %@...".localized(with: userId.prefix(8)))
```

---

## 🎯 需要本地化的视图文件

以下是项目中包含硬编码中文字符串的主要文件，建议逐步修改：

### 1. 认证相关视图

**SignInView.swift** - 登录页面
```swift
// 示例修改
Text("登录") → Text("登录".localized)
Text("邮箱") → Text("邮箱".localized)
Text("密码") → Text("密码".localized)
```

**SignUpView.swift** - 注册页面
```swift
Text("注册") → Text("注册".localized)
Text("发送验证码") → Text("发送验证码".localized)
```

**PasswordResetView.swift** - 密码重置
```swift
Text("找回密码") → Text("找回密码".localized)
Text("重置密码") → Text("重置密码".localized)
```

### 2. ProfileTabView.swift - 个人页面

**已部分修改的示例:**
```swift
// 菜单项（建议本地化）
Text("设置") → Text("设置".localized)
Text("语言") → Text("语言".localized)
Text("通知") → Text("通知".localized)
Text("隐私") → Text("隐私".localized)
Text("帮助") → Text("帮助".localized)

// 按钮文本
Text("退出登录") → Text("退出登录".localized)
Text("删除账户") → Text("删除账户".localized)

// 对话框
.alert("确认退出".localized, isPresented: $showLogoutAlert) {
    Button("取消".localized, role: .cancel) { }
    Button("退出".localized, role: .destructive) { ... }
} message: {
    Text("确定要退出登录吗？".localized)
}
```

### 3. MainTabView.swift - 底部导航栏

```swift
// Tab 标题
.tabItem {
    Label("地图".localized, systemImage: "map")
}
.tabItem {
    Label("领地".localized, systemImage: "flag.fill")
}
.tabItem {
    Label("个人".localized, systemImage: "person.fill")
}
```

---

## 🔄 语言切换的工作原理

### 1. 用户选择语言

```
用户点击"语言" → 弹出选择面板 → 选择语言 → LanguageManager.changeLanguage()
```

### 2. LanguageManager 更新状态

```swift
func changeLanguage(to language: AppLanguage) {
    // 1. 更新 currentLanguage（触发 @Published）
    currentLanguage = language

    // 2. 保存到 UserDefaults（持久化）
    saveLanguagePreference()

    // 3. 更新 currentBundle（加载对应语言包）
    updateCurrentBundle()
}
```

### 3. UI 自动响应

因为 LanguageManager 是 `ObservableObject`，且 `currentLanguage` 是 `@Published`：
- 所有订阅 LanguageManager 的视图会自动重新渲染
- 使用 `.localized` 的 Text 会自动显示新语言

### 4. 持久化存储

```swift
// 保存
UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")

// 下次启动时加载
if let saved = UserDefaults.standard.string(forKey: "AppLanguage") {
    currentLanguage = AppLanguage(rawValue: saved) ?? .system
}
```

---

## 📋 Localizable.xcstrings 状态

**当前状态:** ✅ 已包含 74 个完整的中英文翻译

**支持的字符串包括:**
- 认证流程相关（登录、注册、密码重置）
- UI 标签（邮箱、密码、验证码等）
- 按钮文本（确定、取消、删除等）
- 提示消息
- Tab 标题

**示例翻译:**
```json
{
  "删除账户": {
    "localizations": {
      "en": {
        "stringUnit": {
          "state": "translated",
          "value": "Delete Account"
        }
      }
    }
  }
}
```

---

## 🧪 测试语言切换功能

### 测试步骤：

1. **运行应用**
   ```
   在 Xcode 中按 ⌘ + R
   ```

2. **登录账户**
   ```
   使用邮箱密码登录（或注册新账户）
   ```

3. **进入 Profile 页面**
   ```
   点击底部 Tab Bar 的 Profile 图标
   ```

4. **打开语言选择**
   ```
   点击菜单中的"语言"行
   ```

5. **切换语言**
   ```
   - 选择"English" - 界面应立即切换为英文
   - 选择"简体中文" - 界面应立即切换为中文
   - 选择"跟随系统" - 界面应使用系统语言
   ```

6. **验证持久化**
   ```
   - 完全关闭 App（双击 Home，上滑关闭）
   - 重新启动 App
   - 检查语言是否保持之前的选择
   ```

### 预期结果：

**切换到 English 后:**
```
✅ "语言" 变为 "Language" (如果该文本已本地化)
✅ "删除账户" 变为 "Delete Account" (如果使用 .localized)
✅ 菜单中的"语言"行显示 "English"
✅ UserDefaults 保存 "en"
```

**切换到简体中文后:**
```
✅ 所有文本显示中文
✅ 菜单中的"语言"行显示 "简体中文"
✅ UserDefaults 保存 "zh-Hans"
```

**选择跟随系统后:**
```
✅ 根据系统语言设置显示对应语言
✅ 菜单中的"语言"行显示 "跟随系统"
✅ UserDefaults 保存 "system"
```

### 查看日志：

打开 Xcode 控制台 (⌘ + Shift + C)，切换语言时应看到：

```
🌍 切换语言: 简体中文 -> English
💾 语言设置已保存: English
✅ 成功加载语言包: en
```

---

## ⚠️ 注意事项

### 1. 视图必须订阅 LanguageManager

要让视图响应语言变化，需要：

```swift
@ObservedObject private var languageManager = LanguageManager.shared
```

如果视图没有订阅，使用 `.localized` 时可能不会自动更新。

### 2. 硬编码字符串不会自动本地化

以下代码**不会**响应语言切换：
```swift
Text("删除账户")  // ❌ 硬编码，不会变化
```

必须修改为：
```swift
Text("删除账户".localized)  // ✅ 会响应语言变化
```

### 3. Alert 和 Sheet 中的文本

Alert 和 Sheet 也需要本地化：

```swift
.alert("确认删除".localized, isPresented: $showAlert) {
    Button("取消".localized, role: .cancel) { }
    Button("确定".localized) { }
} message: {
    Text("确定要删除吗？".localized)
}
```

### 4. 系统语言回退

如果选择"跟随系统"，但系统语言不在支持列表中（如日语）：
- App 会回退到 Xcode 项目中设置的 `developmentRegion`（现在是 `zh-Hans`）
- 建议在 Localizable.xcstrings 中添加更多语言支持

---

## 🚀 快速上手示例

### 示例 1: 修改 ProfileTabView 的退出按钮

**之前:**
```swift
Button(action: {
    showLogoutAlert = true
}) {
    HStack {
        Image(systemName: "rectangle.portrait.and.arrow.right")
        Text("退出登录")
        Spacer()
    }
}
```

**修改后:**
```swift
@ObservedObject private var languageManager = LanguageManager.shared

Button(action: {
    showLogoutAlert = true
}) {
    HStack {
        Image(systemName: "rectangle.portrait.and.arrow.right")
        Text("退出登录".localized)  // ← 添加 .localized
        Spacer()
    }
}
```

### 示例 2: 修改 Alert 对话框

**之前:**
```swift
.alert("确认退出", isPresented: $showLogoutAlert) {
    Button("取消", role: .cancel) { }
    Button("退出", role: .destructive) { ... }
} message: {
    Text("确定要退出登录吗？")
}
```

**修改后:**
```swift
.alert("确认退出".localized, isPresented: $showLogoutAlert) {
    Button("取消".localized, role: .cancel) { }
    Button("退出".localized, role: .destructive) { ... }
} message: {
    Text("确定要退出登录吗？".localized)
}
```

---

## 📊 实施进度

- ✅ LanguageManager 已创建
- ✅ String Extension 已实现
- ✅ ProfileTabView 语言切换 UI 已添加
- ✅ UserDefaults 持久化已实现
- ✅ Localizable.xcstrings 已包含 74 个翻译
- ⏳ 现有视图的本地化（需要逐步应用）

---

## 🔗 相关文件

- `earth Lord/Managers/LanguageManager.swift` - 语言管理器
- `earth Lord/Views/Tabs/ProfileTabView.swift` - 设置页面（包含语言切换 UI）
- `Localizable.xcstrings` - 本地化字符串资源

---

**最后更新:** 2026-01-03
**下一步:** 在 Xcode 中测试语言切换功能，逐步将现有视图的文本本地化
