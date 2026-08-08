function Initialize()
    folders = {
        { key = 'crystalvault', color = '66,133,244,255', path = 'E:\\crystal-vault', name = 'crystal-vault' },
        { key = 'VENEZUELAV2', color = '234,67,53,255', path = 'E:\\VENEZUELA V2', name = 'VENEZUELA V2' },
        { key = 'MEXICO', color = '251,188,5,255', path = 'E:\\MEXICO', name = 'MEXICO' },
        { key = 'COLOMBIA', color = '52,168,83,255', path = 'E:\\COLOMBIA', name = 'COLOMBIA' },
        { key = 'Ecuador', color = '255,112,67,255', path = 'E:\\Ecuador', name = 'Ecuador' },
        { key = 'RECONSUITEofTOOLS', color = '0,188,212,255', path = 'E:\\RECON SUITE of TOOLS', name = 'RECON SUITE of TOOLS' },
        { key = 'Rwanda', color = '171,71,188,255', path = 'E:\\Rwanda', name = 'Rwanda' },
        { key = 'BurkinaFaso', color = '255,167,38,255', path = 'E:\\Burkina Faso', name = 'Burkina Faso' },
        { key = 'ProxReconSuitePull', color = '38,166,154,255', path = 'E:\\Prox Recon Suite Pull', name = 'Prox Recon Suite Pull' },
        { key = 'LexisNexisDataLeak', color = '239,83,80,255', path = 'E:\\LexisNexis-Data_Leak', name = 'LexisNexis-Data_Leak' },
        { key = 'DominicanRepublic', color = '66,165,245,255', path = 'E:\\Dominican Republic', name = 'Dominican Republic' },
        { key = 'THEWORLDATLARGE', color = '156,204,101,255', path = 'E:\\THE WORLD AT LARGE', name = 'THE WORLD AT LARGE' },
        { key = 'OSINTCAMPAIGNS', color = '255,138,101,255', path = 'E:\\OSINT CAMPAIGNS', name = 'OSINT CAMPAIGNS' },
        { key = 'HAITI', color = '126,87,194,255', path = 'E:\\HAITI', name = 'HAITI' },
        { key = 'Passports', color = '41,182,246,255', path = 'E:\\Passports', name = 'Passports' },
        { key = 'ODINTGithub', color = '255,213,79,255', path = 'E:\\ODINT Github', name = 'ODINT Github' },
        { key = 'MXMigration', color = '77,208,225,255', path = 'E:\\MX Migration', name = 'MX Migration' },
        { key = 'exposedenvcounter', color = '229,115,115,255', path = 'E:\\exposed-env-counter', name = 'exposed-env-counter' },
        { key = 'AlbanianAI', color = '121,134,203,255', path = 'E:\\Albanian AI', name = 'Albanian AI' },
        { key = 'IRAN', color = '129,199,132,255', path = 'E:\\IRAN', name = 'IRAN' },
        { key = 'Rus', color = '66,133,244,255', path = 'E:\\Rus', name = 'Rus' },
        { key = 'IndonesiaRun', color = '234,67,53,255', path = 'E:\\Indonesia Run', name = 'Indonesia Run' },
        { key = 'CUBA', color = '251,188,5,255', path = 'E:\\CUBA', name = 'CUBA' },
        { key = 'Iraq', color = '52,168,83,255', path = 'E:\\Iraq', name = 'Iraq' },
        { key = 'NKHUNTR', color = '255,112,67,255', path = 'E:\\NK HUNTR', name = 'NK HUNTR' },
        { key = 'Pakistan', color = '0,188,212,255', path = 'E:\\Pakistan', name = 'Pakistan' },
        { key = 'RingODINTArticles', color = '171,71,188,255', path = 'E:\\RingODINT Articles', name = 'RingODINT Articles' },
        { key = 'NAZIS', color = '255,167,38,255', path = 'E:\\NAZIS', name = 'NAZIS' },
        { key = 'SularhenINVESTIGATIONS', color = '38,166,154,255', path = 'E:\\Sularhen INVESTIGATIONS', name = 'Sularhen INVESTIGATIONS' },
        { key = 'IRANV1', color = '239,83,80,255', path = 'E:\\IRAN V1', name = 'IRAN V1' },
        { key = 'HENRYDATADUMP', color = '66,165,245,255', path = 'E:\\HENRY DATA DUMP', name = 'HENRY DATA DUMP' },
        { key = 'VENEZUELANEMAILHASHES', color = '156,204,101,255', path = 'E:\\VENEZUELAN EMAIL HASHES', name = 'VENEZUELAN EMAIL HASHES' },
        { key = 'Fedele', color = '255,138,101,255', path = 'E:\\Fedele', name = 'Fedele' },
        { key = 'GOATEDREPORTS', color = '126,87,194,255', path = 'E:\\GOATED REPORTS', name = 'GOATED REPORTS' },
        { key = 'TheAdventuresofRingmast4r', color = '41,182,246,255', path = 'E:\\The Adventures of Ringmast4r', name = 'The Adventures of Ringmast4r' },
        { key = 'ReconSuiteGithub', color = '255,213,79,255', path = 'E:\\Recon Suite Github', name = 'Recon Suite Github' },
        { key = 'Menu', color = '77,208,225,255', path = 'E:\\Menu', name = 'Menu' },
        { key = 'ENVTROPHYSNAPSHOTS', color = '229,115,115,255', path = 'E:\\ENV TROPHY SNAPSHOTS', name = 'ENV TROPHY SNAPSHOTS' },
        { key = 'CALLFORPAPERS', color = '121,134,203,255', path = 'E:\\CALL FOR PAPERS', name = 'CALL FOR PAPERS' },
        { key = 'FROMDESKTOPPC12132025december', color = '129,199,132,255', path = 'E:\\FROM DESKTOP PC 12_13_2025 december', name = 'FROM DESKTOP PC 12_13_2025 december' },
        { key = 'VenezuelaLogin', color = '66,133,244,255', path = 'E:\\Venezuela Login', name = 'Venezuela Login' },
    }
    ticks = 0
end

function Update()
    ticks = ticks + 1

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
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',   'Text',              f.name)
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',   'FontColor',         f.color)
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',   'LeftMouseUpAction', '["' .. f.path .. '"]')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Size',   'MeasureName',       'Measure' .. f.key .. 'Size')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Detail', 'MeasureName',       'Measure' .. f.key .. 'Files')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Detail', 'MeasureName2',      'Measure' .. f.key .. 'Folders')
    end

    -- After 5 ticks (5 seconds), data should be ready. Pause the skin.
    if ticks >= 5 then
        SKIN:Bang('!SetOption', 'Rainmeter', 'Update', '-1')
    end
end