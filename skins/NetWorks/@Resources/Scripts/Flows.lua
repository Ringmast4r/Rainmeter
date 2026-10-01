-- Net // Works Egress / ingress card. Runs Flows.ps1 every PERIOD seconds: every connection this PC holds, split by
-- who opened it (OUT = this PC called out, IN = something connected in), and the ports it listens on.
-- Worst first: threat-listed, inbound from the internet (red), inbound from the LAN (yellow), outbound by connection
-- count, then listeners. Click a stat box to show only that kind; the mouse wheel scrolls STEP rows.
-- The header line is live traffic on the best-route adapter (mIn / mOut).
local PERIOD, ROWS, STEP = 15, 16, 3
local SERVICE = { [21] = 'FTP', [22] = 'SSH', [23] = 'Telnet', [53] = 'DNS', [80] = 'HTTP', [135] = 'Windows RPC',
                  [137] = 'NetBIOS', [138] = 'NetBIOS', [139] = 'NetBIOS', [443] = 'HTTPS', [445] = 'SMB file sharing',
                  [500] = 'IPsec', [1900] = 'SSDP discovery', [3389] = 'Remote Desktop', [3702] = 'WS-Discovery',
                  [4500] = 'IPsec', [5353] = 'mDNS', [5355] = 'LLMNR', [5357] = 'WS-Discovery', [5432] = 'PostgreSQL',
                  [5800] = 'VNC web viewer', [5900] = 'VNC', [7680] = 'Delivery Optimization' }
-- remote-control and cleartext services: yellow when they listen beyond this PC
local RISKY = { [21] = true, [23] = true, [3389] = true, [5800] = true, [5900] = true }
local VIEW = { out = 'outbound', ['in'] = 'inbound', listen = 'listeners', flag = 'threat-listed' }
local C, K, run, mIn, mOut, bar, stats
local tick, lastOk = 0, nil
local all, shown, top, view = {}, {}, 0, 'all'

function Initialize()
    C = dofile(SKIN:ReplaceVariables('#@#') .. 'Scripts\\Common.lua')
    K = C.colors()
    K.ON = SKIN:GetVariable('cHiLab')
    run, mIn, mOut = SKIN:GetMeasure('mRun'), SKIN:GetMeasure('mIn'), SKIN:GetMeasure('mOut')
    -- the generator's scrollbar(): the track rectangle is the room the thumb moves in
    local x, y, w, h = SKIN:GetMeter('RScroll'):GetOption('Shape'):match('^Rectangle (%d+),(%d+),(%d+),(%d+)')
    bar = { x = x, y = tonumber(y), w = w, h = tonumber(h) }
end

local function join(a, b, sep)
    if a == '' then return b elseif b == '' then return a end
    return a .. sep .. b
end

local function plural(n, word) return n .. ' ' .. word .. (n == 1 and '' or 's') end

local function rate(bytes)
    local bits = (bytes or 0) * 8
    if bits >= 1e6 then return string.format('%.1f Mbps', bits / 1e6) end
    return string.format('%.0f kbps', bits / 1e3)
end

local function demoIp(ip, pub, i)
    if ip:find(':', 1, true) then return '2001:db8::' .. string.format('%x', i) end
    return (pub and '203.0.113.' or '192.168.1.') .. (10 + i % 240)
end

local function service(port)
    local s = SERVICE[tonumber(port) or 0]
    return s and (' (' .. s .. ')') or ''
end

