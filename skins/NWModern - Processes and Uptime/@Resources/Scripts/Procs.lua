-- Reads Data/procs.txt (written by Collect.ps1) and paints four top-20 lists
-- side by side: CPU, memory, GPU and GPU memory.
-- Also writes Data/beat.txt each update so the collector knows the skin is alive.
local ROWS, BARW, TILEW = 20, 226, 206
local KEYS = { 'cpu', 'ram', 'gpu', 'gmem' }
local PREFIX = { cpu = 'Cpu', ram = 'Ram', gpu = 'Gpu', gmem = 'Gmem' }
local TEXT, TEXT2 = '234,238,246', '168,176,194'
local DATA, BEAT
local lastStamp, MONO
local rows, meta = {}, {}

function Initialize()
    local res = SKIN:ReplaceVariables('#@#')
    DATA = res .. 'Data/procs.txt'
    BEAT = res .. 'Data/beat.txt'
    BARW  = tonumber(SKIN:GetVariable('BarW'))  or BARW
    TILEW = tonumber(SKIN:GetVariable('TileW')) or TILEW
    MONO = SKIN:GetVariable('Mono') == '1'   -- house-style skin: no heat colours
end

local function set(m, k, v) SKIN:Bang('!SetOption', m, k, v) end

local function mem(mb)
    if mb >= 1024 then return string.format('%.1f GB', mb / 1024) end
    if mb >= 0.5 then return string.format('%.0f MB', mb) end
    return '-'
end
local function pct(v) return string.format('%.1f%%', v) end

local function heat(v)
    if v >= 60 then return '255,104,104' elseif v >= 25 then return '255,198,92'
    elseif v >= 3 then return '112,224,160' end
    return TEXT2
end

-- smallest value worth listing; below this a row is noise
local MIN = { cpu = 0.05, ram = 0.5, gpu = 0.05, gmem = 0.5 }

local function parse()
    local f = io.open(DATA, 'r')
    if not f then return false end
    local t = f:read('*a'); f:close()
    local r, m = {}, {}
    for line in t:gmatch('[^\r\n]+') do
        local k, v = line:match('^([%w_]+)=(.*)$')
        if k and k:match('^R%d+$') then
            local n, c, ram, g, gm = v:match('^([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|')
            if n then
                r[#r + 1] = { name = n, cpu = tonumber(c) or 0, ram = tonumber(ram) or 0,
                              gpu = tonumber(g) or 0, gmem = tonumber(gm) or 0 }
            end
        elseif k then m[k] = v end
    end
    rows, meta = r, m
    return true
end

local function tile(p, value, sub, frac)
    set('T' .. p .. 'Val', 'Text', value)
    set('T' .. p .. 'Sub', 'Text', sub)
    set('T' .. p .. 'Bar', 'W', math.max(1, math.floor(TILEW * math.min(1, math.max(0, frac)))))
end

local function column(key)
    local list = {}
    for _, r in ipairs(rows) do
        if r[key] >= MIN[key] then list[#list + 1] = r end
    end
    table.sort(list, function(a, b) return a[key] > b[key] end)

    local P = PREFIX[key]
    local top = list[1] and list[1][key] or 0
    local isPct = (key == 'cpu' or key == 'gpu')
    for i = 1, ROWS do
        local m, r = P .. i, list[i]
        if r then
            set(m .. 'Name', 'Text', r.name)
            set(m .. 'Val', 'Text', isPct and pct(r[key]) or mem(r[key]))
            if isPct and not MONO then set(m .. 'Val', 'FontColor', heat(r[key])) end
            set(m .. 'Bar', 'W', math.max(1, math.floor(BARW * r[key] / top)))
            SKIN:Bang('!ShowMeter', m .. 'Bar')
        else
            set(m .. 'Name', 'Text', i == 1 and 'idle' or '')
            set(m .. 'Val', 'Text', '')
            SKIN:Bang('!HideMeter', m .. 'Bar')
        end
    end
end

local function render()
    local n = tonumber
    local cpuT = n(meta.CpuTotal) or 0
    local ramU, ramT = n(meta.RamUsedMB) or 0, n(meta.RamTotalMB) or 1
    local gpuT = n(meta.GpuTotal) or 0
    local vU, vT = n(meta.VramUsedMB) or 0, n(meta.VramTotalMB) or 0

    tile('Cpu', string.format('%.0f%%', cpuT), (meta.Cores or '?') .. ' logical cores', cpuT / 100)
    tile('Ram', string.format('%.0f%%', ramU / ramT * 100),
         string.format('%.1f / %.1f GB in use', ramU / 1024, ramT / 1024), ramU / ramT)
    tile('Gpu', string.format('%.0f%%', gpuT), meta.GpuName or 'GPU', gpuT / 100)
    tile('Gmem', vT > 0 and string.format('%.0f%%', vU / vT * 100) or '-',
         string.format('VRAM %.1f / %.1f GB dedicated', vU / 1024, vT / 1024), vT > 0 and vU / vT or 0)

    for _, k in ipairs(KEYS) do column(k) end
end

function Update()
    local b = io.open(BEAT, 'w')
    if b then b:write(tostring(os.time())); b:close() end

    if not parse() then
        set('MFootL', 'Text', 'Starting collector...')
        SKIN:Bang('!UpdateMeter', 'MFootL'); SKIN:Bang('!Redraw')
        return 0
    end

    local stamp = tonumber(meta.Stamp) or 0
    if stamp ~= lastStamp then
        render()
        lastStamp = stamp
    end
    set('MFootL', 'Text', string.format('%s processes  -  updated %ds ago',
        meta.ProcCount or '?', math.max(0, os.time() - stamp)))
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
    return #rows
end
