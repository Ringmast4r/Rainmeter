-- Net // Works Deadlines card. Reads @Resources\Local\deadlines.txt (falls back to Examples\deadlines.txt):
-- one date per line as  2026-10-11 | Name . Yellow inside WARN days, red inside CRIT. Past dates stay KEEP days.
local PERIOD, ROWS, WARN_D, CRIT_D, KEEP = 60, 6, 30, 7, 2
local C, K
local tick = PERIOD

function Initialize()
    C = dofile(SKIN:ReplaceVariables('#@#') .. 'Scripts\\Common.lua')
    K = C.colors()
end

local function noon(y, m, d) return os.time({ year = y, month = m, day = d, hour = 12 }) end

local function color(days)
    if days <= CRIT_D then return K.CRIT elseif days <= WARN_D then return K.WARN end
    return K.INK
end

local function refresh()
    local t = os.date('*t')
    local today = noon(t.year, t.month, t.day)
    local list = {}
    for line in C.readConf('deadlines.txt'):gmatch('[^\r\n]+') do
        local y, m, d, name = line:match('^%s*(%d%d%d%d)%-(%d%d)%-(%d%d)%s*[|]?%s*(.-)%s*$')
        if y then
            local at = noon(tonumber(y), tonumber(m), tonumber(d))
            local days = math.floor((at - today) / 86400 + 0.5)
            if days >= -KEEP then list[#list + 1] = { at = at, days = days, name = name ~= '' and name or 'Deadline' } end
        end
    end
    table.sort(list, function(a, b) return a.at < b.at end)

    local nextOne
    for _, e in ipairs(list) do if e.days >= 0 then nextOne = e; break end end
    if nextOne then
        local col = color(nextOne.days)
        C.set('MNextName', 'Text', nextOne.name); C.set('MNextName', 'FontColor', col)
        C.set('MNextDate', 'Text', os.date('%A %d %B %Y', nextOne.at))
        C.set('MNextDays', 'Text', nextOne.days == 0 and 'TODAY' or tostring(nextOne.days)); C.set('MNextDays', 'FontColor', col)
        C.set('MNextUnit', 'Text', nextOne.days == 0 and '' or (nextOne.days == 1 and 'day' or 'days'))
        C.set('MNextBox', 'Shape', 'Rectangle 19,51,302,68 | Fill Color ' .. K.BG .. ' | StrokeWidth 2 | Stroke Color ' .. col)
    else
        C.set('MNextName', 'Text', 'nothing coming up'); C.set('MNextName', 'FontColor', K.MID)
        C.set('MNextDate', 'Text', 'add dates: right-click > Edit deadlines'); C.set('MNextDays', 'Text', '')
        C.set('MNextUnit', 'Text', '')
    end
    for i = 1, ROWS do
        local e, r = list[i], 'R' .. i
        if e then
            local col = e.days < 0 and K.MID or color(e.days)
            C.cell(r, 'Name', e.name, e.days < 0 and K.MID or K.INK)
            C.cell(r, 'Date', os.date('%Y-%m-%d', e.at), K.MID)
            C.cell(r, 'Days', (e.days < 0 and 'passed') or (e.days == 0 and 'today') or tostring(e.days), col)
        else
            for _, k in ipairs({ 'Name', 'Date', 'Days' }) do C.cell(r, k, '') end
        end
    end
    C.set('MFoot', 'Text', string.format('%d upcoming  -  as of %s', #list, os.date('%a %d %b')))
    C.redraw()
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then tick = 0; refresh() end
    return 0
end
