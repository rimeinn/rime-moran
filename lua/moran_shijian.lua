-- Moran 日期与时间翻译器
-- 原作者：98wubi Group (http://98wb.ys168.com/)
-- 当前版本由 Project Moran 修改并提供
--
-- 命令：orq/odate 日期；onl/ocdate 农历；osj/ouj/otime 时间；
--       oxq/oweek 星期；oww/ovu 周数；ojq 节气；N年月日[时] 历法查询；
--       ors 日期时间；oepoch Unix 时间戳。

local moran = require("moran")

local Top = {}
local Calendar = {}       -- 公历／农历换算，不依赖时区
local Solar = {}          -- 太阳位置、儒略日与节气计算
local Ganzhi = {}         -- 每次查询独立的干支状态
local data = {}

--------------------------------------------------------------------------------
-- 命令入口
--------------------------------------------------------------------------------

function Top.func(input, segment)
    if input == "odate" or input == "orq" then
        Top.yield_date(segment)
    elseif input == "ocdate" or input == "onl" then
        Top.yield_lunar(segment)
    elseif input == "otime" or input == "osj" or input == "ouj" then
        Top.yield_time(segment)
    elseif input == "oweek" or input == "oxq" then
        Top.yield_weekday(segment)
    elseif input == "oww" or input == "ovu" then
        Top.yield_week_number(segment)
    elseif input == "ojq" then
        Top.yield_solar_terms(segment)
    elseif input:sub(1, 1) == "N" then
        Top.yield_query(input, segment)
    elseif input == "ors" then
        Top.yield_timestamp(input, segment)
    elseif input == "oepoch" then
        Top.emit(segment, input, string.format("%d", os.time()), "Unix Timestamp")
    end
end

--------------------------------------------------------------------------------
-- 候选生成
--------------------------------------------------------------------------------

function Top.emit(segment, candidate_type, text, comment, quality)
    local candidate = Candidate(candidate_type, segment.start, segment._end, text, comment)
    if quality then candidate.quality = quality end
    yield(candidate)
end

function Top.yield_date(segment)
    local now = os.time()
    local day_count_comment = os.date("%j/", now) .. Calendar.year_days(os.date("%Y", now))
    for _, date_format in ipairs({"%Y-%m-%d", "%Y/%m/%d", "%Y.%m.%d"}) do
        Top.emit(segment, "date", os.date(date_format, now), day_count_comment)
    end
    Top.emit(segment, "date", (os.date("%Y年%m月%d日", now):gsub("(%D)0", "%1")), day_count_comment)
    local gregorian_text = os.date("%m/%d/%Y", now):gsub("([^%d])0+", "%1"):gsub("^0+", "")
    Top.emit(segment, "date", gregorian_text, day_count_comment)
    Top.emit(segment, "date", Top.chinese_date(os.date("%Y%m%d", now)), day_count_comment)
    Top.emit(segment, "date", Top.format_ganzhi(now), " ")
    local lunar_text = Calendar.format_lunar(os.date("%Y%m%d", now))
    Top.emit(segment, "date", lunar_text .. Solar.term_on_date(os.date("%Y%m%d", now)), "")
    Top.emit(segment, "date", lunar_text .. Top.shichen(os.date("%H", now)), "")
end

function Top.yield_lunar(segment)
    local now = os.time()
    local lunar_text = Calendar.format_lunar(os.date("%Y%m%d", now))
    Top.emit(segment, "date", lunar_text .. Solar.term_on_date(os.date("%Y%m%d", now)), "", 1.1)
    Top.emit(segment, "date", Top.format_ganzhi(now), " ", 1.1)
    Top.emit(segment, "date", lunar_text .. Top.shichen(os.date("%H", now)), "", 1.1)
end

function Top.yield_time(segment)
    local now = os.time()
    local shichen_text = Top.shichen(os.date("%H", now))
    Top.emit(segment, "time", os.date("%H:%M", now), shichen_text)
    local day_period = os.date("%p", now) == "AM" and "上午" or "下午"
    Top.emit(segment, "time", day_period .. os.date("%I:%M", now), shichen_text)
    Top.emit(segment, "time", os.date("%H:%M:%S", now), shichen_text)
    Top.emit(segment, "time", (os.date("%H点%M分%S秒", now):gsub("^0", "")), shichen_text)
end

function Top.yield_weekday(segment)
    local now = os.time()
    local weekday_names = {"日", "一", "二", "三", "四", "五", "六"}
    local weekday_text = weekday_names[tonumber(os.date("%w", now)) + 1]
    local week_comment = "第" .. Top.iso_week_number(now) .. "周"
    Top.emit(segment, "xq", "周" .. weekday_text, week_comment)
    Top.emit(segment, "xq", "星期" .. weekday_text, week_comment)
    Top.emit(segment, "xq", os.date("%a", now), week_comment)
    Top.emit(segment, "xq", os.date("%A", now), week_comment)
end

function Top.yield_week_number(segment)
    local week_number = Top.iso_week_number()
    Top.emit(segment, "oww", "W" .. week_number, "周")
    Top.emit(segment, "oww", "第" .. week_number .. "周", "周")
end

function Top.yield_solar_terms(segment)
    local date = os.date("*t")
    local start_date = os.date("%Y%m%d", os.time({year = date.year, month = date.month,
        day = date.day - 15, hour = 12, min = 0, sec = 0}))
    for _, term_text in ipairs(Solar.upcoming_terms(start_date)) do
        Top.emit(segment, "solar_terms", term_text, "〔节气〕")
    end
end

function Top.yield_query(input, segment)
    local date_input = input:sub(2)
    if not tonumber(date_input) then return end
    for _, query_result in ipairs(Top.query_date(date_input)) do
        Top.emit(segment, input, query_result[1], query_result[2])
    end
end

function Top.yield_timestamp(input, segment)
    local now = os.time()
    Top.emit(segment, input, os.date("%Y-%m-%d %H:%M:%S", now), "年-月-日 时:分:秒")
    local utc_offset = os.date("%z", now):gsub("(%d%d)(%d%d)$", "%1:%2")
    Top.emit(segment, input, os.date("%Y-%m-%dT%H:%M:%S", now) .. utc_offset, "年-月-日T时:分:秒+时区")
    Top.emit(segment, input, os.date("%Y%m%d%H%M%S", now), "年月日时分秒")
end

--------------------------------------------------------------------------------
-- 日期格式化与查询
--------------------------------------------------------------------------------

-- ISO 周以星期四决定所属年份；用中午避免夏令时间切换的午夜边界。
function Top.iso_week_number(timestamp)
    local date = os.date("*t", timestamp or os.time())
    date.hour, date.min, date.sec = 12, 0, 0

    local noon_timestamp = os.time(date)
    local weekday = tonumber(os.date("%w", noon_timestamp))
    if weekday == 0 then weekday = 7 end

    local thursday_timestamp = os.time({
        year = date.year,
        month = date.month,
        day = date.day + 4 - weekday,
        hour = 12,
        min = 0,
        sec = 0,
    })
    local thursday_day_of_year = tonumber(os.date("%j", thursday_timestamp))
    return tostring(math.floor((thursday_day_of_year - 1) / 7) + 1)
end

--- 23 时及 0 时同属子时，其后每两小时一个时辰。
function Top.shichen(hour)
    local shichen_names = {"子时(夜半｜三更)", "丑时(鸡鸣｜四更)", "寅时(平旦｜五更)",
            "卯时(日出)", "辰时(食时)", "巳时(隅中)", "午时(日中)", "未时(日昳)",
            "申时(晡时)", "酉时(日入)", "戌时(黄昏｜一更)", "亥时(人定｜二更)"}
    return shichen_names[math.floor((tonumber(hour) + 1) / 2) % 12 + 1]
end

function Top.chinese_date(date_digits)
    local chinese_digits = {"〇", "一", "二", "三", "四", "五", "六", "七", "八", "九"}
    local date_text = ""
    for digit_index = 1, #date_digits do
        local digit_text = chinese_digits[tonumber(date_digits:sub(digit_index, digit_index)) + 1]
        if digit_index == 5 and digit_text ~= "〇" then
            digit_text = "年十"
        elseif digit_index == 5 and digit_text == "〇" then
            digit_text = "年"
        end
        if digit_index == 6 and digit_text ~= "〇" then
            digit_text = digit_text .. "月"
        elseif digit_index == 6 and digit_text == "〇" then
            digit_text = "月"
        end

        if digit_index == 7 and tonumber(date_digits:sub(7, 7)) > 1 then
            digit_text = digit_text .. "十"
        elseif digit_index == 7 and digit_text == "〇" then
            digit_text = ""
        elseif digit_index == 7 and tonumber(date_digits:sub(7, 7)) == 1 then
            digit_text = "十"
        end
        if digit_index == 8 and digit_text ~= "〇" then
            digit_text = digit_text .. "日"
        elseif digit_index == 8 and digit_text == "〇" then
            digit_text = "日"
        end
        date_text = date_text .. digit_text
    end
    return date_text
end

-- 接受 1900–2099 年；N2008 补成 2008010101，N20080110 补成 2008011001。
function Top.query_date(input)
    local date_digits = tostring(input):gsub("^(%u+)", "")
    if not (date_digits:match("^20%d%d+$") or date_digits:match("^19%d%d+$")) then return {} end

    local completion_suffixes = {[4] = "010101", [5] = "10101", [6] = "0101", [7] = "101", [8] = "01", [9] = "0"}
    date_digits = completion_suffixes[#date_digits] and date_digits .. completion_suffixes[#date_digits] or date_digits:sub(1, 10)
    local month, day, hour = tonumber(date_digits:sub(5, 6)), tonumber(date_digits:sub(7, 8)), tonumber(date_digits:sub(9, 10))
    if month < 1 or month > 12 or day < 1 or day > 31 or hour > 23 then return {} end

    local query_results = {}
    if Calendar.to_lunar(date_digits) then
        local timestamp = os.time({year = tonumber(date_digits:sub(1, 4)), month = month,
            day = day, hour = hour, min = 0, sec = 0})
        query_results = {
            {date_digits:sub(1, 4) .. "年" .. date_digits:sub(5, 6) .. "月" .. date_digits:sub(7, 8) .. "日", "〔公历〕"},
            {Calendar.format_lunar(date_digits), "〔公历⇉农历〕"},
        }
        -- 夏令时跳过的小时没有对应的本地时刻。
        if timestamp and os.date("%Y%m%d%H", timestamp) == date_digits then
            table.insert(query_results, {Top.format_ganzhi(timestamp), "〔公历⇉干支〕"})
        end
    end
    for leap_flag = 0, 1 do
        local gregorian_text = Calendar.to_gregorian(date_digits, leap_flag)
        if gregorian_text:match("^%d+") then
            table.insert(query_results, {gregorian_text .. (leap_flag == 1 and "（闰）" or ""), "〔农历⇉公历〕"})
        end
    end
    return query_results
end

--------------------------------------------------------------------------------
-- 公历与农历换算（公历 1900–2100 年）
--------------------------------------------------------------------------------

function Calendar.year_days(year)
    year = tonumber(year)
    return (year % 400 == 0 or year % 4 == 0 and year % 100 ~= 0) and 366 or 365
end

local function month_days(year, month)
    if month == 2 then return Calendar.year_days(year) == 366 and 29 or 28 end
    return ({31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31})[month]
end

-- 公历整数日序，避开时区及夏令时间；农历换算只使用日期。
local function gregorian_day_number(year, month, day)
    local previous_year = year - 1
    local day_number = 365 * previous_year + math.floor(previous_year / 4) - math.floor(previous_year / 100) + math.floor(previous_year / 400) + day
    for previous_month = 1, month - 1 do day_number = day_number + month_days(year, previous_month) end
    return day_number
end

local function parse_date(date)
    -- 查询入口可能附带时辰（YYYYMMDDHH）；换算只取年月日。
    local year, month, day = tostring(date):match("^(%d%d%d%d)(%d%d)(%d%d)%d*$")
    return tonumber(year), tonumber(month), tonumber(day)
end

--- 公历 YYYYMMDD → 农历年、月、日、闰月标记（0 或 1）；无效日期返回 nil。
function Calendar.to_lunar(date)
    local year, month, day = parse_date(date)
    if not year or year < 1900 or year > 2100 or month < 1 or month > 12 or day < 1 or day > month_days(year, month) then
        return nil
    end
    local day_number = gregorian_day_number(year, month, day)
    if day_number < data.lunar_years()[year].new_year_day_number then year = year - 1 end
    local remaining_days = day_number - data.lunar_years()[year].new_year_day_number
    for _, lunar_month in ipairs(data.lunar_years()[year].months) do
        if remaining_days < lunar_month.days then return year, lunar_month.month, remaining_days + 1, lunar_month.leap_flag end
        remaining_days = remaining_days - lunar_month.days
    end
end

function Calendar.format_lunar(date)
    local year, month, day, leap_flag = Calendar.to_lunar(date)
    if not year then return "无效日期" end
    return data.stems[(year - 4) % 10 + 1] .. data.branches[(year - 4) % 12 + 1] .. "年(" ..
        data.animals[(year - 4) % 12 + 1] .. ")" .. (leap_flag == 1 and "闰" or "") .. data.month_names[month] .. data.day_names[day]
end

--- 农历 YYYYMMDD、闰月标记 → 公历中文日期；接受农历 1899–2100 年。
function Calendar.to_gregorian(date, leap_flag)
    local year, month, day = parse_date(date)
    leap_flag = tonumber(leap_flag)
    if not year or not data.lunar_years()[year] or month < 1 or month > 12 or day < 1 or day > 30 or (leap_flag ~= 0 and leap_flag ~= 1) then
        return "无效日期"
    end
    local day_number = data.lunar_years()[year].new_year_day_number
    for _, lunar_month in ipairs(data.lunar_years()[year].months) do
        if lunar_month.month == month and lunar_month.leap_flag == leap_flag then
            if day > lunar_month.days then return "无效日期" end
            day_number = day_number + day - 1
            while day_number >= gregorian_day_number(year + 1, 1, 1) do year = year + 1 end
            day_number = day_number - gregorian_day_number(year, 1, 1) + 1
            month = 1
            while day_number > month_days(year, month) do
                day_number = day_number - month_days(year, month)
                month = month + 1
            end
            return string.format("%d年%d月%d日", year, month, day_number)
        end
        day_number = day_number + lunar_month.days
    end
    return "该月不是闰月！"
end

--------------------------------------------------------------------------------
-- 干支纪年、纪月、纪日与纪时
--------------------------------------------------------------------------------

-- 干支年、月以节气的实际时刻分界；日与时按本地时区计算，23 时换日。
function Ganzhi:cycle_index(start, offset, period)
    return (start + offset - 1) % period + 1
end

function Ganzhi:set_time(timestamp)
    self.timestamp = timestamp
    local year = os.date("*t", timestamp).year
    self.terms = Solar.year_terms(year)
    self.year = timestamp < self.terms[1] and year - 1 or year
    if self.year ~= year then self.terms = Solar.year_terms(self.year) end
    self.month = self:calendar_month()
end

function Ganzhi:calendar_month()
    if self.timestamp < self.terms[1] then return nil end
    for term_index = 1, 23 do
        if self.timestamp < self.terms[term_index + 1] then return math.floor((term_index + 1) / 2) end
    end
    return 12
end

function Ganzhi:year_index()
    return self:cycle_index(1, self.year - 1984, 60) -- 1984 为甲子年
end

function Ganzhi:month_index()
    -- 2010 年立春所在的寅月为戊寅，六十甲子序号 15。
    local month_offset = (self.year - 2010) * 12 + self.month - 1
    return self:cycle_index(15, month_offset, 60)
end

function Ganzhi:day_index()
    local date = os.date("*t", self.timestamp)
    local day_number = gregorian_day_number(date.year, date.month, date.day)
    if date.hour == 23 then day_number = day_number + 1 end
    return self:cycle_index(1, day_number - gregorian_day_number(2012, 8, 31), 60)
end

function Ganzhi:hour_index()
    local hour = os.date("*t", self.timestamp).hour
    local hour_branch = math.floor((hour + 1) / 2) % 12
    return ((self:day_index() - 1) * 12 + hour_branch) % 60 + 1
end

function Top.cycle_name(index)
    return data.stems[(index - 1) % 10 + 1] .. data.branches[(index - 1) % 12 + 1]
end

--- Unix 时间戳 → 年、月、日、时干支。
function Top.format_ganzhi(timestamp)
    local context = setmetatable({}, {__index = Ganzhi})
    context:set_time(timestamp)
    return Top.cycle_name(context:year_index()) .. "年" .. Top.cycle_name(context:month_index()) .. "月" ..
        Top.cycle_name(context:day_index()) .. "日" .. Top.cycle_name(context:hour_index()) .. "时"
end

--------------------------------------------------------------------------------
-- 节气日期与时间
--------------------------------------------------------------------------------

--- term_index 从 0（春分）到 23（次年惊蛰）。先求力学时，再换算为东八区日期。
function Solar.term_date(year, term_index)
    local estimated_day = 365.2422 * (year - 2000) + term_index * 15.2
    local julian_day = Solar.solve_longitude(estimated_day, term_index * 15) + data.j2000 + 8 / 24
    return Solar.from_julian(julian_day)
end

-- 每年按小寒至冬至排列；日期使用东八区，时间戳不依赖本地时区。
function Solar.calendar_terms(year)
    local terms = {}
    for index = 1, 24 do
        local term_index = (index + 18) % 24
        local date = Solar.term_date(index <= 5 and year - 1 or year, term_index)
        terms[index] = {date = Solar.date_string(date), timestamp = Solar.date_timestamp(date),
            name = data.solar_term_names[term_index + 1]}
    end
    return terms
end

--- 当天若为节气，返回「-节气名」，否则返回空字符串。
function Solar.term_on_date(date)
    date = tostring(date)
    for _, term in ipairs(Solar.calendar_terms(tonumber(date:sub(1, 4)))) do
        if term.date:gsub("-", "") == date then return "-" .. term.name end
    end
    return ""
end

--- 当年立春起算的 24 个节气时间戳。
function Solar.year_terms(year)
    local current_terms = Solar.calendar_terms(year)
    local next_terms = Solar.calendar_terms(year + 1)
    local timestamps = {}
    for index = 3, 24 do timestamps[#timestamps + 1] = current_terms[index].timestamp end
    for index = 1, 2 do timestamps[#timestamps + 1] = next_terms[index].timestamp end
    return timestamps
end

--- 指定日期至次年惊蛰的节气，包含指定日期当天。
function Solar.upcoming_terms(date)
    date = tostring(date)
    local year, month, day = parse_date(date)
    if not year or year < 1900 or year > 2100 or month < 1 or month > 12 or
        day < 1 or day > month_days(year, month) then return {} end
    local descriptions = {}
    for term_year = year, year + 1 do
        for index, term in ipairs(Solar.calendar_terms(term_year)) do
            if (term_year == year or index <= 5) and term.date:gsub("-", "") >= date then
                descriptions[#descriptions + 1] = term.name .. " " .. term.date
            end
        end
    end
    return descriptions
end

--------------------------------------------------------------------------------
-- 天文计算：J2000 起算日数、弧度与力学时
--------------------------------------------------------------------------------

--- 将弧度化至 [0, 2π)。
function Solar.normalize_angle(angle)
    return angle % (2 * math.pi)
end

--- 以年份插值 ΔT（秒），供力学时转世界时使用。
function Solar.delta_t_seconds(year)
    local interval_index
    local coefficients = data.delta_t
    for candidate_index = 1, 100, 5 do
        if year < coefficients[candidate_index + 5] or candidate_index == 96 then
            interval_index = candidate_index
            break
        end
    end

    local scaled_year = (year - coefficients[interval_index]) / (coefficients[interval_index + 5] - coefficients[interval_index]) * 10
    local scaled_year_squared = scaled_year * scaled_year
    local scaled_year_cubed = scaled_year_squared * scaled_year
    return coefficients[interval_index + 1]
        + coefficients[interval_index + 2] * scaled_year
        + coefficients[interval_index + 3] * scaled_year_squared
        + coefficients[interval_index + 4] * scaled_year_cubed
end

--- days_since_epoch 为 J2000 起算的日数；返回 ΔT（日）。
function Solar.delta_t_days(days_since_epoch)
    return Solar.delta_t_seconds(days_since_epoch / 365.2425 + 2000) / 86400.0
end

--- 带东八区偏移的力学时儒略日 → 公历年月日时分秒（先扣除 ΔT）。
function Solar.from_julian(julian_day)
    local date = {}
    julian_day = julian_day - Solar.delta_t_days(julian_day - data.j2000)
    julian_day = julian_day + 0.5
    local calendar_day = math.floor(julian_day)
    local fractional_day = julian_day - calendar_day
    if calendar_day > 2299161 then
        local century = math.floor((calendar_day - 1867216.25) / 36524.25)
        calendar_day = calendar_day + 1 + century - math.floor(century / 4)
    end
    calendar_day = calendar_day + 1524
    date.year = math.floor((calendar_day - 122.1) / 365.25)
    local remaining_days = calendar_day - math.floor(365.25 * date.year)
    date.month = math.floor(remaining_days / 30.6001)
    date.day = remaining_days - math.floor(date.month * 30.6001)
    date.year = date.year - 4716
    date.month = date.month - 1
    if date.month > 12 then date.month = date.month - 12 end
    if date.month <= 2 then date.year = date.year + 1 end

    local fractional_hour = fractional_day * 24
    date.hour = math.floor(fractional_hour)
    local fractional_minute = (fractional_hour - date.hour) * 60
    date.min = math.floor(fractional_minute)
    date.sec = (fractional_minute - date.min) * 60
    return date
end

function Solar.date_string(date)
    return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
end

--- 东八区年月日时分秒 → Unix 时间戳；秒四舍五入。
function Solar.date_timestamp(date)
    local days = gregorian_day_number(date.year, date.month, date.day) - gregorian_day_number(1970, 1, 1)
    return days * 86400 + (date.hour - 8) * 3600 + date.min * 60 + math.floor(date.sec + .5)
end

function Solar.aberration(days_since_epoch, position) -- 恒星周年光行差计算(黄道坐标中)
    local centuries = days_since_epoch / 36525
    local centuries_squared = centuries * centuries
    local centuries_cubed = centuries_squared * centuries
    local centuries_fourth = centuries_cubed * centuries
    local mean_longitude = data.mean_longitude_coefficients[1]
        + data.mean_longitude_coefficients[2] * centuries
        + data.mean_longitude_coefficients[3] * centuries_squared
        + data.mean_longitude_coefficients[4] * centuries_cubed
        + data.mean_longitude_coefficients[5] * centuries_fourth
    local perihelion_longitude = data.perihelion_coefficients[1]
        + data.perihelion_coefficients[2] * centuries
        + data.perihelion_coefficients[3] * centuries_squared
    local eccentricity = data.eccentricity_coefficients[1]
        + data.eccentricity_coefficients[2] * centuries
        + data.eccentricity_coefficients[3] * centuries_squared
    local mean_longitude_difference = mean_longitude - position.longitude
    local perihelion_difference = perihelion_longitude - position.longitude
    position.longitude = position.longitude - (data.aberration_constant
        * (math.cos(mean_longitude_difference) - eccentricity * math.cos(perihelion_difference))
        / math.cos(position.latitude))
    position.latitude = position.latitude - (data.aberration_constant * math.sin(position.latitude)
        * (math.sin(mean_longitude_difference) - eccentricity * math.sin(perihelion_difference)))
    position.longitude = Solar.normalize_angle(position.longitude)
end

function Solar.nutation(days_since_epoch) -- 黄经章动（弧度）
    local longitude = 0
    local centuries = days_since_epoch / 36525
    local argument_angle
    local centuries_squared = centuries * centuries
    local centuries_cubed = centuries_squared * centuries
    local centuries_fourth = centuries_cubed * centuries
    for coefficient_index = 1, #data.nutation, 7 do
        argument_angle = data.nutation[coefficient_index]
            + data.nutation[coefficient_index + 1] * centuries
            + data.nutation[coefficient_index + 2] * centuries_squared
            + data.nutation[coefficient_index + 3] * centuries_cubed
            + data.nutation[coefficient_index + 4] * centuries_fourth
        longitude = longitude + (data.nutation[coefficient_index + 5]
            + data.nutation[coefficient_index + 6] * centuries / 10) * math.sin(argument_angle)
    end
    return longitude / (data.arcseconds_per_radian * 10000)
end

-- 系数每三项一组 A、B、C，累加 A*cos(B+C*t)；millennia 的单位为儒略千年。
function Solar.periodic_sum(coefficients, millennia)
    local sum = 0
    for coefficient_index = 1, #coefficients, 3 do
        sum = sum + coefficients[coefficient_index] * math.cos(coefficients[coefficient_index + 1] + millennia * coefficients[coefficient_index + 2])
    end
    return sum
end

-- 日心黄经、黄纬（弧度）；输入为 J2000 起算日数。
function Solar.earth_position(days_since_epoch)
    local millennia = days_since_epoch / 365250
    local position = {}
    local millennia_squared = millennia * millennia
    position.longitude = Solar.periodic_sum(data.earth_longitude_0, millennia)
        + Solar.periodic_sum(data.earth_longitude_1, millennia) * millennia
        + Solar.periodic_sum(data.earth_longitude_2, millennia) * millennia_squared
    position.latitude = Solar.periodic_sum(data.earth_latitude_0, millennia)
        + Solar.periodic_sum(data.earth_latitude_1, millennia) * millennia
    position.longitude = Solar.normalize_angle(position.longitude)
    return position
end

function Solar.longitude_error(days_since_epoch, target_longitude)
    local sun_position = Solar.earth_position(days_since_epoch) -- 计算太阳真位置(先算出日心坐标中地球的位置)
    sun_position.longitude = sun_position.longitude + math.pi
    sun_position.latitude = -sun_position.latitude -- 转为地心坐标
    Solar.aberration(days_since_epoch, sun_position) -- 补周年光行差
    sun_position.longitude = sun_position.longitude + Solar.nutation(days_since_epoch)
    return Solar.normalize_angle(target_longitude - sun_position.longitude)
end

-- 用截弦法求太阳黄经到达 target_degrees（度）的时刻，返回 J2000 起算的力学时日数。
-- 搜索起点 previous_day 应早于目标；节气按约 15.2 日间距给出初值。
function Solar.solve_longitude(previous_day, target_degrees)
    local current_day = previous_day
    local estimated_day = 0
    local angle_error
    current_day = current_day + 360
    local target_longitude = target_degrees * math.pi / 180
    local previous_error = Solar.longitude_error(previous_day, target_longitude)
    local current_error = Solar.longitude_error(current_day, target_longitude)
    if previous_error < current_error then
        current_error = current_error - 2 * math.pi
    end -- 减2pi作用是将周期性角度转为连续角度
    local slope, next_slope = 1, nil
    for iteration = 1, 10 do -- 快速截弦求根,通常截弦三四次就已达所需精度
        next_slope = (current_error - previous_error) / (current_day - previous_day)
        if math.abs(next_slope) > 1e-15 then
            slope = next_slope
        end -- 差商可能为零,应排除
        estimated_day = previous_day - previous_error / slope
        angle_error = Solar.longitude_error(estimated_day, target_longitude) -- 直线逼近法求根(直线方程的根)
        if angle_error > 1 then
            angle_error = angle_error - 2 * math.pi
        end -- 将角度差展开至同一周期
        if math.abs(angle_error) < 1e-8 then
            break
        end
        previous_day = current_day
        previous_error = current_error
        current_day = estimated_day
        current_error = angle_error
    end
    return estimated_day
end

--------------------------------------------------------------------------------
-- 只读数据：天文系数与农历年表
--------------------------------------------------------------------------------

data.j2000 = 2451545 -- 2000-01-01 12:00 UTC 的儒略日
data.arcseconds_per_radian = 180 * 3600 / math.pi
data.degrees_per_radian = 180 / math.pi

data.eccentricity_coefficients = {0.016708634, -0.000042037, -0.0000001267}

data.perihelion_coefficients = {102.93735 / data.degrees_per_radian, 1.71946 / data.degrees_per_radian, 0.00046 / data.degrees_per_radian}

data.mean_longitude_coefficients = {
    280.4664567 / data.degrees_per_radian, 36000.76982779 / data.degrees_per_radian,
    0.0003032028 / data.degrees_per_radian, 1 / 49931000 / data.degrees_per_radian,
    -1 / 153000000 / data.degrees_per_radian,
}

data.aberration_constant = 20.49552 / data.arcseconds_per_radian -- 光行差常数

data.nutation = { -- 黄经章动系数
    2.1824391966, -33.757045954, 0.0000362262, 3.7340E-08, -2.8793E-10, -171996, -1742,
    3.5069406862, 1256.663930738, 0.0000105845, 6.9813E-10, -2.2815E-10, -13187, -16,
    1.3375032491, 16799.418221925, -0.0000511866, 6.4626E-08, -5.3543E-10, -2274, -2,
    4.3648783932, -67.514091907, 0.0000724525, 7.4681E-08, -5.7586E-10, 2062, 2,
    0.0431251803, -628.301955171, 0.0000026820, 6.5935E-10, 5.5705E-11, -1426, 34,
    2.3555557435, 8328.691425719, 0.0001545547, 2.5033E-07, -1.1863E-09, 712, 1,
    3.4638155059, 1884.965885909, 0.0000079025, 3.8785E-11, -2.8386E-10, -517, 12,
    5.4382493597, 16833.175267879, -0.0000874129, 2.7285E-08, -2.4750E-10, -386, -4,
    3.6930589926, 25128.109647645, 0.0001033681, 3.1496E-07, -1.7218E-09, -301, 0,
    3.5500658664, 628.361975567, 0.0000132664, 1.3575E-09, -1.7245E-10, 217, -5,
}

-- VSOP87D 地球运动系数：longitude 黄经、latitude 黄纬。
-- 黄经按 |A| × 0.101^时间幂次选取 96 项，适用于 1900–2100 年。
-- 来源：https://ftp.imcce.fr/pub/ephem/planets/vsop87/VSOP87D.ear
-- 每三项为一组周期项；名称末尾的数字为时间幂次。
data.earth_longitude_0 = {
    1.75347045673, 0, 0, 0.03341656456, 4.66925680417, 6283.0758499914,
    0.00034894275, 4.62610241759, 12566.151699983, 3.417571e-05, 2.82886579606, 3.523118349,
    3.497056e-05, 2.74411800971, 5753.3848848968, 3.135896e-05, 3.62767041758, 77713.77146812,
    2.676218e-05, 4.41808351397, 7860.4193924392, 2.342687e-05, 6.13516237631, 3930.2096962196,
    1.273166e-05, 2.03709655772, 529.6909650946, 1.324292e-05, 0.74246356352, 11506.769769794,
    9.01855e-06, 2.04505443513, 26.2983197998, 1.199167e-05, 1.10962944315, 1577.3435424478,
    8.57223e-06, 3.50849156957, 398.1490034082, 7.79786e-06, 1.17882652114, 5223.6939198022,
    9.9025e-06, 5.23268129594, 5884.9268465832, 7.53141e-06, 2.53339053818, 5507.5532386674,
    5.05264e-06, 4.58292563052, 18849.227549974, 4.92379e-06, 4.20506639861, 775.522611324,
    3.56655e-06, 2.91954116867, 0.0673103028, 2.84125e-06, 1.89869034186, 796.2980068164,
    2.4281e-06, 0.34481140906, 5486.777843175, 3.17087e-06, 5.84901952218, 11790.629088659,
    2.71039e-06, 0.31488607649, 10977.078804699, 2.0616e-06, 4.80646606059, 2544.3144198834,
    2.05385e-06, 1.86947813692, 5573.1428014331, 2.02261e-06, 2.45767795458, 6069.7767545534,
    1.26184e-06, 1.0830263021, 20.7753954924, 1.55516e-06, 0.83306073807, 213.299095438,
    1.15132e-06, 0.64544911683, 0.9803210682, 1.02851e-06, 0.63599846727, 4694.0029547076,
    1.01724e-06, 4.26679821365, 7.1135470008, 9.9206e-07, 6.20992940258, 2146.1654164752,
    1.32212e-06, 3.41118275555, 2942.4634232916, 9.7607e-07, 0.6810127227, 155.4203994342,
    8.5128e-07, 1.29870743025, 6275.9623029906, 7.4651e-07, 1.75508916159, 5088.6288397668,
    1.01895e-06, 0.97569221824, 15720.838784878, 8.4711e-07, 3.67080093025, 71430.695618129,
    7.3547e-07, 4.67926565481, 801.8209311238, 7.3874e-07, 3.50319443167, 3154.6870848956,
    7.8756e-07, 3.03698313141, 12036.460734888, 7.9637e-07, 1.807913307, 17260.15465469,
    8.5803e-07, 5.98322631256, 161000.68573767, 5.6963e-07, 2.78430398043, 6286.5989683404,
    6.1148e-07, 1.81839811024, 7084.8967811152, 6.9627e-07, 0.83297596966, 9437.762934887,
    5.6116e-07, 4.38694880779, 14143.495242431, 6.2449e-07, 3.97763880587, 8827.3902698748,
    5.1145e-07, 0.28306864501, 5856.4776591154, 5.5577e-07, 3.47006009062, 6279.5527316424,
    4.1036e-07, 5.36817351402, 8429.2412664666, 5.1605e-07, 1.33282746983, 1748.016413067,
    5.1992e-07, 0.18914945834, 12139.553509107, 4.9e-07, 0.48735065033, 1194.4470102246,
    3.92e-07, 6.16832995016, 10447.387839604, 3.5566e-07, 1.77597314691, 6812.766815086,
    3.677e-07, 6.04133859347, 10213.285546211, 3.6596e-07, 2.56955238628, 1059.3819301892,
    3.3291e-07, 0.59309499459, 17789.845619785, 3.5954e-07, 1.70876111898, 2352.8661537718,
    4.0938e-07, 2.39850881707, 19651.048481098, 3.0047e-07, 2.73975123935, 1349.8674096588,
    3.0412e-07, 0.44294464135, 83996.847318112, 2.3663e-07, 0.48473567763, 8031.0922630584,
    2.3574e-07, 2.06527720049, 3340.6124266998, 2.1089e-07, 4.14825464101, 951.7184062506,
    2.4738e-07, 0.21484762138, 3.5904286518, 2.5352e-07, 3.16470953405, 4690.4798363586,
    2.282e-07, 5.22197888032, 4705.7323075436, 2.1419e-07, 1.42563735525, 16730.463689596,
    2.1891e-07, 5.55594302562, 553.5694028424, 1.7481e-07, 4.56052900359, 135.0650800354,
    1.9925e-07, 5.22208471269, 12168.002696575, 1.986e-07, 5.77470167653, 6309.3741697912,
    2.03e-07, 0.37133792946, 283.8593188652, 1.4421e-07, 4.19315332546, 242.728603974,
    1.6225e-07, 5.98837722564, 11769.853693166, 1.5077e-07, 4.19567181073, 6256.7775301916,
    1.9124e-07, 3.82219996949, 23581.258177318, 1.8888e-07, 5.38626880969, 149854.40013481,
    1.4346e-07, 3.72355084422, 38.0276726358, 1.7898e-07, 2.21490735647, 13367.972631107,
    1.2054e-07, 2.62229588349, 955.5997416086, 1.1287e-07, 0.17739328092, 4164.311989613,
    1.3971e-07, 4.40138139996, 6681.2248533996, 1.3621e-07, 1.88934471407, 7632.9432596502,
    1.2503e-07, 1.13052412208, 5.5229243074, 1.2003e-07, 1.003514567, 632.7837393132,
}

data.earth_longitude_1 = {
    6283.3196674749, 0, 0, 0.00206058863, 2.67823455584, 6283.0758499914,
    4.30343e-05, 2.63512650414, 12566.151699983, 4.25264e-06, 1.59046980729, 3.523118349,
    1.08977e-06, 2.96618001993, 1577.3435424478, 1.19261e-06, 5.79557487799, 26.2983197998,
}

data.earth_longitude_2 = {
    0.0005291887, 0, 0, 8.719837e-05, 1.07209665242, 6283.0758499914,
}

data.earth_latitude_0 = { -- 黄纬周期项
    0.00000279620, 3.19870156017, 84334.6615813083, 0.00000101643, 5.42248619256, 5507.5532386674, 0.00000080445,
    3.88013204458, 5223.6939198022, 0.00000043806, 3.70444689758, 2352.8661537718, 0.00000031933, 4.00026369781,
    1577.3435424478, 0.00000022724, 3.98473831560, 1047.7473117547, 0.00000016392, 3.56456119782, 5856.4776591154,
    0.00000018141, 4.98367470263, 6283.0758499914, 0.00000014443, 3.70275614914, 9437.7629348870, 0.00000014304,
    3.41117857525, 10213.2855462110}

data.earth_latitude_1 = {0.00000009030, 3.89729061890, 5507.5532386674, 0.00000006177, 1.73038850355, 5223.6939198022}

-- 每五项：起始年份与四个 ΔT 插值系数。
data.delta_t = {
    -4000, 108371.7, -13036.80, 392.000, 0.0000, -500, 17201.0, -627.82, 16.170, -0.3413, -150, 12200.6, -346.41, 5.403,
    -0.1593, 150, 9113.8, -328.13, -1.647, 0.0377, 500, 5707.5, -391.41, 0.915, 0.3145, 900, 2203.4, -283.45, 13.034,
    -0.1778, 1300, 490.1, -57.35, 2.085, -0.0072, 1600, 120.0, -9.81, -1.532, 0.1403, 1700, 10.2, -0.91, 0.510, -0.0370,
    1800, 13.4, -0.72, 0.202, -0.0193, 1830, 7.8, -1.81, 0.416, -0.0247, 1860, 8.3, -0.13, -0.406, 0.0292, 1880, -5.4,
    0.32, -0.183, 0.0173, 1900, -2.3, 2.06, 0.169, -0.0135, 1920, 21.2, 1.69, -0.304, 0.0167, 1940, 24.2, 1.22, -0.064,
    0.0031, 1960, 33.2, 0.51, 0.231, -0.0109, 1980, 51.0, 1.29, -0.026, 0.0032, 2000, 64.7, -1.66, 5.224, -0.2905, 2150,
    279.4, 732.95, 429.579, 0.0158, 6000}

data.solar_term_names = { -- 节气表
    "春分", "清明", "谷雨", "立夏", "小满", "芒种", "夏至", "小暑", "大暑", "立秋", "处暑", "白露",
    "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至", "小寒", "大寒", "立春", "雨水", "惊蛰"}

data.stems = {"甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"}
data.branches = {"子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"}
data.animals = {"鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"}
data.month_names = {"正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"}
data.day_names = {"初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
    "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
    "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"}

-- 1899–2100 年：12 个大小月比特位、闰月大小、闰月月份、春节 MMDD（十六进制）。
-- 1900–2026 数据来自紫金山天文台官方历表：
-- https://pmo.cas.cn/xwdt2019/kpdt2019/202203/t20220309_6386774.html
-- 2027 之后的日期来自香港天文台预测，但未来仍可能调整。
local lunar_data = {"AB500D2", "4BD0883", "4AE00DB", "A5700D0", "54D0581", "D2600D8", "D9500CC", "655147D",
    "56A00D5", "9AD00CA", "55D027A", "4AE00D2", "A5B0682", "A4D00DA", "D2500CE", "D25157E",
    "B5400D6", "D6A00CB", "ADA027B", "95B00D3", "49717C9", "49700DC", "A4B00D0", "B4B0580",
    "6A500D8", "6D400CD", "AB5147C", "2B600D5", "95700CA", "52F027B", "49700D2", "6560682",
    "D4A00D9", "EA500CE", "6A9157E", "5AD00D6", "2B600CC", "86E137C", "92E00D3", "C8D1783",
    "C9500DB", "D4A00D0", "D8A167F", "B5500D7", "56A00CD", "A5B147D", "25D00D5", "92D00CA",
    "D2B027A", "A9500D2", "B550781", "6CA00D9", "B5500CE", "535157F", "4DA00D6", "A5B00CB",
    "457137C", "52B00D4", "A9A0883", "E9500DA", "6AA00D0", "AEA0680", "AB500D7", "4B600CD",
    "AAE047D", "A5700D5", "52600CA", "F260379", "D9500D1", "5B50782", "56A00D9", "96D00CE",
    "4DD057F", "4AD00D7", "A4D00CB", "D4D047B", "D2500D3", "D550883", "B5400DA", "B6A00CF",
    "95A1680", "95B00D8", "49B00CD", "A97047D", "A4B00D5", "B270ACA", "6A500DC", "6D400D1",
    "AF40681", "AB600D9", "95700CE", "4AF057F", "49700D7", "64B00CC", "74A037B", "EA500D2",
    "6B50883", "5AC00DB", "AB600CF", "96D0580", "92E00D8", "C9600CD", "D95047C", "D4A00D4",
    "DA500C9", "755027A", "56A00D1", "ABB0781", "25D00DA", "92D00CF", "CAB057E", "A9500D6",
    "B4A00CB", "BAA047B", "AD500D2", "55D0983", "4BA00DB", "A5B00D0", "5171680", "52B00D8",
    "A9300CD", "795047D", "6AA00D4", "AD500C9", "5B5027A", "4B600D2", "A6E0681", "A4E00D9",
    "D2600CE", "EA6057E", "D5300D5", "5AA00CB", "76A037B", "96D00D3", "4AF0B83", "4AD00DB",
    "A4D00D0", "D0B1680", "D2500D7", "D5200CC", "DD4057C", "B5A00D4", "56D00C9", "55B027A",
    "49B00D2", "A570782", "A4B00D9", "AA500CE", "B25157E", "6D200D6", "ADA00CA", "4B6137B",
    "93700D3", "49F08C9", "49700DB", "64B00D0", "68A1680", "EA500D7", "6AA00CC", "A6C147C",
    "AAE00D4", "92E00CA", "D2E0379", "C9600D1", "D550781", "D4A00D9", "DA500CD", "5D5057E",
    "56A00D6", "A6D00CB", "55D047B", "52D00D3", "A9B0883", "A9500DB", "B4A00CF", "B6A067F",
    "AD500D7", "55A00CD", "ABA047C", "A5B00D4", "52B00CA", "B27037A", "69300D1", "7330781",
    "6AA00D9", "AD500CE", "4B5157E", "4B600D6", "A5700CB", "54E047C", "D1600D2", "E960882",
    "D5200DA", "DAA00CF", "6AA167F", "56D00D7", "4AE00CD", "A9D047D", "A2D00D4", "D1500C9",
    "F250279", "D5200D1"}

data.lunar_years = moran.Thunk(function()
    local years = {}
    for year_index, encoded_year in ipairs(lunar_data) do
        local year = year_index + 1898
        local month_size_bits = tonumber(encoded_year:sub(1, 3), 16)
        local leap_month = tonumber(encoded_year:sub(5, 5), 16)
        local new_year_mmdd = tonumber(encoded_year:sub(6, 7), 16)
        local year_info = {
            new_year_day_number = gregorian_day_number(year, math.floor(new_year_mmdd / 100), new_year_mmdd % 100),
            months = {},
        }
        for month = 1, 12 do
            local month_length = 29 + math.floor(month_size_bits / 2 ^ (12 - month)) % 2
            year_info.months[#year_info.months + 1] = {month = month, leap_flag = 0, days = month_length}
            if month == leap_month then
                year_info.months[#year_info.months + 1] = {month = month, leap_flag = 1, days = 29 + tonumber(encoded_year:sub(4, 4))}
            end
        end
        years[year] = year_info
    end
    return years
end)

return Top

-- Local Variables:
-- lua-indent-level: 4
-- End:
