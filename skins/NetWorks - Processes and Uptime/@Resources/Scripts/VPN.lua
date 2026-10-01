-- Net // Works VPN card. Runs VPN.ps1 through the RunCommand measure every
-- PERIOD seconds and paints which VPN carries your traffic.
local PERIOD = 10
local ROWS = { { key = 'Proton', meter = 'RProton' }, { key = 'Mullvad', meter = 'RMullvad' },
               { key = 'NetWorks', meter = 'RNetWorks' }, { key = 'Other', meter = 'ROther' } }
local STATE_TEXT = { CONNECTED = 'CONNECTED', CONNECTING = 'CONNECTING', READY = 'READY - not connected',
                     OFF = 'OFF', ['NOT INSTALLED'] = 'NOT INSTALLED' }

local run, INK, BG, MID, WARN
local tick, lastOk = 0, nil

local function set(m, k, v) SKIN:Bang('!SetOption', m, k, v) end

function Initialize()
    run = SKIN:GetMeasure('mRun')
    INK, BG, MID, WARN = SKIN:GetVariable('cFg'), SKIN:GetVariable('cBg'), SKIN:GetVariable('cMid'), SKIN:GetVariable('cWarn')
end

-- FinishAction of mRun
function Parse()
    local got = {}
    for line in (run:GetStringValue() or ''):gmatch('[^\r\n]+') do
        local k, v = line:match('^(%w+)=(.*)$')
        if k then got[k] = v:gsub('%s+$', '') end
    end
    if got.Route == nil then return end

    local active, route = got.Active or '', got.Route or ''
    if active ~= '' then
        -- protected: solid ink block, ground-coloured text
        set('MStatusBox', 'Shape', 'Rectangle 18,50,404,48 | Fill Color ' .. INK .. ' | StrokeWidth 0')
        set('MStatusCap', 'FontColor', BG); set('MStatusVal', 'FontColor', BG)
        set('MStatusCap', 'Text', 'PROTECTED - your traffic goes through')
        set('MStatusVal', 'Text', string.upper(active))
    else
        set('MStatusBox', 'Shape', 'Rectangle 19,51,402,46 | Fill Color ' .. BG .. ' | StrokeWidth 2 | Stroke Color ' .. WARN)
        set('MStatusCap', 'FontColor', WARN); set('MStatusVal', 'FontColor', WARN)
        set('MStatusCap', 'Text', 'NOT PROTECTED - no VPN carries your traffic')
        set('MStatusVal', 'Text', route ~= '' and ('DIRECT OVER ' .. string.upper(route)) or 'NO NETWORK')
    end

    for _, r in ipairs(ROWS) do
        local v = got[r.key] or ''
        local state, ip = v:match('^([^|]*)|?(.*)$')
        if r.key == 'Other' then
            -- Other is "name|ip" and only shows when some other tunnel is up
            local name = state or ''
            set(r.meter .. 'Name', 'Text', name ~= '' and name or 'Other tunnel')
            state = name ~= '' and 'CONNECTED' or 'NONE'
        end
        local txt = STATE_TEXT[state] or (state == 'NONE' and 'none up' or (state or ''))
        local col = (state == 'CONNECTED') and INK or ((state == 'CONNECTING') and WARN or MID)
        set(r.meter .. 'State', 'Text', txt)
        set(r.meter .. 'State', 'FontColor', col)
        set(r.meter .. 'Name', 'FontColor', state == 'CONNECTED' and INK or MID)
        set(r.meter .. 'Ip', 'Text', (ip and ip ~= '') and ip or '-')
    end
    lastOk = os.time()
    SKIN:Bang('!UpdateMeter', '*'); SKIN:Bang('!Redraw')
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then tick = 0; SKIN:Bang('!CommandMeasure', 'mRun', 'Run') end
    if lastOk then
        set('MFoot', 'Text', string.format('checked %ds ago  -  every %ds', os.time() - lastOk, PERIOD))
        SKIN:Bang('!UpdateMeter', 'MFoot')
    end
    return 0
end
