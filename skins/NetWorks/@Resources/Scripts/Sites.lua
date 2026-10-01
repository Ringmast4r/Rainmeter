-- Net // Works Sites card. Runs Sites.ps1 every PERIOD seconds. Up = any answer below 500 (401/403 are gated
-- sites answering, code in yellow); 5xx or no answer = down, in red. A site that is up but takes SLOW ms reads
-- SLOW in yellow, VERY_SLOW in red (cold connection each check: DNS, TLS and the response headers).
-- Worst first: down, error, check, then slowest. ROWS show at a time; the mouse wheel scrolls STEP rows.
local PERIOD, ROWS, SLOW, VERY_SLOW, STEP = 60, 16, 350, 1000, 3
local C, K, run
local tick, lastOk = 0, nil
local sites, top, bar = {}, 0, nil

function Initialize()
    C = dofile(SKIN:ReplaceVariables('#@#') .. 'Scripts\\Common.lua')
    K = C.colors()
    run = SKIN:GetMeasure('mRun')
    -- the generator's scrollbar(): the track rectangle is the room the thumb moves in
    local x, y, w, h = SKIN:GetMeter('RScroll'):GetOption('Shape'):match('^Rectangle (%d+),(%d+),(%d+),(%d+)')
    bar = { x = x, y = tonumber(y), w = w, h = tonumber(h) }
end

local function banner(ok, cap, val)
    local col = ok and K.INK or K.CRIT
    if ok then
        C.set('MStatusBox', 'Shape', 'Rectangle 18,50,404,48 | Fill Color ' .. K.INK .. ' | StrokeWidth 0')
        C.set('MStatusCap', 'FontColor', K.BG); C.set('MStatusVal', 'FontColor', K.BG)
    else
        C.set('MStatusBox', 'Shape', 'Rectangle 19,51,402,46 | Fill Color ' .. K.BG .. ' | StrokeWidth 2 | Stroke Color ' .. col)
        C.set('MStatusCap', 'FontColor', col); C.set('MStatusVal', 'FontColor', col)
    end
    C.set('MStatusCap', 'Text', cap); C.set('MStatusVal', 'Text', val)
end

-- rows top+1 .. top+ROWS of the sorted list, the thumb and the footer note
local function draw()
    top = math.max(0, math.min(top, #sites - ROWS))
    for i = 1, ROWS do
        local s, r = sites[top + i], 'R' .. i
        if s then
            C.cell(r, 'Site', s.shown, s.sc)
            C.cell(r, 'Code', s.code > 0 and tostring(s.code) or '-', s.cc)
            C.cell(r, 'Ms', s.code > 0 and (s.ms .. ' ms') or (s.err ~= '' and s.err or '-'), s.code > 0 and s.tc or K.CRIT)
            C.cell(r, 'State', s.state, s.sc)
            C.set(r .. 'Hit', 'LeftMouseUpAction', '["' .. s.url .. '"]')
            C.set(r .. 'Hit', 'MouseActionCursor', '1')
            C.set(r .. 'Hit', 'MouseActionCursorName', 'Hand')
            C.set(r .. 'Hit', 'ToolTipText', s.url .. (s.err ~= '' and ('  -  ' .. s.err) or ''))
        else
            for _, k in ipairs({ 'Site', 'Code', 'Ms', 'State' }) do C.cell(r, k, '') end
            C.set(r .. 'Hit', 'LeftMouseUpAction', ''); C.set(r .. 'Hit', 'ToolTipText', '')
            C.set(r .. 'Hit', 'MouseActionCursor', '0')
        end
    end
    if #sites > ROWS then
        local len = math.max(12, math.floor(bar.h * ROWS / #sites))
        local pos = bar.y + math.floor((bar.h - len) * top / (#sites - ROWS) + 0.5)
        C.set('RScroll', 'Shape2', string.format('Rectangle %s,%d,%s,%d | Fill Color %s | StrokeWidth 0', bar.x, pos, bar.w, len, K.INK))
        C.set('MScroll', 'Text', string.format('%d-%d of %d  -  scroll', top + 1, top + ROWS, #sites))
        SKIN:Bang('!ShowMeter', 'RScroll')
    else
        C.set('MScroll', 'Text', '')
        SKIN:Bang('!HideMeter', 'RScroll')
    end
end

function Parse()
    local kv, lists = C.parse(run:GetStringValue())
    if kv.Err then banner(false, 'no sites to check', kv.Err); C.redraw(); return end
    if not lists.S then return end

    local down, slowest, slowName = {}, -1, ''
    sites = {}
    for i, line in ipairs(lists.S) do
        local f = C.split(line)
        local site, code, ms, err = f[1], tonumber(f[2]) or 0, tonumber(f[3]) or 0, f[4] or ''
        -- sc = site and state colour, cc = code colour, tc = time colour
        local s = { idx = i, code = code, ms = ms, err = err, state = 'UP', sc = K.INK, cc = K.MID, rank = 0 }
        s.tc = C.level(K, ms, SLOW, VERY_SLOW)
        s.shown = C.demo() and string.format('site-%02d.example', i) or site:gsub('^https?://', ''):gsub('/$', '')
        s.url = site:match('^https?://') and site or ('https://' .. site)
        if code == 0 then s.state, s.sc, s.rank = 'DOWN', K.CRIT, 3
        elseif code >= 500 then s.state, s.sc, s.cc, s.rank = 'ERROR', K.CRIT, K.CRIT, 2
        elseif code >= 400 and code ~= 401 and code ~= 403 then s.state, s.sc, s.cc, s.rank = 'CHECK', K.WARN, K.WARN, 1
        else
            if code >= 400 then s.cc = K.WARN end
            if s.tc ~= K.INK then s.state, s.sc = 'SLOW', s.tc end
        end
        if s.rank >= 2 then down[#down + 1] = s.shown end
        if code > 0 and ms > slowest then slowest, slowName = ms, s.shown end
        sites[i] = s
    end
    table.sort(sites, function(a, b)
        if a.rank ~= b.rank then return a.rank > b.rank end
        if a.ms ~= b.ms then return a.ms > b.ms end
        return a.idx < b.idx
    end)
    draw()

    local n = #sites
    if #down == 0 then
        banner(true, slowest >= 0 and ('slowest: ' .. slowName .. '  ' .. slowest .. ' ms') or '', 'all ' .. n .. ' up')
    else
        banner(false, 'down: ' .. table.concat(down, ', '), #down .. ' of ' .. n .. ' down')
    end
    lastOk = os.time()
    C.redraw()
end

-- mouse wheel: n = -1 up, 1 down
function Scroll(n)
    local to = math.max(0, math.min(top + n * STEP, #sites - ROWS))
    if to == top then return end
    top = to
    draw()
    C.redraw()
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then tick = 0; SKIN:Bang('!CommandMeasure', 'mRun', 'Run') end
    C.foot(lastOk, PERIOD, 'checked')
    return 0
end
