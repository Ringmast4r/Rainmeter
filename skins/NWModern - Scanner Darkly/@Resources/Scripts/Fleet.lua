-- NWModern Scanner Darkly card. Runs Fleet.py every PERIOD seconds and paints one tile per URL in the
-- Scanner Darkly registry, in registry (name) order so a tile stays where you expect it.
-- Up = any answer below 500; 401/403 are gated dashboards answering, code in yellow. 5xx or no answer = down, red.
-- An answer slower than SLOW ms reads yellow. More links than tiles: the mouse wheel scrolls one row at a time.
local PERIOD, SLOW = 60, 1500
local COLS, ROWS, SLOTS
local run, K
local tick, lastOk = 0, nil
local links, top, src, total = {}, 0, '', 0

local function set(m, k, v) SKIN:Bang('!SetOption', m, k, v) end

function Initialize()
    run = SKIN:GetMeasure('mRun')
    COLS = tonumber(SKIN:GetVariable('Cols')) or 4
    ROWS = tonumber(SKIN:GetVariable('Rows')) or 7
    SLOTS = COLS * ROWS
    K = {}
    for _, n in ipairs({ 'cText', 'cText2', 'cText3', 'cGood', 'cWarn', 'cBad', 'cAccent' }) do
        K[n] = SKIN:GetVariable(n)
    end
end

