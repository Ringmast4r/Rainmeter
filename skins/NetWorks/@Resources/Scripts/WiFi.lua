-- Net // Works Wi-Fi / Eth card. Runs WiFi.ps1 through the RunCommand measure every
-- PERIOD seconds, in the mode (wifi | eth) set by the WI-FI / ETH switch.
-- Wi-Fi signal steps ink -> yellow -> red as it drops.
local PERIOD = 5
local BARS = 5

local run, INK, MID, WARN, CRIT, TRACK, BG
local warnAt, critAt, mode
local tick, lastOk, styled = 0, nil, false

-- Screenshot mode (skin variable Demo=1): placeholder network name and documentation-only
-- addresses (RFC 5737 / RFC 7042), so screenshots never leak real details.
local DEMO_SSID = 'NetWorks-Lab'
local DEMO_ETH = { EthV4 = '192.0.2.50/24', EthGw = '192.0.2.1', EthDns = '192.0.2.53', EthMac = '00:00:5E:00:53:2A' }

local function set(m, k, v) SKIN:Bang('!SetOption', m, k, v) end
local function dash(v) return (v and v ~= '') and v or '-' end
local function demo() return SKIN:GetVariable('Demo') == '1' end

function Initialize()
    run = SKIN:GetMeasure('mRun')
    INK, MID, WARN, CRIT, TRACK, BG = SKIN:GetVariable('cFg'), SKIN:GetVariable('cMid'),
        SKIN:GetVariable('cWarn'), SKIN:GetVariable('cCrit'), SKIN:GetVariable('cTrack'), SKIN:GetVariable('cBg')
    warnAt = tonumber(SKIN:GetVariable('SignalWarn')) or 60
    critAt = tonumber(SKIN:GetVariable('SignalCrit')) or 35
    mode = (SKIN:GetVariable('Mode') == 'eth') and 'eth' or 'wifi'
end

-- runs once, on the first update, when every meter exists
local function style()
    for m, on in pairs({ MModeWifi = mode == 'wifi', MModeEth = mode == 'eth' }) do
        set(m, 'SolidColor', on and INK or TRACK)
        set(m, 'FontColor', on and BG or MID)
    end
    if mode == 'eth' then
        set('MNetCap', 'Text', 'Interface')
        for i = 1, BARS do SKIN:Bang('!HideMeter', 'MBar' .. i) end
        -- link speed takes the place of the signal bars, level with the adapter name
        set('MSig', 'FontSize', '13'); set('MSig', 'Y', '70')
        set('MDbm', 'Y', '100')
        set('VChanLab', 'Text', 'IPv4'); set('VRxLab', 'Text', 'Gateway')
        set('VTxLab', 'Text', 'DNS'); set('VAdapterLab', 'Text', 'MAC')
    end
    SKIN:Bang('!UpdateMeter', '*'); SKIN:Bang('!Redraw')
end

local function level(sig)
    if sig < critAt then return CRIT elseif sig < warnAt then return WARN end
    return INK
end

local function wifi(g)
    if g.State == nil then return false end
    if demo() and g.SSID ~= '' then g.SSID = DEMO_SSID end
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
    set('VAdapter', 'Text', dash(g.Adapter))
    return true
end

local function eth(g)
    if g.EthStatus == nil then return false end
    if demo() and g.EthStatus ~= 'none' then for k, v in pairs(DEMO_ETH) do g[k] = v end end
    local up = g.EthStatus == 'Up'
    if up then
        set('MSsid', 'Text', dash(g.EthName)); set('MSsid', 'FontColor', INK)
        set('MSec', 'Text', dash(g.EthDesc))
        set('MSig', 'Text', dash(g.EthSpeed)); set('MSig', 'FontColor', INK)
        set('MDbm', 'Text', g.EthDuplex or '')
    else
        set('MSsid', 'Text', 'NOT CONNECTED'); set('MSsid', 'FontColor', CRIT)
        set('MSec', 'Text', g.EthStatus == 'none' and 'no Ethernet adapter found' or ('state: ' .. g.EthStatus:lower()))
        set('MSig', 'Text', '-'); set('MSig', 'FontColor', MID)
        set('MDbm', 'Text', '')
    end
    set('VChan', 'Text', dash(up and g.EthV4))
    set('VRx', 'Text', dash(up and g.EthGw))
    set('VTx', 'Text', dash(up and g.EthDns))
    set('VAdapter', 'Text', dash(g.EthMac))
    return true
end

-- FinishAction of mRun
function Parse()
    local g = {}
    for line in (run:GetStringValue() or ''):gmatch('[^\r\n]+') do
        local k, v = line:match('^(%w+)=(.*)$')
        if k then g[k] = v:gsub('%s+$', '') end
    end
    local ok
    if mode == 'eth' then ok = eth(g) else ok = wifi(g) end
    if not ok then return end
    lastOk = os.time()
    SKIN:Bang('!UpdateMeter', '*'); SKIN:Bang('!Redraw')
end

function Update()
    if not styled then styled = true; style() end
    tick = tick + 1
    if tick >= PERIOD then tick = 0; SKIN:Bang('!CommandMeasure', 'mRun', 'Run') end
    if lastOk then
        set('MFoot', 'Text', string.format('updated %ds ago  -  every %ds', os.time() - lastOk, PERIOD))
        SKIN:Bang('!UpdateMeter', 'MFoot')
    end
    return 0
end
