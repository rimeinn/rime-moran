-- Moran Fix Filter
-- Copyright (c) 2024, 2025, 2026 ksqsf
--
-- Ver: 0.3.0
--
-- This file is part of Project Moran
-- Licensed under GPLv3
--
-- 0.3.0: Delegate reordering to moran_reorder_filter.
--
-- 0.2.0: Add `fix_use_dict` option to use "moran_fixed", just like "moran".
--        The old way is still kept, but deprecated and discouraged.
--
-- 0.1.0: added.

local Top = {}

function Top.init(env)
    env.fix_use_dict = env.engine.schema.config:get_bool("moran/fix/use_dict") or false
    if env.fix_use_dict then
        env.fixed = Component.Translator(env.engine, "", "table_translator@fixed")
        env.use_dict_max_length = env.engine.schema.config:get_int("moran/fix/use_dict_max_length") or 3
    end
    env.cache = {}
end

function Top.fini(env)
    env.cache = nil
    collectgarbage()
end

function Top.func(t_input, env)
    if env.fix_use_dict then
        return Top.func_use_dict(t_input, env)
    else
        return Top.func_no_dict(t_input, env)
    end
end

function Top.func_use_dict(t_input, env)
    local context = env.engine.context
    local composition = context.composition
    local segment = composition:back()
    local input = context.input:sub(segment._start + 1, segment._end)

    if #input > env.use_dict_max_length then
        for c in t_input:iter() do
            yield(c)
        end
        return
    end

    local fixed_res = env.fixed:query(input, segment)
    if fixed_res then
        for fc in fixed_res:iter() do
            fc.comment = "`F"
            yield(fc)
        end
    end

    for c in t_input:iter() do
        yield(c)
    end
end

function Top.func_no_dict(t_input, env)
    local input = env.engine.context.input
    local input_len = utf8.len(input)

    -- 只支持一二簡
    if input_len > 2 then
        for cand in t_input:iter() do
            yield(cand)
        end
        return
    end

    local needle = Top.get_needle(env, input)
    if needle == nil or needle == "" then
        for cand in t_input:iter() do
            yield(cand)
        end
        return
    end

    local context = env.engine.context
    local composition = context.composition
    local segment = composition:back()
    local fixed = Candidate("fixed", segment._start, segment._end, needle, "`F")
    yield(fixed)

    for cand in t_input:iter() do
        yield(cand)
    end
end

function Top.get_needle(env, input)
    if env.cache[input] then
        return env.cache[input]
    end
    if input:find("/") then
        return nil
    end
    local val = env.engine.schema.config:get_string("moran/fix/" .. input)
    env.cache[input] = val
    return val
end

return Top

-- Local Variables:
-- lua-indent-level: 4
-- End:
