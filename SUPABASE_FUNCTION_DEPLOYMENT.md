# 🚀 Supabase 边缘函数部署指南

**函数名称:** delete-account
**功能:** 删除用户账户
**创建时间:** 2026-01-02

---

## 📋 函数说明

### 功能特性
- ✅ 验证请求者身份（JWT Token）
- ✅ 使用 service_role 权限删除用户
- ✅ 详细的中文日志输出
- ✅ 完整的错误处理
- ✅ CORS 支持

### 安全特性
- ✅ 只能删除自己的账户（通过 JWT 验证）
- ✅ 使用 service_role key 确保删除权限
- ✅ 详细的操作日志用于审计

---

## 🛠️ 部署步骤

### 前置条件

#### 1. 安装 Supabase CLI
```bash
# macOS (使用 Homebrew)
brew install supabase/tap/supabase

# 或者使用 npm
npm install -g supabase

# 验证安装
supabase --version
```

#### 2. 登录 Supabase
```bash
# 登录到 Supabase
supabase login

# 会自动打开浏览器进行授权
```

---

### 步骤 1: 链接到你的 Supabase 项目

```bash
# 进入项目目录
cd "/Users/fuerxiyuedemengdong/Desktop/earth Lord"

# 链接到远程项目
supabase link --project-ref uxkyrcyyuxtvgasqplua

# 会提示输入数据库密码
# 密码可以在 Supabase Dashboard → Settings → Database 中找到或重置
```

---

### 步骤 2: 部署边缘函数

```bash
# 部署 delete-account 函数
supabase functions deploy delete-account

# 部署成功后会显示函数 URL:
# https://uxkyrcyyuxtvgasqplua.supabase.co/functions/v1/delete-account
```

---

### 步骤 3: 设置环境变量（可选）

如果函数需要额外的环境变量，可以使用：

```bash
# 设置单个环境变量
supabase secrets set MY_SECRET=my-secret-value

# 从文件批量设置
supabase secrets set --env-file supabase/functions/.env
```

**注意:** `SUPABASE_URL` 和 `SUPABASE_SERVICE_ROLE_KEY` 等内置变量会自动注入，无需手动设置。

---

## 🧪 测试函数

### 方法 1: 使用 curl 测试

```bash
# 获取你的访问令牌（从应用中登录后获取）
ACCESS_TOKEN="your_jwt_token_here"

# 调用函数
curl -X POST \
  'https://uxkyrcyyuxtvgasqplua.supabase.co/functions/v1/delete-account' \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

### 方法 2: 在应用中调用

在 iOS 应用中添加删除账户功能：

```swift
// AuthManager.swift 中添加方法

/// 删除用户账户
func deleteAccount() async throws {
    print("🗑️ 开始删除账户...")

    // 获取当前会话的访问令牌
    let session = try await supabase.auth.session
    let accessToken = session.accessToken

    // 调用边缘函数
    let url = URL(string: "https://uxkyrcyyuxtvgasqplua.supabase.co/functions/v1/delete-account")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw NSError(domain: "DeleteAccount", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的响应"])
    }

    if httpResponse.statusCode == 200 {
        print("✅ 账户删除成功")
        // 清空本地状态
        await signOut()
    } else {
        let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
        print("❌ 删除账户失败: \(errorMessage)")
        throw NSError(domain: "DeleteAccount", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }
}
```

---

## 📊 查看函数日志

### 实时查看日志
```bash
# 实时查看函数日志
supabase functions logs delete-account

# 持续监听（类似 tail -f）
supabase functions logs delete-account --follow
```

### 在 Supabase Dashboard 查看
```
1. 访问 https://supabase.com/dashboard/project/uxkyrcyyuxtvgasqplua
2. 左侧菜单选择 "Edge Functions"
3. 选择 "delete-account"
4. 点击 "Logs" 标签
```

---

## 🔍 函数工作流程

### 1. 请求流程
```
客户端 → 发送 DELETE 请求 + JWT Token
   ↓
边缘函数接收请求
   ↓
验证 JWT Token（使用 SUPABASE_ANON_KEY）
   ↓
获取当前用户信息
   ↓
使用 SUPABASE_SERVICE_ROLE_KEY 删除用户
   ↓
返回成功响应
```

### 2. 日志输出
```
🚀 开始处理删除账户请求...
🔑 获取到 Authorization header
⚙️ Supabase 配置已加载
✅ 用户身份验证成功: user@example.com (ID: xxx)
🗑️ 准备删除用户: xxx
✅ 用户账户删除成功: user@example.com
```

---

## ⚠️ 常见问题

### 问题 1: 部署失败 - "Not logged in"
```bash
# 解决方案：重新登录
supabase login
```

### 问题 2: 部署失败 - "Project not linked"
```bash
# 解决方案：链接项目
supabase link --project-ref uxkyrcyyuxtvgasqplua
```

### 问题 3: 函数调用返回 401
**原因：** JWT Token 无效或已过期

**解决方案：**
1. 确保使用有效的访问令牌
2. 检查 Authorization header 格式：`Bearer YOUR_TOKEN`
3. 重新登录获取新的令牌

### 问题 4: 函数调用返回 500
**原因：** 删除用户失败

**解决方案：**
1. 查看函数日志：`supabase functions logs delete-account`
2. 检查 SUPABASE_SERVICE_ROLE_KEY 是否正确配置
3. 确认用户存在且未被删除

---

## 🔒 安全注意事项

### 1. Service Role Key 保护
- ⚠️ **绝对不要**在客户端代码中使用 service_role_key
- ✅ service_role_key 只在边缘函数的服务端环境中使用
- ✅ Supabase 会自动注入环境变量，无需手动配置

### 2. JWT 验证
- ✅ 函数会验证 JWT Token 的有效性
- ✅ 只能删除与 JWT Token 对应的用户账户
- ✅ 无法删除其他用户的账户

### 3. 操作不可逆
- ⚠️ 删除账户是**永久性**操作
- ⚠️ 所有用户数据将被删除
- 建议在客户端添加二次确认

---

## 📝 更新函数

如果需要修改函数代码：

```bash
# 1. 修改代码
vim supabase/functions/delete-account/index.ts

# 2. 重新部署
supabase functions deploy delete-account

# 3. 查看新版本日志
supabase functions logs delete-account --follow
```

---

## 🗑️ 删除函数

如果需要删除函数：

```bash
# 删除远程函数
supabase functions delete delete-account

# 删除本地代码
rm -rf supabase/functions/delete-account
```

---

## 📞 需要帮助？

### 查看文档
- [Supabase Edge Functions 官方文档](https://supabase.com/docs/guides/functions)
- [Supabase CLI 文档](https://supabase.com/docs/reference/cli)
- [Deno 文档](https://deno.land/manual)

### 常用命令
```bash
# 查看所有函数
supabase functions list

# 查看函数详情
supabase functions inspect delete-account

# 本地运行函数（测试）
supabase functions serve delete-account

# 查看帮助
supabase functions --help
```

---

## ✅ 部署检查清单

部署前确认：

- [ ] 已安装 Supabase CLI
- [ ] 已登录 Supabase (`supabase login`)
- [ ] 已链接项目 (`supabase link`)
- [ ] 函数代码已创建 (`supabase/functions/delete-account/index.ts`)
- [ ] 准备好部署 (`supabase functions deploy delete-account`)

部署后验证：

- [ ] 函数部署成功（显示函数 URL）
- [ ] 可以访问函数 URL
- [ ] 函数日志正常输出
- [ ] 测试删除功能工作正常

---

**最后更新:** 2026-01-02
**状态:** ✅ 函数已创建，等待部署
