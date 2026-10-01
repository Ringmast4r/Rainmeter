-- Net // Works LAN watch card. Runs Lan.ps1 every PERIOD seconds (it ping-sweeps every 5 minutes on its own;
-- "Sweep now" runs mSweep). New devices (first seen in the last 24 h) are listed first in yellow, then everything
-- else by address, Proxmox containers last.
local PERIOD, ROWS, NEW_FOR = 60, 16, 86400
local C, K
local tick, lastOk = 0, nil

function Initialize()
    C = dofile(SKIN:ReplaceVariables('#@#') .. 'Scripts\\Common.lua')
    K = C.colors()
end

local function ipnum(ip)
    local a, b, c, d = ip:match('^(%d+)%.(%d+)%.(%d+)%.(%d+)$')
    return a and (((tonumber(a) * 256 + tonumber(b)) * 256 + tonumber(c)) * 256 + tonumber(d)) or 0
end

local function age(first, now)
    if first == 0 then return 'known' end
    local s = now - first
    if s < 3600 then return math.floor(s / 60) .. 'm' end
    if s < 86400 then return math.floor(s / 3600) .. 'h' end
    return math.floor(s / 86400) .. 'd'
end

function Parse(measure)
    local m = SKIN:GetMeasure(measure or 'mRun')
    local kv, lists = C.parse(m:GetStringValue())
    if kv.Err then C.box(K, 'Net', 'OFFLINE', kv.Err, K.CRIT, K.CRIT); C.redraw(); return end
    if not kv.Net then return end

    local now, devs, newN, ctN, clashN = os.time(), {}, 0, 0, 0
    for _, line in ipairs(lists.D or {}) do
        local f = C.split(line)
        local d = { ip = f[1], mac = f[2], name = f[3], first = tonumber(f[4]) or 0, ct = f[5] == '1', clash = f[6] or '' }
        d.new = d.first > 0 and now - d.first < NEW_FOR
        d.rank = (d.clash ~= '' and -1) or (d.new and 0) or (d.ct and 2 or 1)
        if d.new then newN = newN + 1 end
        if d.clash ~= '' then clashN = clashN + 1 end
        if d.ct then ctN = ctN + 1 end
        devs[#devs + 1] = d
    end
    table.sort(devs, function(a, b)
        if a.rank ~= b.rank then return a.rank < b.rank end
        return ipnum(a.ip) < ipnum(b.ip)
    end)

    local addr, plen = (C.demo() and '192.168.1.0/24' or kv.Net):match('^(.-)/(%d+)$')
    C.box(K, 'Dev', tostring(#devs), (#devs - ctN) .. ' physical')
    C.box(K, 'New', tostring(newN), newN > 0 and 'first seen today' or 'nothing new', newN > 0 and K.WARN or K.INK,
        newN > 0 and K.WARN or K.MID)
    C.box(K, 'Ct', tostring(ctN), 'Proxmox guests')
    local swept = tonumber(kv.Swept) or 0
    C.box(K, 'Net', addr or kv.Net, '/' .. (plen or '?') .. '  -  ' .. (swept > 0 and ('swept ' .. age(swept, now) .. ' ago') or 'sweeping...'))

    for i = 1, ROWS do
        local d, r = devs[i], 'R' .. i
        if d then
            local col = (d.clash ~= '' and K.CRIT) or (d.new and K.WARN) or (d.ct and K.MID) or K.INK
            local ip, mac, name = d.ip, d.mac, d.name
            if d.clash ~= '' then name = 'IP CLASH: ' .. d.clash end
            if C.demo() then
                ip = '192.168.1.' .. (ipnum(d.ip) % 256)
                mac = string.format('00:00:5E:00:53:%02X', i)
                name = name ~= '' and string.format('device-%02d', i) or ''
            end
            C.cell(r, 'Ip', ip, col)
            C.cell(r, 'Name', C.dash(name), col)
            C.set(r .. 'Name', 'ToolTipText', d.clash ~= '' and (d.clash .. ' is configured with this address, but a different device '
                .. '(' .. d.mac .. ') answers on it' .. (d.name ~= '' and (': ' .. d.name) or '')) or '')
            C.cell(r, 'Vendor', C.dash(C.vendor(d.mac)), d.new and K.WARN or K.MID)
            C.cell(r, 'Mac', mac, K.MID)
            C.cell(r, 'Seen', d.new and ('new ' .. age(d.first, now)) or age(d.first, now), d.new and K.WARN or K.MID)
        else
            for _, k in ipairs({ 'Ip', 'Name', 'Vendor', 'Mac', 'Seen' }) do C.cell(r, k, '') end
            C.set(r .. 'Name', 'ToolTipText', '')
        end
    end
    C.set('MHint', 'Text', string.format('// %d devices', #devs) ..
        (clashN > 0 and string.format('  -  %d IP clash%s', clashN, clashN == 1 and '' or 'es') or ''))
    C.set('MHint', 'FontColor', clashN > 0 and K.CRIT or K.MID)
    lastOk = os.time()
    C.redraw()
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then tick = 0; SKIN:Bang('!CommandMeasure', 'mRun', 'Run') end
    C.foot(lastOk, PERIOD, 'checked')
    return 0
end
