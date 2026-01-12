-- Day 18: territories 表设置
-- 创建时间: 2026-01-09

-- 第一步：启用 PostGIS 扩展
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 第二步：创建 territories 表（如果不存在）
CREATE TABLE IF NOT EXISTS public.territories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,  -- 允许为空，用户可以稍后命名
    path JSONB NOT NULL,
    polygon GEOGRAPHY(POLYGON, 4326),
    bbox_min_lat DOUBLE PRECISION,
    bbox_max_lat DOUBLE PRECISION,
    bbox_min_lon DOUBLE PRECISION,
    bbox_max_lon DOUBLE PRECISION,
    area DOUBLE PRECISION NOT NULL,
    point_count INTEGER,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 确保 name 字段允许为空（如果表已存在且 name 是 NOT NULL）
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'territories'
        AND column_name = 'name'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.territories ALTER COLUMN name DROP NOT NULL;
    END IF;
END $$;

-- 第三步：创建索引
CREATE INDEX IF NOT EXISTS territories_user_id_idx ON public.territories(user_id);
CREATE INDEX IF NOT EXISTS territories_is_active_idx ON public.territories(is_active);
CREATE INDEX IF NOT EXISTS territories_created_at_idx ON public.territories(created_at);

-- 第四步：启用 RLS
ALTER TABLE public.territories ENABLE ROW LEVEL SECURITY;

-- 第五步：删除旧策略（如果存在）
DROP POLICY IF EXISTS "所有人可查看领地" ON public.territories;
DROP POLICY IF EXISTS "用户只能创建自己的领地" ON public.territories;
DROP POLICY IF EXISTS "用户只能删除自己的领地" ON public.territories;
DROP POLICY IF EXISTS "用户只能更新自己的领地" ON public.territories;

-- 第六步：创建 RLS 策略
-- 1. 所有人可查看领地
CREATE POLICY "所有人可查看领地" ON public.territories
    FOR SELECT USING (true);

-- 2. 用户只能创建自己的领地
CREATE POLICY "用户只能创建自己的领地" ON public.territories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. 用户只能删除自己的领地
CREATE POLICY "用户只能删除自己的领地" ON public.territories
    FOR DELETE USING (auth.uid() = user_id);

-- 4. 用户只能更新自己的领地
CREATE POLICY "用户只能更新自己的领地" ON public.territories
    FOR UPDATE USING (auth.uid() = user_id);
