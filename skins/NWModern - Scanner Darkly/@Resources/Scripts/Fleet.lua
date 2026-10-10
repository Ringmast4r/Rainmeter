-- NWModern Scanner Darkly card. Runs Fleet.py every PERIOD seconds and lists every URL in the Scanner Darkly
-- registry, one per row, in registry (name) order so a row stays where you expect it.
-- Up = any answer below 500; 401/403 are gated dashboards answering, dot in yellow. 5xx or no answer = down, red.
-- An answer slower than SLOW ms reads yellow. ROWS show at a time; the mouse wheel scrolls one row per notch.
local PERIOD, SLOW = 60, 1500
local ROWS
local run, K, bar
local tick, lastOk = 0, nil
local links, top, src = {}, 0, ''

local function set(m, k, v) SKIN:Bang('!SetOption', m, k, v) end

function Initialize()
    run = SKIN:GetMeasure('mRun')
    ROWS = tonumber(SKIN:GetVariable('Rows')) or 14
    K = {}
    for _, n in ipairs({ 'cText', 'cText2', 'cText3', 'cGood', 'cWarn', 'cBad' }) do
        K[n] = SKIN:GetVariable(n)
    end
    -- the generator's scrollbar: the track rectangle is the room the thumb moves in
    local x, y, w, h = SKIN:GetMeter('RScroll'):GetOption('Shape'):match('^Rectangle (%d+),(%d+),(%d+),(%d+)')
    bar = { x = x, y = tonumber(y), w = w, h = tonumber(h) }
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

local function redraw() SKIN:Bang('!UpdateMeter', '*'); SKIN:Bang('!Redraw') end

local function draw()
    local maxTop = math.max(0, #links - ROWS)
    top = math.max(0, math.min(top, maxTop))
    for n = 1, ROWS do
        local l, r = links[top + n], 'R' .. n
        if l then
            set(r .. 'Name', 'Text', l.name)
            set(r .. 'Ms', 'Text', l.right)
            set(r .. 'Ms', 'FontColor', l.rc)
            SKIN:Bang('!SetVariable', 'Dot' .. n, l.col)
            set(r, 'LeftMouseUpAction', '["' .. l.url .. '"]')
            set(r, 'MouseActionCursorName', 'Hand')
            set(r, 'ToolTipTitle', l.name)
            set(r, 'ToolTipText', l.tip)
            set(r, 'ToolTipWidth', '360')
            SKIN:Bang('!ShowMeterGroup', r)
        else
            set(r, 'LeftMouseUpAction', '')
            set(r, 'ToolTipText', '')
            SKIN:Bang('!HideMeterGroup', r)
        end
    end
    if maxTop > 0 then
        local len = math.max(20, math.floor(bar.h * ROWS / #links))
        local pos = bar.y + math.floor((bar.h - len) * top / maxTop + 0.5)
        set('RScroll', 'Shape2', string.format('Rectangle %s,%d,%s,%d,2 | Fill Color %s | StrokeWidth 0',
            bar.x, pos, bar.w, len, K.cText3))
        set('MScroll', 'Text', string.format('%d-%d of %d', top + 1, top + ROWS, #links))
        SKIN:Bang('!ShowMeter', 'RScroll')
    else
        set('MScroll', 'Text', #links .. ' urls')
        SKIN:Bang('!HideMeter', 'RScroll')
    end
end

function Parse()
    local text = run:GetStringValue() or ''
    local err = text:match('Err=([^\r\n]*)')
    if err then
        set('MSub', 'Text', 'no links'); set('MSub', 'FontColor', K.cBad)
        set('MFoot', 'Text', err)
        redraw()
        return
    end
    local s = text:match('Src=([^|\r\n]*)')
    if not s then return end            -- run still going or cut short; keep the last picture
    src = s

    local down = 0
    links = {}
    for line in text:gmatch('S=([^\r\n]*)') do
        local f = split(line)
        local i = #links + 1
        local l = { name = f[1] or '', url = f[2] or '', stat = f[4] or '', ct = f[5] or '',
                    desc = (f[6] or ''):gsub('"', "'"), code = tonumber(f[7]) or 0, ms = tonumber(f[8]) or 0,
                    err = f[9] or '' }
        if l.name == 'Scanner Darkly' and not demo() then
            set('MTitle', 'LeftMouseUpAction', '["' .. l.url .. '"]')
            set('MTitle', 'ToolTipText', 'Open the Scanner Darkly index#CRLF#' .. l.url)
        end
        if demo() then
            l.name = string.format('Scanner %02d', i)
            l.url, l.ct, l.desc = 'https://example.com/', '', 'Demo mode.'
            l.stat = string.format('%d,%03d findings', (i * 37) % 900 + 12, (i * 271) % 1000)
        end
        if l.code == 0 then
            l.col, l.right, l.rc = K.cBad, (l.err ~= '' and l.err or 'down'), K.cBad
        elseif l.code >= 500 then
            l.col, l.right, l.rc = K.cBad, 'HTTP ' .. l.code, K.cBad
        else
            l.col, l.right, l.rc = K.cGood, l.ms .. ' ms', K.cText3
            if l.code >= 400 then l.col = K.cWarn end
            if l.ms >= SLOW then l.col, l.rc = K.cWarn, K.cWarn end
        end
        if l.col == K.cBad then down = down + 1 end
        local state = l.code > 0 and ('HTTP ' .. l.code .. '  -  ' .. l.ms .. ' ms') or ('no answer: ' .. l.right)
        if l.code == 401 or l.code == 403 then state = state .. '  (login)' end
        l.tip = (demo() and 'demo' or addr(l.url)) .. (l.ct ~= '' and ('   CT ' .. l.ct) or '') .. '#CRLF#' .. state
            .. (l.stat ~= '' and ('#CRLF#' .. l.stat) or '') .. (l.desc ~= '' and ('#CRLF##CRLF#' .. l.desc) or '')
        links[i] = l
    end
    draw()

    if down > 0 then
        set('MSub', 'Text', down .. ' down  -  ' .. (#links - down) .. ' up'); set('MSub', 'FontColor', K.cBad)
    else
        set('MSub', 'Text', 'all ' .. #links .. ' up'); set('MSub', 'FontColor', K.cGood)
    end
    lastOk = os.time()
    redraw()
end

-- mouse wheel: n = -1 up, 1 down
function Scroll(n)
    local to = math.max(0, math.min(top + n, #links - ROWS))
    if to == top then return end
    top = to
    draw()
    redraw()
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then tick = 0; SKIN:Bang('!CommandMeasure', 'mRun', 'Run') end
    if lastOk then
        set('MFoot', 'Text', string.format('checked %ds ago%s', os.time() - lastOk,
            src == 'registry' and '' or ('  -  ' .. src .. ' list')))
        SKIN:Bang('!UpdateMeter', 'MFoot')
    end
    return 0
end
