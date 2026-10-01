-- Net // Works speed card: live download / upload from the NetIn / NetOut
-- measures (bytes per second on the best-route adapter), plus peaks and
-- data used since the skin loaded.
local mDown, mUp
local peakDown, peakUp, totalDown, totalUp = 0, 0, 0, 0
local started

local function set(m, k, v) SKIN:Bang('!SetOption', m, k, v) end

local function rate(bytes)
    local bits = bytes * 8
    if bits >= 1e6 then return string.format('%.1f Mbps', bits / 1e6) end
    return string.format('%.0f kbps', bits / 1e3)
end

local function size(bytes)
    if bytes >= 1073741824 then return string.format('%.2f GB', bytes / 1073741824) end
    if bytes >= 1048576 then return string.format('%.1f MB', bytes / 1048576) end
    return string.format('%.0f KB', bytes / 1024)
end

local function since(sec)
    if sec >= 3600 then return string.format('%dh %02dm', math.floor(sec / 3600), math.floor(sec % 3600 / 60)) end
    return string.format('%dm %02ds', math.floor(sec / 60), sec % 60)
end

function Initialize()
    mDown, mUp = SKIN:GetMeasure('mDown'), SKIN:GetMeasure('mUp')
    started = os.time()
end

function Update()
    local d, u = mDown:GetValue() or 0, mUp:GetValue() or 0
    if d > peakDown then peakDown = d end
    if u > peakUp then peakUp = u end
    totalDown, totalUp = totalDown + d, totalUp + u   -- skin updates once a second

    set('DownVal', 'Text', rate(d))
    set('UpVal', 'Text', rate(u))
    set('DownSub', 'Text', 'peak ' .. rate(peakDown) .. '  /  ' .. size(totalDown))
    set('UpSub', 'Text', 'peak ' .. rate(peakUp) .. '  /  ' .. size(totalUp))
    set('MFoot', 'Text', 'totals since load ' .. since(os.time() - started))
    return d
end
