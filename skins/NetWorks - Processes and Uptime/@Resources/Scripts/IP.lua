-- Net // Works IP card. Runs IP.ps1 through the RunCommand measure every
-- PERIOD seconds, paints the four addresses, and copies them on click.
local PERIOD = 15          -- seconds between lookups
local FRESH = 60           -- a changed address stays highlighted this long
local COPIED_FOR = 2       -- seconds the COPY badge reads COPIED

local FIELDS = { PublicV4 = 'PubV4', PublicV6 = 'PubV6', LocalV4 = 'LocV4', LocalV6 = 'LocV6' }
local ORDER = { 'PubV4', 'PubV6', 'LocV4', 'LocV6' }
local LABEL = { PubV4 = 'Public IPv4', PubV6 = 'Public IPv6', LocV4 = 'Local IPv4', LocV6 = 'Local IPv6' }

local run, INK, MID, WARN
local vals, changedAt, copiedAt = {}, {}, {}
local v6State, iface = '', ''
local tick, lastOk = 0, nil

local function set(m, k, v) SKIN:Bang('!SetOption', m, k, v) end

function Initialize()
    run = SKIN:GetMeasure('mRun')
    INK, MID, WARN = SKIN:GetVariable('cFg'), SKIN:GetVariable('cMid'), SKIN:GetVariable('cWarn')
    -- first lookup is started by the skin's OnRefreshAction
end

local function paint()
    local now = os.time()
    for _, f in ipairs(ORDER) do
        local v = vals[f]
        if v and v ~= '' then
            set(f .. 'Val', 'Text', v)
            set(f .. 'Val', 'FontColor', (changedAt[f] and now - changedAt[f] < FRESH) and WARN or INK)
            set(f .. 'Copy', 'Text', (copiedAt[f] and now - copiedAt[f] < COPIED_FOR) and 'COPIED' or 'COPY')
            SKIN:Bang('!ShowMeter', f .. 'Copy')
        else
            local why = 'looking up...'
            if lastOk then
                why = (f == 'PubV6' or f == 'LocV6') and (v6State ~= '' and v6State or 'not available') or 'not available'
            end
            set(f .. 'Val', 'Text', why)
            set(f .. 'Val', 'FontColor', MID)
            SKIN:Bang('!HideMeter', f .. 'Copy')
        end
    end
    set('MAll', 'Text', (copiedAt.all and now - copiedAt.all < COPIED_FOR) and 'COPIED' or 'COPY ALL')
    set('MLocalHead', 'Text', iface ~= '' and ('LOCAL - ' .. string.upper(iface)) or 'LOCAL')
    if lastOk then
        set('MFoot', 'Text', string.format('updated %ds ago  -  every %ds', now - lastOk, PERIOD))
    end
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

-- FinishAction of mRun
function Parse()
    local out = run:GetStringValue() or ''
    local got = {}
    for line in out:gmatch('[^\r\n]+') do
        local k, v = line:match('^(%w+)=(.*)$')
        if k then got[k] = v:gsub('%s+$', '') end
    end
    if got.Iface == nil then return end           -- script failed; keep last values
    for key, f in pairs(FIELDS) do
        local new = got[key] or ''
        if vals[f] and vals[f] ~= '' and new ~= '' and new ~= vals[f] then changedAt[f] = os.time() end
        vals[f] = new
    end
    v6State, iface = got.V6State or '', got.Iface or ''
    lastOk = os.time()
    paint()
end

function Copy(f)
    local v = vals[f]
    if not v or v == '' then return end
    SKIN:Bang('!SetClip', v)
    copiedAt[f] = os.time()
    paint()
end

function CopyAll()
    local lines = {}
    for _, f in ipairs(ORDER) do
        local v = vals[f]
        lines[#lines + 1] = LABEL[f] .. ': ' .. ((v and v ~= '') and v or 'not available')
    end
    SKIN:Bang('!SetClip', table.concat(lines, '\r\n'))
    copiedAt.all = os.time()
    paint()
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then
        tick = 0
        SKIN:Bang('!CommandMeasure', 'mRun', 'Run')
    end
    paint()
    return 0
end
