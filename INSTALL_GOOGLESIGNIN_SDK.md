# 📦 安装 GoogleSignIn SDK

**更新时间:** 2026-01-02

---

## 🎯 当前状态

✅ **代码已准备好** - Google 登录代码使用条件编译，可以在没有 SDK 的情况下正常编译
⚠️ **SDK 未安装** - 需要安装 GoogleSignIn SDK 才能使用 Google 登录功能

---

## 📝 安装方式

### 方式 1: 使用 Swift Package Manager（推荐）

#### 第 1 步：在 Xcode 中添加包

```
1. 打开 Xcode 项目
2. 选择菜单: File → Add Package Dependencies...
3. 在搜索框中输入: https://github.com/google/GoogleSignIn-iOS
4. 点击 "Add Package"
5. 选择版本: 建议使用最新版本（7.x 或更高）
6. 选择 Target: earth Lord
7. 确保勾选 "GoogleSignIn"
8. 点击 "Add Package"
```

#### 第 2 步：验证安装

```
1. 在项目导航器中查看
2. 应该看到 "Package Dependencies" 下有 "GoogleSignIn-iOS"
3. 重新编译项目 (⌘ + B)
4. 应该不再有 "No such module 'GoogleSignIn'" 错误
```

---

### 方式 2: 使用 CocoaPods

#### 第 1 步：创建 Podfile

如果还没有 Podfile，在项目根目录创建：

```ruby
# Podfile
platform :ios, '15.0'
use_frameworks!

target 'earth Lord' do
  # GoogleSignIn SDK
  pod 'GoogleSignIn', '~> 7.0'
end
```

#### 第 2 步：安装依赖

```bash
cd "/Users/fuerxiyuedemengdong/Desktop/earth Lord"

# 安装 CocoaPods（如果未安装）
sudo gem install cocoapods

# 安装依赖
pod install
```

#### 第 3 步：使用 Workspace

```
⚠️ 安装后需要打开 .xcworkspace 文件，而不是 .xcodeproj

1. 关闭当前的 Xcode 项目
2. 打开 "earth Lord.xcworkspace"
3. 重新编译项目
```

---

### 方式 3: 手动添加框架

#### 第 1 步：下载 SDK

```
1. 访问: https://github.com/google/GoogleSignIn-iOS/releases
2. 下载最新版本的 ZIP 文件
3. 解压缩
```

#### 第 2 步：添加到项目

```
1. 在 Xcode 中选择项目
2. 选择 "earth Lord" Target
3. 选择 "General" 标签页
4. 滚动到 "Frameworks, Libraries, and Embedded Content"
5. 点击 "+" 添加框架
6. 选择下载的 GoogleSignIn.framework
7. Embed 选择 "Embed & Sign"
```

---

## ✅ 验证安装

### 检查 1: 编译成功

```bash
# 在 Xcode 中
Product → Clean Build Folder (⌘ + Shift + K)
Product → Build (⌘ + B)

# 应该成功编译，没有 "No such module" 错误
```

### 检查 2: 运行应用

```
1. 运行应用 (⌘ + R)
2. 进入认证页面
3. 点击「使用 Google 登录」按钮
4. 查看控制台日志
```

### 预期日志（SDK 已安装）：

```
👆 点击 Google 登录按钮
🚀 开始 Google 登录流程...
📱 获取根视图控制器成功
🔑 Google Client ID 已配置
⚙️ Google Sign-In 配置完成
🔐 打开 Google 登录界面...
```

### 预期日志（SDK 未安装）：

```
👆 点击 Google 登录按钮
⚠️ GoogleSignIn SDK 未安装
```

---

## 🎯 推荐方案

**我推荐使用 Swift Package Manager（方式 1）**，原因：

1. ✅ 无需额外工具（Xcode 内置）
2. ✅ 自动管理依赖版本
3. ✅ 无需修改项目结构
4. ✅ 易于更新和维护
5. ✅ 不需要 .xcworkspace

---

## 🔧 配置 Google Client ID

安装 SDK 后，还需要配置 Google Client ID 才能使用。

详细步骤请参考：**GOOGLE_SIGNIN_SETUP.md**

---

## ⚠️ 常见问题

### 问题 1: "No such module 'GoogleSignIn'"

**原因:** SDK 未安装或未正确链接

**解决方案:**
1. 确认已按上述方式之一安装 SDK
2. Clean Build Folder (⌘ + Shift + K)
3. 重新编译

---

### 问题 2: Swift Package Manager 添加失败

**症状:** 添加包时显示错误

**解决方案:**
```
1. 检查网络连接
2. 确认 Xcode 版本（建议 14.0+）
3. 尝试重新添加包
4. 或者改用 CocoaPods
```

---

### 问题 3: CocoaPods 安装失败

**症状:** `pod install` 失败

**解决方案:**
```bash
# 更新 CocoaPods
sudo gem install cocoapods

# 更新本地仓库
pod repo update

# 重新安装
pod install
```

---

## 📚 官方文档

- [GoogleSignIn-iOS GitHub](https://github.com/google/GoogleSignIn-iOS)
- [Google Sign-In 官方文档](https://developers.google.com/identity/sign-in/ios)
- [Swift Package Manager 文档](https://swift.org/package-manager/)

---

## 🎯 完成后的下一步

1. ✅ 安装 GoogleSignIn SDK
2. ✅ 配置 Google Client ID（见 GOOGLE_SIGNIN_SETUP.md）
3. ✅ 测试 Google 登录功能
4. ✅ 部署删除账户边缘函数（见 NEXT_STEPS.md）

---

**最后更新:** 2026-01-02
**状态:** 等待安装 SDK
