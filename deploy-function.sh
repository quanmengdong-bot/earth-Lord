#!/bin/bash

# 🚀 Supabase Edge Function 部署脚本
# 用于部署 delete-account 函数

echo "🚀 开始部署 delete-account 边缘函数..."
echo ""

# 检查是否在正确的目录
if [ ! -d "supabase/functions/delete-account" ]; then
    echo "❌ 错误: 找不到 supabase/functions/delete-account 目录"
    echo "请确保在项目根目录运行此脚本"
    exit 1
fi

echo "📁 检测到函数目录"
echo ""

# 检查 Supabase CLI 是否安装
if ! command -v supabase &> /dev/null; then
    echo "⚠️  Supabase CLI 未安装"
    echo ""
    echo "请选择安装方式："
    echo ""
    echo "方式 1: 使用 npm（推荐）"
    echo "  npm install -g supabase"
    echo ""
    echo "方式 2: 使用 Homebrew"
    echo "  brew install supabase/tap/supabase"
    echo ""
    echo "方式 3: 使用 npx（无需安装）"
    echo "  npx supabase login"
    echo "  npx supabase link --project-ref uxkyrcyyuxtvgasqplua"
    echo "  npx supabase functions deploy delete-account"
    echo ""
    exit 1
fi

echo "✅ Supabase CLI 已安装"
echo ""

# 检查是否已登录
echo "🔐 检查登录状态..."
if ! supabase projects list &> /dev/null; then
    echo "❌ 未登录 Supabase"
    echo ""
    echo "请先登录："
    echo "  supabase login"
    echo ""
    exit 1
fi

echo "✅ 已登录 Supabase"
echo ""

# 检查是否已链接项目
echo "🔗 检查项目链接状态..."
if [ ! -f ".supabase/config.toml" ]; then
    echo "⚠️  项目未链接"
    echo ""
    read -p "是否现在链接项目? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        supabase link --project-ref uxkyrcyyuxtvgasqplua
    else
        echo "取消部署"
        exit 1
    fi
fi

echo "✅ 项目已链接"
echo ""

# 部署函数
echo "🚀 开始部署函数..."
echo ""
supabase functions deploy delete-account

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 函数部署成功！"
    echo ""
    echo "📍 函数 URL:"
    echo "https://uxkyrcyyuxtvgasqplua.supabase.co/functions/v1/delete-account"
    echo ""
    echo "📊 查看日志:"
    echo "supabase functions logs delete-account"
    echo ""
else
    echo ""
    echo "❌ 函数部署失败"
    echo ""
    echo "请检查错误信息并重试"
    exit 1
fi
