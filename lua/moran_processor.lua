-- moran_processor.lua
-- Synopsis: 适用于魔然方案默认模式的按键处理器
-- Author: ksqsf
-- License: MIT license
-- Version: 0.6.0

-- 主要功能：
-- 1. 选择第二个首选项，但可用于跳过 emoji 滤镜产生的候选
-- 2. 快速切换强制切分
-- 3. 快速取出/放回被吞掉的辅助码
-- 4. shorthand 略码
-- 4. Ctrl-S 在两个字集间快速切换

-- ChangeLog:
--  0.6.0: 增加 Ctrl-S
--  0.5.1: 优化快捷键 consume 逻辑
--  0.5.0: 重构强制切分，增加 4单字-2 => 3-3 规则
--  0.4.4: 允许 Ctrl+L 拆开四码
--  0.4.3: 修复 Ctrl+L 的单字判别条件
--  0.4.2: 放松取出辅助码的条件，Ctrl+O 用于取出辅助码
--  0.4.1: Ctrl+L 增加对 yyxxo 的支持
--  0.4.0: 增加固定格式略码功能
--  0.3.0: 增加取出/放回被吞掉的辅助码的能力
--  0.2.0: 增加快速切换切分的能力，因而从 moran_semicolon_processor 更名为 moran_processor
--  0.1.5: 修复获取 candidate_count 的逻辑
--  0.1.4: 数字也增加到条件里

local moran = require("moran")

local kRejected = 0
local kAccepted = 1
local kNoop = 2
local kConsumingNoop = 3  -- 只要有候选窗，就不应该把快捷键传递给下层程序

local function semicolon_processor(key_event, env)
    if key_event.keycode ~= 0x3B then
        return kNoop
    end

    local context = env.engine.context
    local composition = context.composition
    if composition:empty() then
        return kNoop
    end

    local segment = composition:back()
    local menu = segment.menu
    local page_size = env.engine.schema.page_size

    -- Special cases: for 'ovy' and 快符, just send ';'
    if context.input:find('^ovy') or context.input:find('^;') then
        return kNoop
    end

    -- Special case: if there is only one candidate, just select it!
    local candidate_count = menu:prepare(page_size)
    if candidate_count == 1 then
        context:select(0)
        return kAccepted
    end

    -- If it is not the first page, simply send 2.
    local selected_index = segment.selected_index
    if selected_index >= page_size then
        local page_num = math.floor(selected_index / page_size)
        context:select(page_num * page_size + 1)
        return kAccepted
    end

    -- First page: do something more sophisticated.
    local i = 1
    while i < page_size do
        local cand = menu:get_candidate_at(i)
        if cand == nil then
            break
        end
        local cand_text = cand.text
        local codepoint = utf8.codepoint(cand_text, 1)
        if moran.unicode_code_point_is_chinese(codepoint) -- 汉字
            or (codepoint >= 97 and codepoint <= 122)      -- a-z
            or (codepoint >= 65 and codepoint <= 90)       -- A-Z
            or (codepoint >= 48 and codepoint <= 57 and cand.type ~= "simplified") -- 0-9
        then
            context:select(i)
            return kAccepted
        end
        i = i + 1
    end

    -- No good candidates found. Just select the second candidate.
    context:select(1)
    return kAccepted
end

