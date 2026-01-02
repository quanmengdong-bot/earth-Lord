# 📱 iOS 客户端集成 - 删除账户功能

**更新时间:** 2026-01-02

---

## 🎯 在 AuthManager 中添加删除账户方法

### 步骤 1: 添加删除账户方法

打开 `earth Lord/Managers/AuthManager.swift`，在文件末尾添加以下方法：

```swift
// MARK: - 删除账户

/// 删除用户账户
/// - Note: 这是一个不可逆操作，会永久删除用户数据
func deleteAccount() async throws {
    print("🗑️ 开始删除账户流程...")
    isLoading = true
    errorMessage = nil

    do {
        // 1. 获取当前会话的访问令牌
        print("🔑 获取访问令牌...")
        let session = try await supabase.auth.session
        let accessToken = session.accessToken

        print("✅ 访问令牌已获取")

        // 2. 构建请求
        let functionUrl = URL(string: "https://uxkyrcyyuxtvgasqplua.supabase.co/functions/v1/delete-account")!
        var request = URLRequest(url: functionUrl)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        print("📡 发送删除请求到边缘函数...")

        // 3. 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "DeleteAccount",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "无效的响应"]
            )
        }

        // 4. 处理响应
        if httpResponse.statusCode == 200 {
            print("✅ 账户删除成功")

            // 解析响应
            if let json = try? JSONDecoder().decode([String: AnyCodable].self, from: data) {
                print("📝 删除详情: \(json)")
            }

            // 清空本地状态
            print("🧹 清理本地状态...")
            isAuthenticated = false
            needsPasswordSetup = false
            currentUser = nil
            otpSent = false
            otpVerified = false

            print("✅ 账户删除流程完成")

        } else {
            // 解析错误信息
            var errorMsg = "删除账户失败"

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? String {
                errorMsg = error
            }

            print("❌ 删除账户失败 (HTTP \(httpResponse.statusCode)): \(errorMsg)")

            throw NSError(
                domain: "DeleteAccount",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMsg]
            )
        }

    } catch {
        print("❌ 删除账户异常: \(error.localizedDescription)")
        errorMessage = "删除账户失败: \(error.localizedDescription)"
        throw error
    }

    isLoading = false
}

// 辅助类型，用于解析 JSON
struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        }
    }
}
```

---

## 🎨 在 ProfileTabView 中添加删除按钮

### 步骤 2: 更新 ProfileTabView

打开 `earth Lord/Views/Tabs/ProfileTabView.swift`，添加删除账户按钮：

```swift
// 在 ProfileTabView 中添加以下代码

@State private var showDeleteConfirmation = false
@State private var showDeleteError = false
@State private var deleteErrorMessage = ""

// 在视图中添加删除按钮（建议放在退出登录按钮下方）
var body: some View {
    VStack {
        // ... 现有代码 ...

        // 退出登录按钮
        Button {
            Task {
                await authManager.signOut()
            }
        } label: {
            Text("退出登录")
                .foregroundColor(.red)
        }

        Spacer().frame(height: 20)

        // 删除账户按钮
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("删除账户")
            }
            .foregroundColor(.red)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
        }
        .alert("确认删除账户", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("此操作不可逆！删除后您的所有数据将永久丢失。")
        }
        .alert("删除失败", isPresented: $showDeleteError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage)
        }
    }
}

// 删除账户方法
private func deleteAccount() async {
    print("👆 用户确认删除账户")

    do {
        try await authManager.deleteAccount()
        print("✅ 账户删除成功，自动返回登录页")
        // 成功后会自动返回登录页（因为 isAuthenticated = false）
    } catch {
        print("❌ 删除账户失败: \(error.localizedDescription)")
        deleteErrorMessage = error.localizedDescription
        showDeleteError = true
    }
}
```

---

## 🧪 测试流程

### 完整测试步骤

#### 1. 部署边缘函数
```bash
# 进入项目目录
cd "/Users/fuerxiyuedemengdong/Desktop/earth Lord"

# 运行部署脚本
./deploy-function.sh

# 或者手动部署
npx supabase login
npx supabase link --project-ref uxkyrcyyuxtvgasqplua
npx supabase functions deploy delete-account
```

#### 2. 在应用中测试

##### 步骤 A: 创建测试账户
```
1. 运行应用
2. 注册一个新账户（用于测试删除）
3. 完成注册流程
4. 确认登录成功
```

##### 步骤 B: 测试删除功能
```
1. 进入 Profile 页面
2. 点击「删除账户」按钮
3. 在确认对话框中点击「删除」
4. 观察控制台日志
5. 确认应用自动返回登录页
```

#### 3. 预期日志

**客户端日志:**
```
👆 用户确认删除账户
🗑️ 开始删除账户流程...
🔑 获取访问令牌...
✅ 访问令牌已获取
📡 发送删除请求到边缘函数...
✅ 账户删除成功
🧹 清理本地状态...
✅ 账户删除流程完成
✅ 账户删除成功，自动返回登录页
🔄 isAuthenticated 状态变化: true → false
🔐 显示认证页面（未登录）
```

**边缘函数日志:**
```
🚀 开始处理删除账户请求...
🔑 获取到 Authorization header
⚙️ Supabase 配置已加载
✅ 用户身份验证成功: test@example.com (ID: xxx-xxx-xxx)
🗑️ 准备删除用户: xxx-xxx-xxx
✅ 用户账户删除成功: test@example.com
```

---

## 🔍 查看边缘函数日志

### 实时监控
```bash
# 持续查看日志
npx supabase functions logs delete-account --follow

# 或者在 Supabase Dashboard 查看
# https://supabase.com/dashboard/project/uxkyrcyyuxtvgasqplua/functions
```

---

## ⚠️ 常见问题

### 问题 1: 删除请求返回 401

**症状:**
```
❌ 删除账户失败 (HTTP 401): 无效的身份验证令牌
```

**原因:** 访问令牌无效或已过期

**解决方案:**
1. 确保用户已登录
2. 检查 `supabase.auth.session` 是否返回有效会话
3. 重新登录获取新的令牌

---

### 问题 2: 删除请求返回 500

**症状:**
```
❌ 删除账户失败 (HTTP 500): 服务器内部错误
```

**原因:** 边缘函数执行失败

**解决方案:**
1. 查看边缘函数日志：`npx supabase functions logs delete-account`
2. 检查 service_role_key 配置
3. 确认函数已正确部署

---

### 问题 3: 函数未部署

**症状:**
```
❌ 删除账户异常: The Internet connection appears to be offline
```

**原因:** 函数未部署或 URL 错误

**解决方案:**
1. 运行部署脚本：`./deploy-function.sh`
2. 确认函数 URL 正确
3. 检查网络连接

---

## 🔒 安全注意事项

### 1. 二次确认
- ✅ 使用 `.alert` 对话框进行二次确认
- ✅ 明确提示操作不可逆
- ✅ 使用红色警告色提醒用户

### 2. 权限验证
- ✅ 边缘函数验证 JWT Token
- ✅ 只能删除自己的账户
- ✅ 使用 service_role_key 确保删除权限

### 3. 操作日志
- ✅ 客户端详细日志
- ✅ 服务端详细日志
- ✅ 便于问题排查和审计

---

## 📊 API 响应格式

### 成功响应 (200)
```json
{
  "success": true,
  "message": "账户已成功删除",
  "deletedUserId": "xxx-xxx-xxx",
  "deletedUserEmail": "user@example.com"
}
```

### 错误响应 (401)
```json
{
  "error": "无效的身份验证令牌"
}
```

### 错误响应 (500)
```json
{
  "error": "删除账户失败",
  "details": "User not found"
}
```

---

## ✅ 完成检查清单

集成前确认：

- [ ] 边缘函数已部署
- [ ] AuthManager 中已添加 deleteAccount() 方法
- [ ] ProfileTabView 中已添加删除按钮
- [ ] 已添加二次确认对话框

测试后验证：

- [ ] 可以成功删除账户
- [ ] 删除后自动返回登录页
- [ ] 删除后无法再用该账户登录
- [ ] 客户端和服务端日志正常
- [ ] 错误情况处理正确

---

**最后更新:** 2026-01-02
**状态:** ✅ 集成指南已创建，等待实施