-- the rows the current view shows; "all" leaves out listeners only this PC can reach
local function pick()
    shown = {}
    for _, r in ipairs(all) do
        if (view == 'all' and r.rank < 6) or r.kind == view or (view == 'flag' and r.flag) then shown[#shown + 1] = r end
    end
end

local function boxes()
    if not stats then return end
    local s = stats
    local function on(v) return view == v and K.ON or nil end
    C.box(K, 'Out', tostring(s.out), 'to ' .. plural(s.outHosts, 'host'), nil, nil, on('out'))
    local inCol = s.inn > 0 and (s.inPub and K.CRIT or K.WARN) or nil
    C.box(K, 'In', tostring(s.inn), s.inn > 0 and ('from ' .. plural(s.inHosts, 'host')) or 'nothing connected in',
        inCol, inCol, on('in'))
    C.box(K, 'Lis', tostring(s.open), s.risky > 0 and (s.risky .. ' remote control') or ('+' .. s.localOnly .. ' this PC only'),
        s.risky > 0 and K.WARN or nil, s.risky > 0 and K.WARN or nil, on('listen'))
    C.box(K, 'Flag', tostring(s.flagged), s.flagged > 0 and 'on a threat list' or 'none on threat lists',
        s.flagged > 0 and K.CRIT or nil, s.flagged > 0 and K.CRIT or nil, on('flag'))
end

-- rows top+1 .. top+ROWS of the current view, the thumb and the footer note
local function draw()
    top = math.max(0, math.min(top, #shown - ROWS))
    for i = 1, ROWS do
        local s, r = shown[top + i], 'R' .. i
        if s then
            C.cell(r, 'Dir', s.dir, s.col)
            C.cell(r, 'Proc', C.dash(s.proc), s.col)
            C.cell(r, 'Peer', s.peer, s.col)
            C.cell(r, 'Who', C.dash(s.who), s.flag and K.CRIT or K.MID)
            C.cell(r, 'Port', s.port, K.MID)
            C.cell(r, 'N', s.n, K.INK)
            C.set(r .. 'Peer', 'ToolTipText', s.tip)
        else
            for _, k in ipairs({ 'Dir', 'Proc', 'Peer', 'Who', 'Port', 'N' }) do C.cell(r, k, '') end
            C.set(r .. 'Peer', 'ToolTipText', '')
        end
    end
    local range = plural(#shown, 'row')
    if #shown > ROWS then
        local len = math.max(12, math.floor(bar.h * ROWS / #shown))
        local pos = bar.y + math.floor((bar.h - len) * top / (#shown - ROWS) + 0.5)
        C.set('RScroll', 'Shape2', string.format('Rectangle %s,%d,%s,%d | Fill Color %s | StrokeWidth 0', bar.x, pos, bar.w, len, K.INK))
        SKIN:Bang('!ShowMeter', 'RScroll')
        range = string.format('%d-%d of %d  -  scroll', top + 1, top + ROWS, #shown)
    else
        SKIN:Bang('!HideMeter', 'RScroll')
    end
    C.set('MScroll', 'Text', join(view ~= 'all' and (VIEW[view] .. ' only') or '', range, '  -  '))
end

function Parse()
    local kv, lists = C.parse(run:GetStringValue())
    if not kv.Ok then return end

    all = {}
    local s = { out = 0, inn = 0, inPub = false, open = 0, localOnly = 0, risky = 0 }
    local outHosts, inHosts, flagged = {}, {}, {}
    for i, line in ipairs(lists.F or {}) do
        local f = C.split(line)
        local dir, proc, ip, pub, who, cc, city = f[1], f[2], f[3], f[4] == 'pub', f[5] or '', f[6] or '', f[7] or ''
        local port, n, flag, rports = f[8] or '', tonumber(f[9]) or 1, f[10] or '', f[11] or ''
        local r = { idx = i, proc = proc, count = n, n = tostring(n), port = port, flag = flag ~= '' }
        local where = join(join(who, city, ', '), cc, ' ')
        local named = ip .. (where ~= '' and (' (' .. where .. ')') or '')
        if dir == 'I' then
            r.kind, r.dir, r.rank, r.col = 'in', 'IN', pub and 1 or 2, pub and K.CRIT or K.WARN
            r.tip = string.format('%s connected in to %s on port %s%s', named, C.dash(proc), port, service(port))
            s.inn = s.inn + n; inHosts[ip] = true
            if pub then s.inPub = true end
        else
            r.kind, r.dir, r.rank, r.col = 'out', 'OUT', 3, K.INK
            r.tip = string.format('%s called out to %s, port%s %s', C.dash(proc), named, rports:find(',', 1, true) and 's' or '', rports)
            s.out = s.out + n; outHosts[ip] = true
        end
        if r.flag then
            r.rank, r.col = 0, K.CRIT
            r.tip = r.tip .. '  -  threat listed: ' .. flag
            flagged[ip] = true
        end
        if pub then r.who = join(who, cc, '  ') else r.who = who ~= '' and who or 'local network' end
        r.peer = ip
        if C.demo() then
            r.peer, r.tip = demoIp(ip, pub, i), ''
            if not pub and who ~= '' then r.who = string.format('device-%02d', i) end
        end
        all[#all + 1] = r
    end
    for i, line in ipairs(lists.L or {}) do
        local f = C.split(line)
        local proto, proc, port, scope = f[1], f[2], tonumber(f[3]) or 0, f[4] or ''
        local r = { idx = 1000 + i, kind = 'listen', dir = 'LISTEN', proc = proc, count = 0, n = '', flag = false, portNum = port,
                    port = (proto == 'udp' and 'udp ' or '') .. port, who = SERVICE[port] or '' }
        if scope == 'local' then
            r.peer, r.rank, r.col = 'this PC only', 6, K.MID
            r.tip = string.format('%s listens on %s port %d%s, loopback only', C.dash(proc), proto, port, service(port))
            s.localOnly = s.localOnly + 1
        else
            r.peer = scope == 'all' and 'all interfaces' or (C.demo() and '192.168.1.10' or scope)
            r.rank, r.col = RISKY[port] and 4 or 5, RISKY[port] and K.WARN or K.INK
            r.tip = string.format('%s listens on %s port %d%s on %s; the firewall decides who can reach it', C.dash(proc), proto, port,
                service(port), scope == 'all' and 'every interface' or r.peer)
            s.open = s.open + 1
            if RISKY[port] then s.risky = s.risky + 1 end
        end
        all[#all + 1] = r
    end
    table.sort(all, function(a, b)
        if a.rank ~= b.rank then return a.rank < b.rank end
        if a.count ~= b.count then return a.count > b.count end
        if a.kind == 'listen' and a.portNum ~= b.portNum then return a.portNum < b.portNum end
        return a.idx < b.idx
    end)

    local function count(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
    s.outHosts, s.inHosts, s.flagged = count(outHosts), count(inHosts), count(flagged)
    stats = s
    pick(); boxes(); draw()
    lastOk = os.time()
    C.redraw()
end

-- click a stat box: only that kind; click it again: everything
function View(v)
    view = (view == v) and 'all' or v
    top = 0
    pick(); boxes(); draw()
    C.redraw()
end

-- mouse wheel: n = -1 up, 1 down
function Scroll(n)
    local to = math.max(0, math.min(top + n * STEP, #shown - ROWS))
    if to == top then return end
    top = to
    draw()
    C.redraw()
end

function Update()
    tick = tick + 1
    if tick >= PERIOD then tick = 0; SKIN:Bang('!CommandMeasure', 'mRun', 'Run') end
    C.set('MHint', 'Text', '// out ' .. rate(mOut:GetValue()) .. '  /  in ' .. rate(mIn:GetValue()))
    SKIN:Bang('!UpdateMeter', 'MHint')
    C.foot(lastOk, PERIOD, 'checked')
    return 0
end
