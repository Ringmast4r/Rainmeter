function Initialize()
    folders = {
        { key = 'DomRep',  color = '0,120,255,255',   path = 'C:\\Users\\Squir\\Desktop\\Dominican Republic' },
        { key = 'Cuba',    color = '255,80,80,255',    path = 'C:\\Users\\Squir\\Desktop\\CUBA' },
    }

    displayNames = {
        DomRep = 'Dominican Republic',
        Cuba = 'Cuba',
    }
end

function Update()
    -- Read current values
    for _, f in ipairs(folders) do
        f.size    = SKIN:GetMeasure('Measure' .. f.key .. 'Size'):GetValue()
        f.files   = SKIN:GetMeasure('Measure' .. f.key .. 'Files'):GetValue()
        f.folders = SKIN:GetMeasure('Measure' .. f.key .. 'Folders'):GetValue()
    end

    -- Sort descending by size
    local sorted = {}
    for i, f in ipairs(folders) do
        sorted[i] = f
    end
    table.sort(sorted, function(a, b) return a.size > b.size end)

    -- Push sorted data into slot meters
    for i, f in ipairs(sorted) do
        local name = displayNames[f.key]
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',    'Text',          name)
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',    'FontColor',     f.color)
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',    'LeftMouseUpAction', '["' .. f.path .. '"]')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Size',    'MeasureName',   'Measure' .. f.key .. 'Size')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Files',   'MeasureName',   'Measure' .. f.key .. 'Files')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Folders', 'MeasureName',   'Measure' .. f.key .. 'Folders')
    end
end
