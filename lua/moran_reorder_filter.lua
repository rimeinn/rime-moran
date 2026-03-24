-- Moran Reorder Filter
-- Copyright (c) 2023, 2024, 2025, 2026 ksqsf
--
-- Ver: 0.3.1
--
-- This file is part of Project Moran
-- Licensed under GPLv3
--
-- 0.3.1: 修復重構引入的 bug。
--
-- 0.3.0: 重構，少許性能優化。
--
-- 0.2.3: 允許單字在4碼輸入時也被重排。
--
-- 0.2.2: 進一步放寬匹配條件，允許多字詞候選被重排。
--
-- 0.2.1: 放寬匹配條件，允許帶輔的候選也被重排。
--
-- 0.2.0: 修復諸多問題。
--
-- 0.1.5: 少許性能優化。
--
-- 0.1.4: 配合 moran_pin。
--
-- 0.1.3: 修復一個導致候選重複輸出的 bug。
--
-- 0.1.2: 配合 show_chars_anyway 設置。從 show_chars_anyway 設置起，
-- fixed 輸出有可能出現在 script 之後！此情況只覆寫 comment 而不做重排。
--
-- 0.1.1: 要求候選項合併時 preedit 也匹配，以防禦一種邊角情況（掛接某
-- 些第三方碼表時可能出現）。
--
-- 0.1.0: 本文件的主要作用是用 script 候選覆蓋對應的 table 候選，從而
-- 解決字頻維護問題。例如：原本用 mau 輸入三簡字「碼」時，該候選是從
-- table 輸出的，不會增加 script 翻譯器用戶詞典的「碼」字的字頻。而長
-- 期使用時，很有可能會使用 mau 鍵入「禡」等較生僻的字，而這些生僻字反
-- 而是從 script 翻譯器輸出的，會增加這些字的字頻。這個問題會導致在長
-- 期使用後，組詞時會導致常用的「碼」反而排在其他生僻字後面。該 filter
-- 的主要作用就是重排 table 和 script 翻譯器輸出，讓簡碼對應的候選也變
-- 成 script 候選，從而解決字頻問題。
--
-- 必須與 moran_express_translator v0.5.0 以上版本聯用。

local Top = {}

function Top.init(env)
    -- At most THRESHOLD smart candidates are subject to reordering,
    -- for performance's sake.
    env.reorder_threshold = 50
    env.quick_code_indicator = env.engine.schema.config:get_string("moran/quick_code_indicator") or "⚡️"
    env.pin_indicator = env.engine.schema.config:get_string("moran/pin/indicator") or "📌"
end

function Top.fini(env)
end

--------------------------------------------------------------------------------
-- 狀態機定義
--
-- 輸入的候選格式是：
--   [pinned]* [fixed1]* smart1{1} [fixed2]* smart2+
--
-- + kCollecting   收集 pinned, fixed1, smart1
-- + kMatching     碰到了 smart2，且還有一些候選等待匹配
-- + kDone         匹配完成，直傳所有剩餘候選
--------------------------------------------------------------------------------
local kCollecting  = 0
local kMatching    = 1
local kDone        = 2

function Top.func(t_input, env)
    local ctx = {
        phase = kCollecting,  -- 當前狀態
        fixed_list = {},      -- 等待匹配的固定候選
        fixed_next = 1,       -- 下一个待匹配的固定候選匹配的
        smart_list = {},      -- 等待匹配的整句候選
        threshold = env.reorder_threshold,
        pin_set = {},         -- 候選是否是 pinned

        -- 用於處理 smart1
        delay_slot = {},      -- 延遲槽
        additional_check = 0  -- 轉移到 kMatching 前額外需要看到的 smart 數量
    }

    for cand in t_input:iter() do
        if cand:get_genuine().type == "punct" then
            yield(cand)
        elseif ctx.phase == kCollecting then
            Top.handle_collecting(env, ctx, cand)
        elseif ctx.phase == kMatching then
            Top.handle_matching(env, ctx, cand)
        else
            Top.yield_exact(env, cand)
        end
    end

    Top.flush(env, ctx, true)
end

--------------------------------------------------------------------------------
-- 狀態轉移
--------------------------------------------------------------------------------

function Top.handle_collecting(env, ctx, cand)
    -- print('handle_collecting: ' .. cand.text .. ', type=' .. cand.type .. ', comment=' .. cand.comment)

    -- 以下是固定候選
    if cand.type == "pinned" then
        -- Pin 輸出, 需要額外檢查 smart1
        table.insert(ctx.fixed_list, cand)
        ctx.pin_set[cand.text] = true
        ctx.additional_check = 1

    elseif cand.comment == "`F" then
        -- 碼表輸出（且非 Pin）
        if not ctx.pin_set[cand.text] then
            table.insert(ctx.fixed_list, cand)
        end

        -- 以下是 smart 候選
    elseif ctx.additional_check > 0 then
        -- 看到了 smart1，只記錄它。在 MATCHING 階段再處理。
        table.insert(ctx.delay_slot, cand)
        ctx.additional_check = ctx.additional_check - 1

    else
        -- 看到了 smart2，轉向 kMatching 狀態。
        ctx.phase = kMatching

        -- 可能收集到了 smart1，先處理。
        for _, c in ipairs(ctx.delay_slot) do
            Top.handle_matching(env, ctx, c)
        end
        ctx.delay_slot = {}

        -- 處理當前看到的 smart2。
        if ctx.phase == kDone then
            Top.yield_exact(env, cand)
        else
            Top.handle_matching(env, ctx, cand)
        end
    end
end

function Top.handle_matching(env, ctx, cand)
    if ctx.threshold == 0 then
        Top.flush(env, ctx, false)
        ctx.phase = kDone
        Top.yield_exact(env, cand)
        return
    else
        ctx.threshold = ctx.threshold - 1
    end

    -- print('handle_matching: ' .. cand.text .. ', threshold=' .. tostring(ctx.threshold))

    table.insert(ctx.smart_list, cand)
    while ctx.fixed_next <= #ctx.fixed_list do
        local fcand = ctx.fixed_list[ctx.fixed_next]
        if not Top.reorderable(fcand) then
            Top.yield_exact(env, fcand)
            ctx.fixed_next = ctx.fixed_next + 1
        else
            local si, scand = Top.find_matching_scand(ctx, fcand)
            if si == nil then
                break
            end
            Top.yield_smart_in_place_of_fixed(env, scand, fcand)
            ctx.fixed_next = ctx.fixed_next + 1
            table.remove(ctx.smart_list, si)
        end
    end
    if ctx.fixed_next > #ctx.fixed_list then
        Top.flush(env, ctx, false)
        ctx.phase = kDone
    end
end

--------------------------------------------------------------------------------
-- 輔助函數
--------------------------------------------------------------------------------

--- 在 smart_list 中查找匹配 fcand 的 scand，返回下標和 scand 對象。
function Top.find_matching_scand(ctx, fcand)
    for si = #ctx.smart_list, 1, -1 do
        local scand = ctx.smart_list[si]
        if Top.candidate_match(scand, fcand) then
            return si, scand
        end
    end
    return nil, nil
end

--- 輸出所有剩下的候選。
function Top.flush(env, ctx, include_delay_slot)
    for i = ctx.fixed_next, #ctx.fixed_list do
        Top.yield_exact(env, ctx.fixed_list[i])
    end
    if include_delay_slot then
        -- 只在完全匹配完畢後才清空延遲槽
        for _, c in ipairs(ctx.delay_slot) do
            Top.yield_exact(env, c)
        end
        ctx.delay_slot = {}
    end
    for _, c in ipairs(ctx.smart_list) do
        Top.yield_exact(env, c)
    end
    ctx.fixed_list = {}
    ctx.smart_list = {}
end

--- cand 是否有可能被重排（即是否有可能是 smart 輸出）。
function Top.reorderable(cand)
    local len = utf8.len(cand.text)
    return (len > 1 and #cand.preedit >= 2 * len) or (len == 1 and #cand.preedit <= 5)
end

--- 檢查 scand 是否可以替代 fcand 。
---
--- Preedit 檢查確保 scand 不單單對應於從輸入的前綴。
function Top.candidate_match(scand, fcand)
    if scand.text ~= fcand.text then
        return false
    end
    local spreedit = scand.preedit
    local fpreedit = fcand.preedit
    if spreedit == fpreedit then
        return true
    end
    return (#fpreedit <= #spreedit and #fpreedit >= #spreedit - math.floor((#spreedit + 1) / 3) + 1)
        and spreedit:gsub('%s', '') == fpreedit
end

--- 輸出候選但恢復簡快碼提示符。若非簡快碼，則直接輸出。
function Top.yield_exact(env, cand)
    if cand.comment == "`F" then
        cand.comment = env.quick_code_indicator
    end
    yield(cand)
end

--- 用 scand 替代 fcand 並輸出。
function Top.yield_smart_in_place_of_fixed(env, scand, fcand)
    if fcand.comment == "`F" then
        scand.comment = env.quick_code_indicator .. scand.comment
    elseif fcand.type == "pinned" then
        scand.comment = env.pin_indicator
    end
    yield(scand)
end

return Top

-- Local Variables:
-- lua-indent-level: 4
-- End:
