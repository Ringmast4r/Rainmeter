-- Shared helpers for the Net // Works lab cards (Homelab, Sites, Talkers, WiFi-Survey, LAN, Deadlines).
-- Load from Initialize():  C = dofile(SKIN:ReplaceVariables('#@#') .. 'Scripts\\Common.lua')
local C = {}

function C.set(m, k, v) SKIN:Bang('!SetOption', m, k, v) end
function C.dash(v) return (v ~= nil and v ~= '') and v or '-' end
function C.demo() return SKIN:GetVariable('Demo') == '1' end
function C.res() return SKIN:ReplaceVariables('#@#') end

function C.colors()
    local g = function(n) return SKIN:GetVariable(n) end
    return { INK = g('cFg'), BG = g('cBg'), MID = g('cMid'), WARN = g('cWarn'), CRIT = g('cCrit'),
             TRACK = g('cTrack'), ALT = g('cAlt') }
end

-- "a|b||c" -> { 'a', 'b', '', 'c' }
function C.split(s, sep)
    local t, i = {}, 1
    sep = sep or '|'
    while true do
        local j = s:find(sep, i, true)
        if not j then t[#t + 1] = s:sub(i); return t end
        t[#t + 1] = s:sub(i, j - 1); i = j + 1
    end
end

-- key=value lines from a RunCommand measure; repeated keys also collect into lists[key]
function C.parse(text)
    local kv, lists = {}, {}
    for line in (text or ''):gmatch('[^\r\n]+') do
        local k, v = line:match('^(%w+)=(.*)$')
        if k then
            v = v:gsub('%s+$', '')
            kv[k] = v
            lists[k] = lists[k] or {}
            table.insert(lists[k], v)
        end
    end
    return kv, lists
end

-- a settings file from @Resources\Local, falling back to the shipped example
function C.readConf(name)
    for _, d in ipairs({ 'Local\\', 'Examples\\' }) do
        local f = io.open(C.res() .. d .. name, 'r')
        if f then local s = f:read('*a'); f:close(); return s end
    end
    return ''
end

-- MAC -> vendor from @Resources\Lookup\oui.tsv (IEEE MA-S, MA-M, then MA-L), loaded once per skin.
-- virtual=true (access point BSSIDs): a locally administered BSSID is usually the radio's own MAC with the
-- local bit set, so look that up and mark it virtual.
local oui
function C.vendor(mac, virtual)
    local hex = (mac or ''):upper():gsub('[^0-9A-F]', '')
    if #hex < 6 then return '' end
    local b1 = tonumber(hex:sub(1, 2), 16)
    if b1 % 4 >= 2 then
        if not virtual then return 'private / random MAC' end
        local v = C.vendor(string.format('%02X', b1 - 2) .. hex:sub(3))
        return v ~= '' and (v .. ' (virtual)') or 'virtual BSSID'
    end
    if not oui then
        oui = {}
        local f = io.open(C.res() .. 'Lookup\\oui.tsv', 'r')
        if f then
            for line in f:lines() do
                local k, v = line:match('^(%x+)\t(.*)$')
                if k then oui[k] = v end
            end
            f:close()
        end
    end
    local v = oui[hex:sub(1, 9)] or oui[hex:sub(1, 7)] or oui[hex:sub(1, 6)] or ''
    return v:match('^(.-) %- ') or v          -- "Vantiva - Connected Home ..." -> "Vantiva"
end

function C.gb(bytes)
    local b = tonumber(bytes) or 0
    if b >= 1073741824 then return string.format('%.1f GB', b / 1073741824) end
    return string.format('%d MB', math.floor(b / 1048576 + 0.5))
end

function C.dur(s)
    s = tonumber(s) or 0
    if s <= 0 then return '-' end
    local d, h, m = math.floor(s / 86400), math.floor(s % 86400 / 3600), math.floor(s % 3600 / 60)
    if d > 0 then return string.format('%dd %dh', d, h) end
    if h > 0 then return string.format('%dh %dm', h, m) end
    return string.format('%dm', m)
end

-- ink below warn, yellow from warn, red from crit
function C.level(K, v, warn, crit)
    if v >= crit then return K.CRIT elseif v >= warn then return K.WARN end
    return K.INK
end

-- a stat box from the generator's statboxes(): value, sub line, and the border takes the value's colour;
-- fill marks a box that is switched on (a table filter)
local rects = {}
function C.box(K, key, val, sub, col, subCol, fill)
    rects[key] = rects[key] or SKIN:GetMeter(key .. 'Box'):GetOption('Shape'):match('^Rectangle ([%d.,]+)')
    C.set(key .. 'Val', 'Text', val); C.set(key .. 'Val', 'FontColor', col or K.INK)
    C.set(key .. 'Sub', 'Text', sub or ''); C.set(key .. 'Sub', 'FontColor', subCol or K.MID)
    C.set(key .. 'Box', 'Shape', string.format('Rectangle %s | Fill Color %s | StrokeWidth 2 | Stroke Color %s',
        rects[key], fill or K.BG, col or K.INK))
end

function C.cell(row, key, text, color)
    C.set(row .. key, 'Text', text)
    if color then C.set(row .. key, 'FontColor', color) end
end

function C.foot(lastOk, period, verb)
    if not lastOk then return end
    C.set('MFoot', 'Text', string.format('%s %ds ago  -  every %ds', verb or 'updated', os.time() - lastOk, period))
    SKIN:Bang('!UpdateMeter', 'MFoot')
end

function C.redraw() SKIN:Bang('!UpdateMeter', '*'); SKIN:Bang('!Redraw') end

return C
