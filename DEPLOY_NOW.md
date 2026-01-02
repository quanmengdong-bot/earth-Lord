# 🚀 立即部署 - 删除账户边缘函数

**创建时间:** 2026-01-02
**状态:** 准备部署

---

## 📦 部署步骤（5 分钟完成）

### 步骤 1: 登录 Supabase（1 分钟）

打开终端，执行：

```bash
cd "/Users/fuerxiyuedemengdong/Desktop/earth Lord"
npx supabase login
```

**会发生什么：**
- 自动打开浏览器
- 显示 Supabase 授权页面
- 点击「Authorize」授权
- 返回终端，显示登录成功

**预期输出：**
```
Finished supabase login.
```

---

### 步骤 2: 链接项目（1 分钟）

```bash
npx supabase link --project-ref uxkyrcyyuxtvgasqplua
```

**会提示输入数据库密码：**
```
Enter your database password:
```

**获取数据库密码的方法：**
1. 访问: https://supabase.com/dashboard/project/uxkyrcyyuxtvgasqplua/settings/database
2. 在 "Database Settings" 页面
3. 找到 "Database password" 部分
4. 点击 "Reset database password" 重置密码（如果忘记了）
5. 复制新密码并粘贴到终端

**预期输出：**
```
Finished supabase link.
```

---

### 步骤 3: 部署函数（2 分钟）

```bash
npx supabase functions deploy delete-account
```

**部署过程：**
```
Deploying Function delete-account (edge-runtime)
Bundling delete-account
Deploying delete-account (4.12 KiB)
Function successfully deployed!
```

**预期输出：**
```
Function URL: https://uxkyrcyyuxtvgasqplua.supabase.co/functions/v1/delete-account
```

---

## ✅ 验证部署

### 方法 1: 查看函数列表

```bash
npx supabase functions list
```

**预期输出：**
```
delete-account
```

### 方法 2: 在 Supabase Dashboard 查看

1. 访问: https://supabase.com/dashboard/project/uxkyrcyyuxtvgasqplua/functions
2. 应该看到 "delete-account" 函数
3. 状态应该是绿色（已部署）

### 方法 3: 测试函数

```bash
# 使用 curl 测试（需要访问令牌）
curl -X POST \
  'https://uxkyrcyyuxtvgasqplua.supabase.co/functions/v1/delete-account' \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

---

## 🧪 在应用中测试

### 前提条件：
- ✅ 边缘函数已部署
- ✅ 用户已登录应用

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

4. **滚动到底部**
   ```
   找到红色的「删除账户」按钮
   ```

5. **点击删除**
   ```
   点击按钮 → 确认对话框 → 点击「删除」
   ```

6. **查看日志**
   ```
   打开 Xcode 控制台 (⌘ + Shift + C)
   ```

### 预期日志输出：

**客户端（Xcode 控制台）：**
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

**边缘函数（Supabase Dashboard 或命令行）：**
```bash
# 查看实时日志
npx supabase functions logs delete-account --follow
```

```
🚀 开始处理删除账户请求...
🔑 获取到 Authorization header
⚙️ Supabase 配置已加载
✅ 用户身份验证成功: user@example.com (ID: xxx)
🗑️ 准备删除用户: xxx
✅ 用户账户删除成功: user@example.com
```

---

## ⚠️ 故障排查

### 问题 1: 登录失败

**症状：** `npx supabase login` 失败

**解决方案：**
```bash
# 方法 1: 使用 access token 登录
# 1. 访问 https://supabase.com/dashboard/account/tokens
# 2. 生成新的 access token
# 3. 执行：
npx supabase login --token YOUR_ACCESS_TOKEN

# 方法 2: 重试
npx supabase login
```

---

### 问题 2: 链接项目失败

**症状：** 数据库密码错误

**解决方案：**
```
1. 访问 Supabase Dashboard
2. Settings → Database
3. Reset database password
4. 复制新密码
5. 重新运行 link 命令
```

---

### 问题 3: 部署失败

**症状：** `npx supabase functions deploy` 报错

**可能原因：**
- 未登录
- 未链接项目
- 网络问题

**解决方案：**
```bash
# 1. 确认登录状态
npx supabase projects list

# 2. 确认项目链接
ls -la .supabase/

# 3. 重新部署
npx supabase functions deploy delete-account
```

---

### 问题 4: 删除功能返回 404

**症状：** 点击删除按钮后提示 404 错误

**原因：** 边缘函数未部署或 URL 错误

**解决方案：**
```bash
# 1. 确认函数已部署
npx supabase functions list

# 2. 如果没有，重新部署
npx supabase functions deploy delete-account

# 3. 验证函数 URL
# 应该是: https://uxkyrcyyuxtvgasqplua.supabase.co/functions/v1/delete-account
```

---

### 问题 5: 删除功能返回 401

**症状：** "无效的身份验证令牌"

**原因：** 用户未登录或令牌过期

**解决方案：**
```
1. 确认用户已登录（在 Profile 页面能看到邮箱）
2. 重新登录
3. 重试删除操作
```

---

## 📊 查看日志

### 客户端日志（Xcode）

```
1. 运行应用
2. 打开控制台：⌘ + Shift + C
3. 执行删除操作
4. 查看详细日志
```

### 边缘函数日志（命令行）

```bash
# 实时监控
npx supabase functions logs delete-account --follow

# 查看最近的日志
npx supabase functions logs delete-account
```

### 边缘函数日志（Dashboard）

```
1. 访问: https://supabase.com/dashboard/project/uxkyrcyyuxtvgasqplua/functions
2. 点击 "delete-account"
3. 选择 "Logs" 标签
4. 查看实时日志
```

---

## 🎯 完整命令总结

```bash
# 进入项目目录
cd "/Users/fuerxiyuedemengdong/Desktop/earth Lord"

# 1. 登录 Supabase
npx supabase login

# 2. 链接项目
npx supabase link --project-ref uxkyrcyyuxtvgasqplua

# 3. 部署函数
npx supabase functions deploy delete-account

# 4. 查看函数列表
npx supabase functions list

# 5. 查看实时日志
npx supabase functions logs delete-account --follow
```

---

## ✅ 部署成功标志

当你看到以下内容时，说明部署成功：

1. ✅ 命令行显示 "Function successfully deployed!"
2. ✅ Dashboard 中看到 delete-account 函数
3. ✅ 测试删除功能正常工作
4. ✅ 查看到完整的日志输出

---

**最后更新:** 2026-01-02
**预计耗时:** 5 分钟
**状态:** 准备执行
