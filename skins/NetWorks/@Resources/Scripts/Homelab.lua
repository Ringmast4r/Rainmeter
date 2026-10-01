-- Net // Works Homelab card. Runs Homelab.ps1 (one SSH call to the Proxmox host) every PERIOD seconds.
-- Boxes: host CPU (sub: load per core), memory, IO wait (sub: processes stuck in disk wait), guests running.
-- Dot grid: every guest by ID. Table: guests that should be up but are not, then the busiest.
local PERIOD, ROWS, DOTS = 30, 12, 200
local C, K, run
local tick, lastOk, err = 0, nil, nil

function Initialize()
    C = dofile(SKIN:ReplaceVariables('#@#') .. 'Scripts\\Common.lua')
    K = C.colors()
    run = SKIN:GetMeasure('mRun')
end

local function box(...) C.box(K, ...) end

local function memPair(u, t)
    local G = 1073741824
    if t >= G then return string.format('%.1f / %d GB', u / G, math.floor(t / G + 0.5)) end
    return C.gb(u) .. ' / ' .. C.gb(t)
end

local function guestName(g)
    return C.demo() and string.format('service-%03d', g.id) or g.name
end

function Parse()
    local kv, lists = C.parse(run:GetStringValue())
    if kv.Err then
        err = kv.Err
        box('Guests', 'OFFLINE', kv.Err, K.CRIT, K.CRIT)
        C.set('MFoot', 'Text', 'cannot reach the host  -  if Mullvad is on, allow LAN access')
        C.redraw(); return
    end
    if not kv.Node then return end
    err = nil

    local cores = tonumber(kv.Cores) or 1
    local cpu, wait, load = tonumber(kv.Cpu) or 0, tonumber(kv.Wait) or 0, tonumber(kv.Load) or 0
    local perCore = load / cores
    box('Cpu', string.format('%d%%', math.floor(cpu + 0.5)),
        string.format(load >= 10 and 'load %.0f / %d cores' or 'load %.1f / %d cores', load, cores),
        C.level(K, cpu, 70, 90), C.level(K, perCore, 1.0, 2.0))
    local mu, mt = tonumber(kv.MemUsed) or 0, tonumber(kv.MemTotal) or 1
    local mp = mu / mt * 100
    box('Mem', string.format('%d%%', math.floor(mp + 0.5)), C.gb(mu) .. ' / ' .. C.gb(mt), C.level(K, mp, 85, 95))
    local dstate = tonumber(kv.DState) or 0
    box('Wait', string.format('%.1f%%', wait), dstate .. ' stuck on disk',
        C.level(K, wait, 5, 20), C.level(K, dstate, 10, 40))

    local guests, running, down, off = {}, 0, 0, 0
    for _, line in ipairs(lists.G or {}) do
        local f = C.split(line)
        local g = { id = tonumber(f[1]) or 0, name = f[2], kind = f[3], status = f[4], onboot = f[5] == '1',
                    cpu = tonumber(f[6]) or 0, mem = tonumber(f[7]) or 0, maxmem = tonumber(f[8]) or 0, up = tonumber(f[9]) or 0 }
        if g.status == 'running' then running = running + 1; g.rank = 1
        elseif g.onboot then down = down + 1; g.rank = 0
        else off = off + 1; g.rank = 2 end
        guests[#guests + 1] = g
    end
    box('Guests', running .. ' / ' .. #guests, down .. ' down  /  ' .. off .. ' off',
        down > 0 and K.CRIT or K.INK, down > 0 and K.CRIT or K.MID)
    C.set('MHint', 'Text', '// ' .. (C.demo() and 'pve' or kv.Node))

    -- dot grid, by guest ID
    table.sort(guests, function(a, b) return a.id < b.id end)
    for i = 1, DOTS do
        local g, m = guests[i], 'D' .. i
        if g then
            local col = (g.rank == 0 and K.CRIT) or (g.rank == 2 and K.MID) or (g.cpu >= 80 and K.WARN) or K.INK
            C.set(m, 'SolidColor', col)
            C.set(m, 'ToolTipText', string.format('%d  %s  -  %s  -  cpu %d%%  -  %s / %s', g.id, guestName(g),
                g.rank == 0 and 'DOWN' or g.status, math.floor(g.cpu + 0.5), C.gb(g.mem), C.gb(g.maxmem)))
            SKIN:Bang('!ShowMeter', m)
        else
            SKIN:Bang('!HideMeter', m)
        end
    end

    -- table: down first, then the busiest running, then stopped-by-choice
    table.sort(guests, function(a, b)
        if a.rank ~= b.rank then return a.rank < b.rank end
        if a.rank == 1 and a.cpu ~= b.cpu then return a.cpu > b.cpu end
        return a.id < b.id
    end)
    for i = 1, ROWS do
        local g, r = guests[i], 'R' .. i
        if g then
            local st, stc = g.status, K.INK
            if g.rank == 0 then st, stc = 'DOWN', K.CRIT elseif g.rank == 2 then st, stc = 'off', K.MID end
            local memPct = g.maxmem > 0 and g.mem / g.maxmem * 100 or 0
            C.cell(r, 'Id', tostring(g.id), g.rank == 1 and K.INK or stc)
            C.cell(r, 'Name', guestName(g), g.rank == 1 and K.INK or stc)
            C.cell(r, 'State', st, stc)
            C.cell(r, 'Cpu', g.rank == 1 and string.format('%d%%', math.floor(g.cpu + 0.5)) or '-', C.level(K, g.cpu, 70, 90))
            C.cell(r, 'Mem', g.rank == 1 and memPair(g.mem, g.maxmem) or '-', C.level(K, memPct, 85, 95))
            C.cell(r, 'Up', g.rank == 1 and C.dur(g.up) or '-', K.MID)
        else
            for _, k in ipairs({ 'Id', 'Name', 'State', 'Cpu', 'Mem', 'Up' }) do C.cell(r, k, '') end
        end
    end
    lastOk = os.time()
    C.redraw()
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then tick = 0; SKIN:Bang('!CommandMeasure', 'mRun', 'Run') end
    if not err then C.foot(lastOk, PERIOD, 'checked') end
    return 0
end
