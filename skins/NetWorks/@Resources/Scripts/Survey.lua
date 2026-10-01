-- Net // Works Wi-Fi survey card. Runs Survey.ps1 every PERIOD seconds: every BSSID in range, strongest first,
-- with the access point vendor from its MAC, plus how crowded each 2.4 / 5 GHz channel is.
local PERIOD, ROWS, BAR_MAX, BASE = 30, 15, 36, 111
local CH24 = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 }
local CH5 = { 36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144, 149, 153, 157, 161, 165 }
local C, K, run
local tick, lastOk = 0, nil

function Initialize()
    C = dofile(SKIN:ReplaceVariables('#@#') .. 'Scripts\\Common.lua')
    K = C.colors()
    run = SKIN:GetMeasure('mRun')
end

local function bars(prefix, chans, count, maxN)
    for _, ch in ipairs(chans) do
        local n, m = count[ch] or 0, 'C' .. prefix .. '_' .. ch
        local h = n == 0 and 2 or math.max(4, math.floor(n / maxN * BAR_MAX + 0.5))
        C.set(m, 'Y', BASE - h); C.set(m, 'H', h)
        C.set(m, 'SolidColor', n == 0 and K.TRACK or C.level(K, n, 4, 8))
        C.set(m, 'ToolTipText', string.format('channel %d: %d network%s', ch, n, n == 1 and '' or 's'))
    end
end

function Parse()
    local kv, lists = C.parse(run:GetStringValue())
    local nets = {}
    for _, line in ipairs(lists.B or {}) do
        local f = C.split(line)
        nets[#nets + 1] = { ssid = f[1], mac = f[2], sig = tonumber(f[3]) or 0, ch = tonumber(f[4]) or 0,
                            band = f[5], radio = f[6], auth = f[7] or '' }
    end
    if kv.Err and #nets == 0 then
        C.cell('R1', 'Ssid', kv.Err, K.CRIT)
        C.redraw(); return
    end
    table.sort(nets, function(a, b) return a.sig > b.sig end)

    local c24, c5, maxN = {}, {}, 1
    for _, n in ipairs(nets) do
        local t = (n.band == '2.4 GHz') and c24 or ((n.band == '5 GHz') and c5 or nil)
        if t then t[n.ch] = (t[n.ch] or 0) + 1; maxN = math.max(maxN, t[n.ch]) end
    end
    bars('24', CH24, c24, maxN)
    bars('5', CH5, c5, maxN)
    C.set('MHint', 'Text', string.format('// %d access point%s in range', #nets, #nets == 1 and '' or 's'))

    for i = 1, ROWS do
        local n, r = nets[i], 'R' .. i
        if n then
            local name, nc = n.ssid, K.INK
            if C.demo() and name ~= '' then name = string.format('NETWORK-%02d', i) end
            if name == '' then name, nc = '(hidden)', K.MID end
            local open = n.auth:lower() == 'open'
            C.cell(r, 'Ssid', name, nc)
            C.cell(r, 'Vendor', C.dash(C.vendor(n.mac, true)), K.MID)
            C.cell(r, 'Ch', tostring(n.ch), K.INK)
            C.cell(r, 'Band', n.band, K.MID)
            C.cell(r, 'Sig', n.sig .. '%', (n.sig < 35 and K.CRIT) or (n.sig < 60 and K.WARN) or K.INK)
            C.cell(r, 'Sec', open and 'OPEN' or n.auth, open and K.WARN or K.MID)
            C.set(r .. 'Ssid', 'ToolTipText', C.demo() and '' or (n.mac .. '  -  ' .. n.radio))
        else
            for _, k in ipairs({ 'Ssid', 'Vendor', 'Ch', 'Band', 'Sig', 'Sec' }) do C.cell(r, k, '') end
            C.set(r .. 'Ssid', 'ToolTipText', '')
        end
    end
    lastOk = os.time()
    C.redraw()
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then tick = 0; SKIN:Bang('!CommandMeasure', 'mRun', 'Run') end
    C.foot(lastOk, PERIOD, 'scanned')
    return 0
end