--| 使用快捷键从前一段「偷」出辅助码。
--
-- 例如，想输入「没法动」，键入 mz'fa'dsl，但输出是「没发动」。
-- 此时若选了「没法」二字，d 会被吞掉。按下该处理器的快捷键，可以把 d 再次偷出来。
local function steal_auxcode_processor(key_event, env)
    -- ctrl+l, ctrl+o
    if not (key_event:ctrl() and (key_event.keycode == 0x6c or key_event.keycode == 0x6f)) then
        return kNoop
    end

    local ctx = env.engine.context
    local composition = ctx.composition
    local segmentation = composition:toSegmentation()
    local segs = segmentation:get_segments()
    local n = #segs
    if n == 0 then
        return kNoop
    elseif n == 1 then
        return kConsumingNoop
    end

    -- n >= 2
    local stealer = segs[n]
    local stealee = segs[n-1]
    if stealee:has_tag("_moran_stealee") then
        ctx.input = ctx.input:sub(1, stealer._start) .. ctx.input:sub(stealer._start + 2)
        stealee.tags = stealee.tags - Set({"_moran_stealee"})
        return kAccepted
    end
    if not (stealee.status == 'kSelected' or stealee.status == 'kConfirmed') then
        return kConsumingNoop
    end
    local stealee_cand = stealee:get_selected_candidate()
    local auxcode = stealee_cand.preedit:match("[a-z][a-z][a-z]?([a-z])$")
    if not auxcode then
        return kConsumingNoop
    end
    ctx.input = ctx.input:sub(1, stealer._start) .. auxcode .. ctx.input:sub(stealer._start + 1)
    stealee.tags = stealee.tags + Set({"_moran_stealee"})
    return kAccepted
end

local SEGMENTATION_PATTERNS = {
    [4] = {
        {"^[a-z][a-z]'[a-z][a-z]$", {4}},   -- 2-2   => 4
        {"^[a-z][a-z][a-z][a-z]$", {2, 2}}, -- 4单字 => 2-2
    },
    [5] = {
        {"^[a-z][a-z][ '][a-z][a-z][a-z]$", {3, 2}},  -- 2-3 => 3-2
        {"^[a-z][a-z][a-z][ '][a-z][a-z]$", {2, 3}},  -- 3-2 => 2-3
        {"^[a-z][a-z][a-z][a-z]o$", {2, 3}},          -- 5单字 => 2-3
    },
    [6] = {
        {"^[a-z][a-z][ '][a-z][a-z][ '][a-z][a-z]$", {3, 3}},  -- 2-2-2   => 3-3
        {"^[a-z][a-z][a-z][ '][a-z][a-z][a-z]$", {2, 2, 2}},   -- 3-3     => 2-2-2
        {"^[a-z][a-z][a-z][a-z][ '][a-z][a-z]$", {3, 3}},      -- 4单字-2 => 3-3
        {"^[a-z][a-z][ '][a-z][a-z][a-z][a-z]$", {3, 3}},      -- 4单字-2 => 3-3
    },
    [7] = {
        {"^[a-z][a-z][ '][a-z][a-z][ '][a-z][a-z][a-z]", {2, 3, 2}}, -- 2-2-3 => 2-3-2
        {"^[a-z][a-z][ '][a-z][a-z][a-z][ '][a-z][a-z]", {3, 2, 2}}, -- 2-3-2 => 3-2-2
        {"^[a-z][a-z][a-z][ '][a-z][a-z][ '][a-z][a-z]", {2, 2, 3}}, -- 3-2-2 => 2-2-3
    },
}

