// delete-account Edge Function
// 用于删除用户账户

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // 处理 CORS 预检请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('🚀 开始处理删除账户请求...')

    // 1. 验证请求者身份
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      console.log('❌ 缺少 Authorization header')
      return new Response(
        JSON.stringify({ error: '未授权：缺少身份验证令牌' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    console.log('🔑 获取到 Authorization header')

    // 2. 从环境变量获取 Supabase 配置
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      console.log('❌ Supabase 环境变量未配置')
      return new Response(
        JSON.stringify({ error: '服务器配置错误' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    console.log('⚙️ Supabase 配置已加载')

    // 3. 使用普通权限的客户端验证用户身份
    const supabaseClient = createClient(
      supabaseUrl,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // 获取当前用户信息
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      console.log('❌ 无效的身份验证令牌:', userError?.message)
      return new Response(
        JSON.stringify({ error: '无效的身份验证令牌' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    console.log(`✅ 用户身份验证成功: ${user.email} (ID: ${user.id})`)

    // 4. 使用 service_role 权限删除用户
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey)

    console.log(`🗑️ 准备删除用户: ${user.id}`)

    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
      user.id
    )

    if (deleteError) {
      console.log('❌ 删除用户失败:', deleteError.message)
      return new Response(
        JSON.stringify({
          error: '删除账户失败',
          details: deleteError.message
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    console.log(`✅ 用户账户删除成功: ${user.email}`)

    // 5. 返回成功响应
    return new Response(
      JSON.stringify({
        success: true,
        message: '账户已成功删除',
        deletedUserId: user.id,
        deletedUserEmail: user.email,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('❌ 发生未知错误:', error)
    return new Response(
      JSON.stringify({
        error: '服务器内部错误',
        details: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
