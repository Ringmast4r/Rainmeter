function Initialize()
    folders = {
        { key = 'AlbanianAI',  color = '225,0,0,255',     path = 'C:\\Users\\Squir\\Desktop\\Albanian AI',          name = 'Albanian AI' },
        { key = 'Colombia',    color = '255,205,0,255',    path = 'C:\\Users\\Squir\\Desktop\\COLOMBIA',             name = 'Colombia' },
        { key = 'DomRep',      color = '0,56,168,255',     path = 'C:\\Users\\Squir\\Desktop\\Dominican Republic',   name = 'Dominican Republic' },
        { key = 'Iran',        color = '35,159,64,255',    path = 'C:\\Users\\Squir\\Desktop\\IRAN',                 name = 'Iran' },
        { key = 'Iraq',        color = '200,16,46,255',    path = 'C:\\Users\\Squir\\Desktop\\Iraq',                 name = 'Iraq' },
        { key = 'Mexico',      color = '0,104,71,255',     path = 'C:\\Users\\Squir\\Desktop\\MEXICO',               name = 'Mexico' },
        { key = 'Pakistan',    color = '1,100,55,255',     path = 'C:\\Users\\Squir\\Desktop\\Pakistan',             name = 'Pakistan' },
        { key = 'Cuba',        color = '0,82,165,255',     path = 'C:\\Users\\Squir\\Desktop\\CUBA',                 name = 'Cuba' },
        { key = 'VenezuelaV2', color = '255,223,0,255',  path = 'C:\\Users\\Squir\\Desktop\\VENEZUELA V2',        name = 'Venezuela V2' },
    }
end

function Update()
    for _, f in ipairs(folders) do
        f.size    = SKIN:GetMeasure('Measure' .. f.key .. 'Size'):GetValue()
        f.files   = SKIN:GetMeasure('Measure' .. f.key .. 'Files'):GetValue()
        f.folders = SKIN:GetMeasure('Measure' .. f.key .. 'Folders'):GetValue()
    end

    local sorted = {}
    for i, f in ipairs(folders) do
        sorted[i] = f
    end
    table.sort(sorted, function(a, b) return a.size > b.size end)

    for i, f in ipairs(sorted) do
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',    'Text',              f.name)
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',    'FontColor',         f.color)
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',    'LeftMouseUpAction', '["' .. f.path .. '"]')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Size',    'MeasureName',       'Measure' .. f.key .. 'Size')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Files',   'MeasureName',       'Measure' .. f.key .. 'Files')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Folders', 'MeasureName',       'Measure' .. f.key .. 'Folders')
    end
end
