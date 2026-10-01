-- Net // Works Wi-Fi card. Runs WiFi.ps1 (netsh) through the RunCommand
-- measure every PERIOD seconds. Signal steps ink -> yellow -> red as it drops.
local PERIOD = 5
local BARS = 5

local run, INK, MID, WARN, CRIT, TRACK
local warnAt, critAt
local tick, lastOk = 0, nil

local function set(m, k, v) SKIN:Bang('!SetOption', m, k, v) end

function Initialize()
    run = SKIN:GetMeasure('mRun')
    INK, MID, WARN, CRIT, TRACK = SKIN:GetVariable('cFg'), SKIN:GetVariable('cMid'),
        SKIN:GetVariable('cWarn'), SKIN:GetVariable('cCrit'), SKIN:GetVariable('cTrack')
    warnAt = tonumber(SKIN:GetVariable('SignalWarn')) or 60
    critAt = tonumber(SKIN:GetVariable('SignalCrit')) or 35
end

local function level(sig)
    if sig < critAt then return CRIT elseif sig < warnAt then return WARN end
    return INK
end

-- FinishAction of mRun
function Parse()
    local g = {}
    for line in (run:GetStringValue() or ''):gmatch('[^\r\n]+') do
        local k, v = line:match('^(%w+)=(.*)$')
        if k then g[k] = v:gsub('%s+$', '') end
    end
    if g.State == nil then return end

    local connected = (g.State == 'connected') and g.SSID ~= ''
    local sig = tonumber(g.Signal) or 0
    if connected then
        local c = level(sig)
        set('MSsid', 'Text', g.SSID); set('MSsid', 'FontColor', INK)
        set('MSec', 'Text', (g.Auth or '') .. '  /  ' .. (g.Radio or ''))
        set('MSig', 'Text', sig .. '%'); set('MSig', 'FontColor', c)
        -- netsh signal quality maps roughly linearly onto -100..-50 dBm
        set('MDbm', 'Text', string.format('~%d dBm', math.floor(sig / 2 - 100)))
        local lit = math.ceil(sig / (100 / BARS))
        for i = 1, BARS do set('MBar' .. i, 'SolidColor', i <= lit and c or TRACK) end
        set('VChan', 'Text', (g.Channel or '-') .. ((g.Band or '') ~= '' and ('  (' .. g.Band .. ')') or ''))
        set('VRx', 'Text', (g.Rx ~= '' and g.Rx or '-') .. ' Mbps')
        set('VTx', 'Text', (g.Tx ~= '' and g.Tx or '-') .. ' Mbps')
    else
        set('MSsid', 'Text', 'NOT CONNECTED'); set('MSsid', 'FontColor', CRIT)
        set('MSec', 'Text', g.State ~= '' and ('state: ' .. g.State) or 'no Wi-Fi adapter found')
        set('MSig', 'Text', '-'); set('MSig', 'FontColor', MID)
        set('MDbm', 'Text', '')
        for i = 1, BARS do set('MBar' .. i, 'SolidColor', TRACK) end
        for _, m in ipairs({ 'VChan', 'VRx', 'VTx' }) do set(m, 'Text', '-') end
    end
    set('VAdapter', 'Text', (g.Adapter ~= '' and g.Adapter) or '-')
    lastOk = os.time()
    SKIN:Bang('!UpdateMeter', '*'); SKIN:Bang('!Redraw')
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then tick = 0; SKIN:Bang('!CommandMeasure', 'mRun', 'Run') end
    if lastOk then
        set('MFoot', 'Text', string.format('updated %ds ago  -  every %ds', os.time() - lastOk, PERIOD))
        SKIN:Bang('!UpdateMeter', 'MFoot')
    end
    return 0
end