local function force_segmentation_processor(key_event, env)
    if not (key_event:ctrl() and key_event.keycode == 0x6c) then  -- ctrl+l
        return kNoop
    end

    local composition = env.engine.context.composition
    if composition:empty() then
        return kNoop
    end

    local seg = composition:back()
    local cand = seg:get_selected_candidate()
    local preedit = ""
    if cand ~= nil then
        preedit = cand.preedit
    end

    local ctx = env.engine.context
    local input = ctx.input:sub(seg._start + 1, seg._end)
    local raw = input:gsub("'", "")  -- 不带 ' 分隔符的输入
    local patterns = SEGMENTATION_PATTERNS[#raw]

    if patterns == nil then
        return kConsumingNoop
    end
    local subst = nil
    for _, pattern in ipairs(patterns) do
        local re = pattern[1]
        if input:match(re) ~= nil or preedit:match(re) ~= nil then
            subst = pattern[2]
            break
        end
    end
    if subst == nil then
        return kConsumingNoop
    end

    local head = ctx.input:sub(1, seg._start)
    local body = ""
    local tail = ctx.input:sub(seg._end + 1, -1)
    local i = 1
    for _, seglen in ipairs(subst) do
        local seg = raw:sub(i, i + seglen - 1)
        if i == 1 then
            body = body .. seg
        else
            body = body .. "'" .. seg
        end
        i = i + seglen
    end
    ctx.input = head .. body .. tail

    return kAccepted
end

local shorthands = {
    [string.byte("B")] = function(env, s)
        return s .. "不" .. s
    end,
    [string.byte("L")] = function(env, s)
        return s .. "了" .. s
    end,
    [string.byte("Y")] = function(env, s)
        return s .. "一" .. s
    end,
    [string.byte("V")] = function(env, s)
        if env.engine.context:get_option("std_s2tw") or env.engine.context:get_option("std_s2tw") then
            return s .. "著" .. s .. "著"
        else
            return s .. "着" .. s .. "着"
        end
    end,
    [string.byte("Q")] = function(env, s)
        if env.engine.context:get_option("std_s") or env.engine.context:get_option("std_s2t") then
            return s .. "来" .. s .. "去"
        else
            return s .. "来" .. s .. "去"
        end
    end,
}

local function shorthand_processor(key_event, env)
    local shf = shorthands[key_event.keycode]
    if not key_event:shift() or shf == nil then
        return kNoop
    end

    local composition = env.engine.context.composition
    if composition:empty() then
        return kNoop
    end

    local segment = composition:back()
    local cand = segment:get_selected_candidate()
    local text = cand.text
    env.engine:commit_text(shf(env, text))
    env.engine.context:clear()
    return kAccepted
end

local function variant_toggle_processor(key_event, env)
    if not (key_event:ctrl() and key_event.keycode == 0x73) then
        return kNoop
    end
    local ctx = env.engine.context
    if ctx.composition:empty() then  -- 无候选窗时不响应 Ctrl-S
        return kNoop
    end

    local v1 = env.variants[1]
    local v2 = env.variants[2]
    if ctx:get_option(v1) then
        ctx:set_option(v1, false)
        ctx:set_option(v2, true)
    elseif ctx:get_option(v2) then
        ctx:set_option(v2, false)
        ctx:set_option(v1, true)
    else
        -- 都不是时也跳回 v1
        ctx:set_option(v2, false)
        ctx:set_option(v1, true)
    end

    return kAccepted
end

return {
    init = function(env)
        env.processors = {
            semicolon_processor,
            force_segmentation_processor,
            steal_auxcode_processor,
            variant_toggle_processor,
        }

        local cfg = env.engine.schema.config
        if cfg:get_bool("moran/shorthands") then
            table.insert(env.processors, shorthand_processor)
        end

        -- 用户启用的字集
        local switches = cfg:get_list("switches")
        if switches then
            for i = 0, switches.size - 1 do
                local switch = switches:get_at(i)
                local switch_map = switch and switch:get_map()
                local options = switch_map and switch_map:get("options")
                local variants = options and options:get_list()
                if variants
                    and variants.size >= 2
                    and variants:get_at(0).type == "kScalar"
                    and variants:get_at(0):get_value():get_string():match("^std_")
                    and variants:get_at(1).type == "kScalar"
                    and variants:get_at(1):get_value():get_string():match("^std_")
                then
                    env.variants = {
                        variants:get_at(0):get_value():get_string(),
                        variants:get_at(1):get_value():get_string(),
                    }
                    break
                end
            end
        end
        if not env.variants then
            log.error('moran_processor: switches 中未找到字形变体列表, 如 "std_s2t"! 回落至默认值 [std_s, std_s2t]')
            env.variants = { "std_s", "std_s2t" }
        end
        -- print('v1 = ' .. env.variants[1])
        -- print('v2 = ' .. env.variants[2])
    end,

    fini = function(env)
    end,

    func = function(key_event, env)
        if key_event:release() then
            return kNoop
        end

        local should_consume = false
        for _, processor in pairs(env.processors) do
            local res = processor(key_event, env)
            if res == kAccepted or res == kRejected then
                return res
            elseif res == kConsumingNoop then
                should_consume = true
            end
        end
        if key_event:ctrl() and should_consume then
            return kAccepted
        end

        return kNoop
    end
}

-- Local Variables:
-- lua-indent-level: 4
-- End:
