-- Fills the day/hour/minute/second tiles and the boot timestamp from the
-- Uptime measure's value (seconds since boot).
function Initialize()
    mUp = SKIN:GetMeasure('mUp')
    SKIN:Bang('!SetOption', 'MHost', 'Text', os.getenv('COMPUTERNAME') or 'THIS PC')
end

function Update()
    local s = math.floor(mUp:GetValue() or 0)
    -- Screenshot mode (skin variable Demo=1): placeholder computer name
    SKIN:Bang('!SetOption', 'MHost', 'Text', SKIN:GetVariable('Demo') == '1' and 'WORKSTATION' or (os.getenv('COMPUTERNAME') or 'THIS PC'))
    SKIN:Bang('!SetOption', 'MDays',  'Text', tostring(math.floor(s / 86400)))
    SKIN:Bang('!SetOption', 'MHours', 'Text', string.format('%02d', math.floor(s % 86400 / 3600)))
    SKIN:Bang('!SetOption', 'MMins',  'Text', string.format('%02d', math.floor(s % 3600 / 60)))
    SKIN:Bang('!SetOption', 'MSecs',  'Text', string.format('%02d', s % 60))
    SKIN:Bang('!SetOption', 'MDayPct', 'Text', string.format('%d%%', math.floor(s % 86400 / 864)))
    if s > 0 then
        SKIN:Bang('!SetOption', 'MBootValue', 'Text', os.date('%a %d %b %Y  %H:%M', os.time() - s))
    end
    return s
end
