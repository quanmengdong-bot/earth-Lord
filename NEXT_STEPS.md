# 🎯 下一步操作指南

**更新时间:** 2026-01-02
**状态:** ✅ iOS 集成完成，待部署边缘函数

---

## 📋 已完成的工作

### ✅ 1. Google 登录功能
- ✅ AuthManager 中实现 Google 登录方法
- ✅ earth_LordApp 中添加 URL 回调处理
- ✅ AuthView 中连接 Google 登录按钮
- ⚠️ **待配置:** Google Client ID（需要在 Xcode 中配置）

### ✅ 2. 删除账户功能
- ✅ Supabase 边缘函数代码已创建
- ✅ AuthManager 中实现 deleteAccount() 方法
- ✅ ProfileTabView 中添加删除账户按钮和 UI
- ⚠️ **待部署:** 边缘函数需要部署到 Supabase

---

## 🚀 立即需要完成的任务

### 任务 1: 部署 delete-account 边缘函数

#### 方式一：使用自动化脚本（推荐）

```bash
cd "/Users/fuerxiyuedemengdong/Desktop/earth Lord"
./deploy-function.sh
```

脚本会自动：
1. 检查 Supabase CLI 是否安装
2. 检查登录状态
3. 链接项目
4. 部署函数

#### 方式二：手动部署

```bash
# 1. 安装 Supabase CLI（如果未安装）
npm install -g supabase
# 或者使用 npx（无需安装）

# 2. 登录 Supabase
npx supabase login
# 会打开浏览器进行授权

# 3. 链接项目
npx supabase link --project-ref uxkyrcyyuxtvgasqplua
# 需要输入数据库密码（可在 Supabase Dashboard 重置）

# 4. 部署函数
npx supabase functions deploy delete-account
```

#### 部署成功标志

看到以下输出表示成功：

```
Deploying Function delete-account (edge-runtime)
Function successfully deployed!
URL: https://uxkyrcyyuxtvgasqplua.supabase.co/functions/v1/delete-account
```

---

### 任务 2: 配置 Google Client ID

#### 第 1 步：获取 Client ID

如果还没有 Google Client ID，请按照 `GOOGLE_SIGNIN_SETUP.md` 中的步骤创建。

#### 第 2 步：在 Xcode 中配置

1. 打开 Xcode 项目
2. 选择项目导航器中的 "earth Lord"
3. 选择 "earth Lord" Target
4. 选择 "Info" 标签页

**添加 GIDClientID：**
```
在 "Custom iOS Target Properties" 中：
1. 点击 "+" 按钮
2. Key: GIDClientID
3. Type: String
4. Value: 你的_Client_ID.apps.googleusercontent.com
```

**配置 URL Scheme：**
```
在 "URL Types" 部分：
1. 点击 "+" 添加新的 URL Type
2. Identifier: Google Sign-In
3. URL Schemes: com.googleusercontent.apps.你的_Client_ID
4. Role: Editor
```

#### 第 3 步：测试

```
1. Clean Build Folder (⌘ + Shift + K)
2. 重新运行应用 (⌘ + R)
3. 点击「使用 Google 登录」按钮
4. 查看控制台日志
```

---

## 🧪 测试步骤

### 测试 1: Google 登录

#### 预期流程：
```
1. 打开应用 → 认证页面
2. 点击「使用 Google 登录」
3. 打开 Google 登录界面
4. 选择账号并授权
5. 自动返回应用
6. 自动跳转到主页面
```

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
🏠 显示主页面（已登录）
```

---

### 测试 2: 删除账户

#### 前置条件：
- ✅ 边缘函数已部署
- ✅ 用户已登录

#### 预期流程：
```
1. 进入 Profile 页面
2. 滚动到底部
3. 点击「删除账户」按钮（红色渐变）
4. 确认对话框出现（⚠️ 不可逆警告）
5. 点击「删除」
6. 自动返回登录页面
```

#### 预期日志：

**客户端：**
```
👆 点击删除账户按钮
👆 用户确认删除账户
🗑️ 开始删除账户流程...
🔑 获取访问令牌...
✅ 访问令牌已获取
📡 发送删除请求到边缘函数...
✅ 账户删除成功
📝 删除详情: {...}
🧹 清理本地状态...
✅ 账户删除流程完成
✅ 账户删除成功，自动返回登录页
🔄 isAuthenticated 状态变化: true → false
🔐 显示认证页面（未登录）
```

**边缘函数：**（使用 `npx supabase functions logs delete-account --follow` 查看）
```
🚀 开始处理删除账户请求...
🔑 获取到 Authorization header
⚙️ Supabase 配置已加载
✅ 用户身份验证成功: user@example.com (ID: xxx)
🗑️ 准备删除用户: xxx
✅ 用户账户删除成功: user@example.com
```

---

## ⚠️ 测试注意事项

### 1. 使用测试账户
- ❌ 不要使用重要的生产账户测试删除功能
- ✅ 创建专门的测试账户
- ✅ 确认测试账户可以安全删除

### 2. 删除是永久性的
- ⚠️ 删除账户后无法恢复
- ⚠️ 所有用户数据将被清除
- ✅ 确认这是你想要的行为

### 3. 边缘函数必须部署
- ❌ 如果函数未部署，删除请求会失败
- ✅ 先部署函数再测试删除功能
- ✅ 使用 `npx supabase functions list` 确认函数已部署

---

## 📊 查看日志

### 客户端日志（Xcode）
```
1. 运行应用 (⌘ + R)
2. 打开控制台 (⌘ + Shift + C)
3. 执行操作
4. 查看日志输出
```

### 边缘函数日志
```bash
# 实时查看
npx supabase functions logs delete-account --follow

# 查看最近的日志
npx supabase functions logs delete-account
```

### Supabase Dashboard
```
1. 访问 https://supabase.com/dashboard/project/uxkyrcyyuxtvgasqplua
2. 左侧菜单选择 "Edge Functions"
3. 选择 "delete-account"
4. 点击 "Logs" 标签
```

---

## 🔍 故障排查

### 问题 1: Google 登录点击无反应

**检查：**
1. Xcode 项目设置中 GIDClientID 是否配置
2. 控制台是否显示「❌ 未配置 Google Client ID」

**解决：**
1. 在 Xcode → Target → Info 中添加 GIDClientID
2. Clean Build 并重新运行

---

### 问题 2: 删除账户返回 404

**症状：**
```
❌ 删除账户失败 (HTTP 404): Not Found
```

**原因：** 边缘函数未部署

**解决：**
```bash
npx supabase functions deploy delete-account
```

---

### 问题 3: 删除账户返回 401

**症状：**
```
❌ 删除账户失败 (HTTP 401): 无效的身份验证令牌
```

**原因：** 用户未登录或令牌过期

**解决：**
1. 确认用户已登录
2. 重新登录获取新令牌
3. 重试删除操作

---

## ✅ 完成检查清单

### Google 登录
- [ ] Google Client ID 已在 Xcode 中配置
- [ ] URL Scheme 已配置
- [ ] 测试登录成功
- [ ] 查看完整日志输出

### 删除账户
- [ ] 边缘函数已部署
- [ ] 可以访问函数 URL
- [ ] 测试删除功能成功
- [ ] 查看客户端和服务端日志

---

## 📞 需要帮助？

### 参考文档
- `GOOGLE_SIGNIN_SETUP.md` - Google 登录配置指南
- `SUPABASE_FUNCTION_DEPLOYMENT.md` - 边缘函数部署指南
- `DELETE_ACCOUNT_INTEGRATION.md` - 删除账户集成指南
- `DEBUGGING_GUIDE.md` - 调试指南

### 快速命令
```bash
# 部署函数
./deploy-function.sh

# 查看函数日志
npx supabase functions logs delete-account --follow

# 查看函数列表
npx supabase functions list

# 测试函数（使用 curl）
curl -X POST \
  'https://uxkyrcyyuxtvgasqplua.supabase.co/functions/v1/delete-account' \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

**最后更新:** 2026-01-02
**下一步:** 部署边缘函数 + 配置 Google Client ID
