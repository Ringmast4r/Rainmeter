-- Net // Works Sites card. Runs Sites.ps1 every PERIOD seconds. Up = any answer below 500 (401/403 are gated
-- sites answering); 5xx or no answer = down. Time goes yellow past SLOW ms, red past VERY_SLOW.
local PERIOD, ROWS, SLOW, VERY_SLOW = 60, 16, 1500, 4000
local C, K, run
local tick, lastOk = 0, nil

function Initialize()
    C = dofile(SKIN:ReplaceVariables('#@#') .. 'Scripts\\Common.lua')
    K = C.colors()
    run = SKIN:GetMeasure('mRun')
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

function Parse()
    local kv, lists = C.parse(run:GetStringValue())
    if kv.Err then banner(false, 'no sites to check', kv.Err); C.redraw(); return end
    if not lists.S then return end

    local down, slowest, slowName = {}, -1, ''
    for i = 1, ROWS do
        local line, r = lists.S[i], 'R' .. i
        if line then
            local f = C.split(line)
            local site, code, ms, err = f[1], tonumber(f[2]) or 0, tonumber(f[3]) or 0, f[4] or ''
            local shown = C.demo() and string.format('site-%02d.example', i) or site:gsub('^https?://', ''):gsub('/$', '')
            local state, sc, cc = 'UP', K.INK, K.MID
            if code == 0 then state, sc = 'DOWN', K.CRIT
            elseif code >= 500 then state, sc, cc = 'ERROR', K.CRIT, K.CRIT
            elseif code >= 400 and code ~= 401 and code ~= 403 then state, sc, cc = 'CHECK', K.WARN, K.WARN end
            if sc == K.CRIT then down[#down + 1] = shown end
            if code > 0 and ms > slowest then slowest, slowName = ms, shown end
            C.cell(r, 'Site', shown, sc == K.CRIT and K.CRIT or K.INK)
            C.cell(r, 'Code', code > 0 and tostring(code) or '-', cc)
            C.cell(r, 'Ms', code > 0 and (ms .. ' ms') or (err ~= '' and err or '-'), code > 0 and C.level(K, ms, SLOW, VERY_SLOW) or K.CRIT)
            C.cell(r, 'State', state, sc)
            local url = site:match('^https?://') and site or ('https://' .. site)
            C.set(r .. 'Hit', 'LeftMouseUpAction', '["' .. url .. '"]')
            C.set(r .. 'Hit', 'MouseActionCursorName', 'Hand')
            C.set(r .. 'Hit', 'ToolTipText', url .. (err ~= '' and ('  -  ' .. err) or ''))
        else
            for _, k in ipairs({ 'Site', 'Code', 'Ms', 'State' }) do C.cell(r, k, '') end
            C.set(r .. 'Hit', 'LeftMouseUpAction', ''); C.set(r .. 'Hit', 'ToolTipText', '')
            C.set(r .. 'Hit', 'MouseActionCursor', '0')
        end
    end
    local n = math.min(#lists.S, ROWS)
    if #down == 0 then
        banner(true, slowest >= 0 and ('slowest: ' .. slowName .. '  ' .. slowest .. ' ms') or '', 'all ' .. n .. ' up')
    else
        banner(false, 'down: ' .. table.concat(down, ', '), #down .. ' of ' .. n .. ' down')
    end
    lastOk = os.time()
    C.redraw()
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then tick = 0; SKIN:Bang('!CommandMeasure', 'mRun', 'Run') end
    C.foot(lastOk, PERIOD, 'checked')
    return 0
end
