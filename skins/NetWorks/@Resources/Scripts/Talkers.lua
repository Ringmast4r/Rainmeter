-- Net // Works Who's talking card. Runs Talkers.ps1 every PERIOD seconds: which programs hold connections to the
-- internet and to whom. Threat-listed addresses (IP // Revealer) turn red.
local PERIOD, ROWS = 15, 16
local C, K, run
local tick, lastOk = 0, nil

function Initialize()
    C = dofile(SKIN:ReplaceVariables('#@#') .. 'Scripts\\Common.lua')
    K = C.colors()
    run = SKIN:GetMeasure('mRun')
end

local function demoIp(ip, i)
    if ip:find(':', 1, true) then return '2001:db8::' .. string.format('%x', i) end
    return '203.0.113.' .. (10 + i)
end

function Parse()
    local kv, lists = C.parse(run:GetStringValue())
    if not kv.Conns then return end
    local flagged = tonumber(kv.Flagged) or 0
    C.box(K, 'Conns', kv.Conns, 'established TCP')
    C.box(K, 'Hosts', kv.Hosts, 'public addresses')
    C.box(K, 'Procs', kv.Procs, 'with open connections')
    C.box(K, 'Flag', tostring(flagged), flagged > 0 and 'on a threat list' or 'none on threat lists',
        flagged > 0 and K.CRIT or K.INK, flagged > 0 and K.CRIT or K.MID)

    local t = lists.T or {}
    for i = 1, ROWS do
        local r = 'R' .. i
        if t[i] then
            local f = C.split(t[i])
            local proc, ip, port, n, cc, city, org, flag = f[1], f[2], f[3], f[4], f[5], f[6], f[7], f[8] or ''
            local hot = flag ~= ''
            local where = (cc ~= '' and (cc .. ((city ~= '') and ('  ' .. city) or ''))) or '-'
            C.cell(r, 'Proc', C.dash(proc), K.INK)
            C.cell(r, 'Ip', C.demo() and demoIp(ip, i) or ip, hot and K.CRIT or K.INK)
            C.cell(r, 'Org', C.dash(org), hot and K.CRIT or K.MID)
            C.cell(r, 'Where', where, K.MID)
            C.cell(r, 'Port', C.dash(port), K.MID)
            C.cell(r, 'N', C.dash(n), K.INK)
            C.set(r .. 'Ip', 'ToolTipText', hot and ('threat listed: ' .. flag) or '')
        else
            for _, k in ipairs({ 'Proc', 'Ip', 'Org', 'Where', 'Port', 'N' }) do C.cell(r, k, '') end
            C.set(r .. 'Ip', 'ToolTipText', '')
        end
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