local function split(s)
    local t, i = {}, 1
    while true do
        local j = s:find('|', i, true)
        if not j then t[#t + 1] = s:sub(i); return t end
        t[#t + 1] = s:sub(i, j - 1); i = j + 1
    end
end

local function demo() return SKIN:GetVariable('Demo') == '1' end

-- "http://192.0.2.10:8080/" -> "192.0.2.10:8080"
local function addr(url) return (url:gsub('^https?://', ''):gsub('/$', '')) end

local function stat(cap, val, sub, col)
    set(cap .. 'Val', 'Text', val)
    set(cap .. 'Val', 'FontColor', col or K.cText)
    set(cap .. 'Sub', 'Text', sub or '')
end

local function draw()
    local maxTop = math.max(0, math.ceil(#links / COLS) - ROWS)
    top = math.max(0, math.min(top, maxTop))
    for n = 1, SLOTS do
        local l, t = links[top * COLS + n], 'T' .. n
        if l then
            set(t .. 'Name', 'Text', l.name)
            set(t .. 'Addr', 'Text', l.addr .. (l.ct ~= '' and ('   CT ' .. l.ct) or ''))
            set(t .. 'Stat', 'Text', l.stat)
            set(t .. 'Ms', 'Text', l.right)
            set(t .. 'Ms', 'FontColor', l.rc)
            SKIN:Bang('!SetVariable', 'Dot' .. n, l.col)
            set(t, 'LeftMouseUpAction', '["' .. l.url .. '"]')
            set(t, 'MouseActionCursorName', 'Hand')
            set(t, 'ToolTipTitle', l.name)
            set(t, 'ToolTipText', l.tip)
            set(t, 'ToolTipWidth', '360')
            SKIN:Bang('!ShowMeterGroup', t)
        else
            set(t, 'LeftMouseUpAction', '')
            set(t, 'ToolTipText', '')
            SKIN:Bang('!HideMeterGroup', t)
        end
    end
    if maxTop > 0 then
        set('MScroll', 'Text', string.format('rows %d-%d of %d  -  scroll for more',
            top + 1, top + ROWS, math.ceil(#links / COLS)))
    else
        set('MScroll', 'Text', #links .. ' urls')
    end
end

function Parse()
    local text = run:GetStringValue() or ''
    local err = text:match('Err=([^\r\n]*)')
    if err then
        stat('SAll', '0', err, K.cBad)
        SKIN:Bang('!UpdateMeter', '*'); SKIN:Bang('!Redraw')
        return
    end
    local s, t = text:match('Src=([^|\r\n]*)|(%d*)')
    if not s then return end            -- run still going or cut short; keep the last picture
    src, total = s, tonumber(t) or 0

    local up, down, gated, downNames, slowMs, slowName, sumMs = 0, 0, 0, {}, -1, '', 0
    links = {}
    for line in text:gmatch('S=([^\r\n]*)') do
        local f = split(line)
        local i = #links + 1
        local l = { name = f[1] or '', url = f[2] or '', cat = f[3] or '', stat = f[4] or '', ct = f[5] or '',
                    desc = f[6] or '', code = tonumber(f[7]) or 0, ms = tonumber(f[8]) or 0, err = f[9] or '' }
        l.addr = addr(l.url)
        if demo() then
            l.name = string.format('Scanner %02d', i)
            l.addr = string.format('192.0.2.%d:%d', 10 + i, 8080 + i)
            l.url, l.ct, l.desc = 'https://example.com/', '', 'Demo mode.'
            l.stat = string.format('%d,%03d findings', (i * 37) % 900 + 12, (i * 271) % 1000)
        end
        if l.code == 0 then
            l.col, l.right, l.rc = K.cBad, (l.err ~= '' and l.err or 'down'), K.cBad
        elseif l.code >= 500 then
            l.col, l.right, l.rc = K.cBad, 'HTTP ' .. l.code, K.cBad
        else
            l.right = l.ms .. ' ms'
            l.col, l.rc = K.cGood, K.cText3
            if l.code >= 400 then l.col, l.right, l.rc = K.cWarn, l.code .. '  ' .. l.ms .. ' ms', K.cWarn end
            if l.ms >= SLOW then l.col, l.rc = K.cWarn, K.cWarn end
        end
        if l.code == 401 or l.code == 403 then gated = gated + 1 end
        if l.col == K.cBad then
            down = down + 1; downNames[#downNames + 1] = l.name
        else
            up = up + 1; sumMs = sumMs + l.ms
            if l.ms > slowMs then slowMs, slowName = l.ms, l.name end
        end
        l.desc = l.desc:gsub('"', "'")
        if l.name == 'Scanner Darkly' and not demo() then
            set('MTitle', 'LeftMouseUpAction', '["' .. l.url .. '"]')
            set('MTitle', 'ToolTipText', 'Open the Scanner Darkly index#CRLF#' .. l.url)
        end
        local state = l.code > 0 and ('HTTP ' .. l.code .. '  -  ' .. l.ms .. ' ms') or ('no answer: ' .. l.right)
        l.tip = l.url .. '#CRLF#' .. state .. (l.desc ~= '' and ('#CRLF##CRLF#' .. l.desc) or '')
        links[i] = l
    end
    draw()

    local srcNote = src == 'registry' and (total .. ' registry rows') or (src == 'cache' and 'cached list' or 'example list')
    stat('SAll', tostring(#links), srcNote)
    stat('SUp', tostring(up), gated > 0 and (gated .. ' behind a login (401/403)') or 'all open', up > 0 and K.cText or K.cBad)
    if down > 0 then
        stat('SDown', tostring(down), table.concat(downNames, ', '), K.cBad)
    else
        stat('SDown', '0', 'nothing down', K.cText)
    end
    if slowMs >= 0 then
        stat('SSlow', slowMs .. ' ms', slowName .. '  -  avg ' .. math.floor(sumMs / math.max(up, 1)) .. ' ms',
            slowMs >= SLOW and K.cWarn or K.cText)
    else
        stat('SSlow', '--', '')
    end
    lastOk = os.time()
    SKIN:Bang('!UpdateMeter', '*'); SKIN:Bang('!Redraw')
end

-- mouse wheel: n = -1 up, 1 down
function Scroll(n)
    local maxTop = math.max(0, math.ceil(#links / COLS) - ROWS)
    local to = math.max(0, math.min(top + n, maxTop))
    if to == top then return end
    top = to
    draw()
    SKIN:Bang('!UpdateMeter', '*'); SKIN:Bang('!Redraw')
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then tick = 0; SKIN:Bang('!CommandMeasure', 'mRun', 'Run') end
    if lastOk then
        set('MFoot', 'Text', string.format('checked %ds ago  -  every %ds  -  source: Scanner Darkly %s',
            os.time() - lastOk, PERIOD, src == 'registry' and 'db' or src))
        SKIN:Bang('!UpdateMeter', 'MFoot')
    end
    return 0
end
