-- moran_number.lua
--
-- Author: ksqsf
-- License: GPLv3
-- Version: 0.1
--
-- 0.1: Introduction.

local MAXINT           = math.maxinteger
local dot              = "点"
local digitRegular     = { [0] = "零", "一", "二", "三", "四", "五", "六", "七", "八", "九" }
local digitLower       = { [0] = "〇", "一", "二", "三", "四", "五", "六", "七", "八", "九" }
local digitUpper       = { [0] = "零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖" }
local unitLower        = { "", "十", "百", "千" }
local unitUpper        = { "", "拾", "佰", "仟" }
local bigUnit          = { "万", "亿" }
local currencyUnit     = "元"
local currencyFracUnit = { "角", "分", "厘", "毫" }

-- 解析浮点数字符串为三元组 ( 整数部分字符串, 小数点字符串, 小数部分字符串 )
local function parseNumStr(str)
   local result = {}
   result.int, result.dot, result.frac = str:match("^(%d*)(%.?)(%d*)")
   return result
end

-- 转换 4 位整数节, 如 9909 -> 九千九百零九
local function translateIntSegment(int, digit, unit)
   local d = {
      int % 10,
      (int // 10) % 10,
      (int // 100) % 10,
      (int // 1000) % 10
   }
   local result = ""
   local lastPos = -1
   local i = 4
   while i >= 1 do
      if d[i] ~= 0 then
         if lastPos == -1 then
            lastPos = i
         end
         if lastPos - i > 1 then  -- 中间有空位, 增加'零'
            result = result .. digit[0]
         end
         result = result .. digit[d[i]] .. unit[i]
         lastPos = i
      end
      i = i - 1
   end
   return result
end

-- 将指数转换成大数单位
-- 如 4->万, 8->亿
-- exponent 必须是4的倍数
local function translateBigUnit(exponent, bigUnit)
   exponent = exponent // 4
   local hiExp = #bigUnit    -- 最高大数单位
   local result = bigUnit[hiExp]:rep(exponent // hiExp)
   exponent = exponent % hiExp
   local i = 1
   local prefix = ""
   while exponent ~= 0 do
      if exponent % 2 == 1 then
         prefix = bigUnit[i] .. prefix
      end
      exponent = exponent // 2
      i = i + 1
   end
   return prefix .. result
end

-- 转换整数部分
local function translateInt(str, digit, unit, bigUnit)
   local int = tonumber(str)
   if math.type(int) == "float" then
      return "数值超限！"
   end
   if int == 0 then
      return digit[0]
   end
   local result = ""
   local exponent = 0
   local lastSegInt = 1000
   local first = true
   while int ~= 0 do
      local segInt = int % 10000
      local segStr = translateIntSegment(segInt, digit, unit)
      local unitStr = translateBigUnit(exponent, bigUnit)
      local filler = (lastSegInt < 1000 and not first) and digit[0] or ""
      result = segStr .. (segStr ~= "" and unitStr or "") .. filler .. result
      lastSegInt = segInt
      int = int // 10000
      exponent = exponent + 4
      if segInt ~= 0 then
         first = false
      end
   end
   return result
end

local function mapDigits(str, digit)
   return str:gsub("%d", function(c) return digit[tonumber(c)] or c end)
end

-- 转换小数部分, 金额风格, 0123 -> 零角一分二厘
local function translateFracCurrency(str, digit, unit)
   local len = math.min(#unit, #str)
   local result = ""
   for i = 1, len do
      result = result .. digit[str:byte(i) - 0x30] .. unit[i]
   end
   return result
end

-- 常规转换
local function translateRegular(input)
   return translateInt(input.int, digitRegular, unitLower, bigUnit)
      .. (input.dot ~= "" and (dot .. mapDigits(input.frac, digitRegular)) or "")
end

local function translateUpper(input)
   return translateInt(input.int, digitUpper, unitUpper, bigUnit)
      .. (input.dot ~= "" and (dot .. mapDigits(input.frac, digitUpper)) or "")
end

local function translateLower(input)
   return translateInt(input.int, digitLower, unitLower, bigUnit)
      .. (input.dot ~= "" and (dot .. mapDigits(input.frac, digitLower)) or "")
end

-- 金额转换
local function translateCurrency(input, digit, unit, bigUnit)
   local intPart = translateInt(input.int, digit, unit, bigUnit)
   if input.dot == "" then
      return intPart .. currencyUnit .. "整"
   else
      return intPart .. currencyUnit .. translateFracCurrency(input.frac, digit, currencyFracUnit)
   end
end

local function translateNumStr(str)
   local input = parseNumStr(str)
   local result = {
      { translateRegular(input), "〔小写〕"},
      { translateUpper(input), "〔大写〕"},
      -- { translateLower(input), "〔小写〕"},
      { mapDigits(str, digitLower):gsub("%.", dot), "〔编号〕" },
      { translateCurrency(input, digitUpper, unitUpper, bigUnit), "〔金额大写〕"},
      { translateCurrency(input, digitLower, unitLower, bigUnit), "〔金额小写〕"},
   }
   return result
end

local function translator(input, seg)
   if input:match("^(S+%d+)(%.?)(%d*)$") ~= nil then
      local str = input:gsub("^(%a+)", "")
      local conversions = translateNumStr(str)
      for i = 1, #conversions do
         yield(Candidate(input, seg.start, seg._end, conversions[i][1], conversions[i][2]))
      end
   end
end

return translator
