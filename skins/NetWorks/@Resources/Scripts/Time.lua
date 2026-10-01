-- Fills the day/hour/minute/second tiles, the UTC offset badge, the date and the UTC time from the system clock.
-- Returns how far through the local day it is (0-100) for the bar.
-- 12 or 24 hour: the Clock variable (12, 24, or auto = the Windows short time format); Clock() flips it.
local mFmt
local last, pct = nil, 0

local function set(m, k, v) SKIN:Bang('!SetOption', m, k, v) end

function Initialize()
    mFmt = SKIN:GetMeasure('mShortTime')
end

local function is24()
    local c = SKIN:GetVariable('Clock')
    if c == '24' then return true elseif c == '12' then return false end
    return mFmt:GetStringValue():find('H', 1, true) ~= nil
end

-- seconds east of UTC, daylight saving included
local function offset(now)
    local u = os.date('!*t', now)
    u.isdst = os.date('*t', now).isdst
    return os.difftime(now, os.time(u))
end

local function zone(off)
    local a = math.abs(off)
    local m = math.floor(a % 3600 / 60)
    return string.format('UTC%s%d', off < 0 and '-' or '+', math.floor(a / 3600)) .. (m > 0 and string.format(':%02d', m) or '')
end

local function draw(now)
    -- Screenshot mode (skin variable Demo=1): show UTC, so the card does not give the time zone away
    local demo = SKIN:GetVariable('Demo') == '1'
    local p = demo and '!' or ''
    local t = os.date(p .. '*t', now)
    local h24 = is24()

    set('MZone', 'Text', zone(demo and 0 or offset(now)))
    set('MZone', 'ToolTipText', demo and '' or os.date('%Z', now))
    set('MDay', 'Text', string.format('%02d', t.day))
    set('MDayL', 'Text', os.date(p .. '%a %b', now))
    set('MHours', 'Text', h24 and string.format('%02d', t.hour) or tostring((t.hour + 11) % 12 + 1))
    set('MHoursL', 'Text', h24 and 'Hours' or (t.hour < 12 and 'Hours AM' or 'Hours PM'))
    set('MHoursHit', 'ToolTipText', 'Switch to ' .. (h24 and '12' or '24') .. ' hour')
    set('MMins', 'Text', string.format('%02d', t.min))
    set('MSecs', 'Text', string.format('%02d', t.sec))

    pct = (t.hour * 3600 + t.min * 60 + t.sec) / 864
    set('MDayPct', 'Text', string.format('%d%%', math.floor(pct)))
    set('MDateValue', 'Text', string.format('%s %d %s %d', os.date(p .. '%A', now), t.day, os.date(p .. '%B', now), t.year))
    set('MUtcValue', 'Text', os.date('!%a %H:%M', now))
end

-- click on the hours box
function Clock()
    local to = is24() and '12' or '24'
    SKIN:Bang('!SetVariable', 'Clock', to)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'Clock', to)
    draw(os.time())
    SKIN:Bang('!UpdateMeter', '*'); SKIN:Bang('!Redraw')
end

function Update()
    local now = os.time()
    if now ~= last then last = now; draw(now) end   -- the skin updates twice a second so no second is skipped
    return pct
end
