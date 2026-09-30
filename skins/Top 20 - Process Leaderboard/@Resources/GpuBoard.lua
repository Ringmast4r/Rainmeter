-- GpuBoard.lua - the GPU column, counted the way Task Manager counts it.
--
-- UsageMonitor with Rollup=0 returns one row per (process, engine), e.g.
--   pid_20416_luid_0x00000000_0x00014553_phys_0_eng_7_engtype_VideoEncode
-- A process's GPU % is its busiest engine (not the sum of its engines), and
-- the GPU total is the busiest engine summed over every process using it.
-- PIDToName only works with rollup on, so PIDs are named from a tasklist
-- that runs once at load and again only when an unknown PID appears.

local raw, rawCount, rows
local names = {}          -- pid -> process name
local pending = false     -- tasklist in flight
local lastLookup = -1e9
local shown = {}          -- per-row cache so unchanged rows send no bangs
local dot                 -- the separator dot, read from the skin so encoding round-trips

local ENGINE = {
    ['3D'] = '3D', VideoEncode = 'encode', VideoDecode = 'decode',
    VideoProcessing = 'video', Copy = 'copy', Compute = 'compute',
    LegacyOverlay = 'overlay', Security = 'security', ['GDI Render'] = 'GDI',
}

local function engineLabel(t)
    t = t:gsub('_%d+$', '')
    return ENGINE[t] or t:lower()
end

local function lookup()
    if pending then return end
    pending = true
    lastLookup = os.time()
    SKIN:Bang('!CommandMeasure', 'MeasureTaskList', 'Run')
end

function Initialize()
    dot = SKIN:GetVariable('Dot', '-')
    rawCount = tonumber(SELF:GetOption('RawCount', '60'))
    rows = tonumber(SELF:GetOption('Rows', '20'))
    raw = {}
    for i = 1, rawCount do raw[i] = SKIN:GetMeasure('MeasureGpuRaw' .. i) end
    lookup()
end

function OnTaskList()
    pending = false
    local out = SKIN:GetMeasure('MeasureTaskList'):GetStringValue()
    local fresh = {}
    for line in out:gmatch('[^\r\n]+') do
        local image, pid = line:match('^"([^"]+)","(%d+)"')
        if pid then fresh[pid] = (image:gsub('%.exe$', '')) end
    end
    if next(fresh) then names = fresh end
end

local function set(r, field, meter, option, value)
    local key = r .. field
    if shown[key] ~= value then
        shown[key] = value
        SKIN:Bang('!SetOption', meter, option, value)
    end
end

function Update()
    local engineSum, engineType = {}, {}
    local procs, list = {}, {}
    local missing = false

    for i = 1, rawCount do
        local s = raw[i]:GetStringValue()
        if s == '' then break end
        local pid, key, etype = s:match('^pid_(%d+)_(luid_.-_eng_%d+)_engtype_(.+)$')
        if pid then
            local v = raw[i]:GetValue()
            engineSum[key] = (engineSum[key] or 0) + v
            engineType[key] = etype
            local name = names[pid]
            if not name then
                missing = true
                name = 'pid ' .. pid
            end
            local p = procs[name]
            if not p then
                p = { name = name, eng = {} }
                procs[name] = p
                list[#list + 1] = p
            end
            p.eng[key] = (p.eng[key] or 0) + v
        end
    end

    if missing and os.time() - lastLookup > 10 then lookup() end

    for _, p in ipairs(list) do
        p.value, p.type = 0, nil
        for key, v in pairs(p.eng) do
            if v > p.value or not p.type then p.value, p.type = v, engineType[key] end
        end
    end
    table.sort(list, function(a, b) return a.value > b.value end)

    local total, totalType = 0, nil
    for key, v in pairs(engineSum) do
        if v > total then total, totalType = v, engineType[key] end
    end
    total = math.min(total, 100)
    SKIN:Bang('!SetVariable', 'GpuTotal', string.format('%.2f', total))
    local sub = SKIN:GetVariable('GpuName')
    if totalType and total >= 0.05 then sub = sub .. ' ' .. dot .. ' ' .. engineLabel(totalType) end
    set(0, 'sub', 'MeterGPUSub', 'Text', sub)

    local top = (list[1] and list[1].value > 0) and list[1].value or 1
    for r = 1, rows do
        local p = list[r]
        local nameMeter, valueMeter = 'MeterGPUName' .. r, 'MeterGPUValue' .. r
        if p then
            local idle = p.value < 0.05
            local color = idle and SKIN:GetVariable('Faint') or SKIN:GetVariable('Text')
            local label = p.name
            if not idle and p.type then label = label .. ' ' .. dot .. ' ' .. engineLabel(p.type) end
            set(r, 'n', nameMeter, 'Text', label)
            set(r, 'v', valueMeter, 'Text', string.format('%.1f%%', p.value))
            set(r, 'nc', nameMeter, 'FontColor', color)
            set(r, 'vc', valueMeter, 'FontColor', idle and color or SKIN:GetVariable('TextDim'))
            SKIN:Bang('!SetVariable', 'GpuBar' .. r, string.format('%.4f', p.value / top))
        else
            set(r, 'n', nameMeter, 'Text', '')
            set(r, 'v', valueMeter, 'Text', '')
            SKIN:Bang('!SetVariable', 'GpuBar' .. r, '0')
        end
    end
    return total
end
