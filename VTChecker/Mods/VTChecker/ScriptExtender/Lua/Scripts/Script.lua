local Script = {
    -- Adapted with permission from rakor.
	-- "But it’s not accurate"
	-- "I don’t remember the problem. But some mods have default paths or something, and you can’t tell what mod that is"
	-- "Default path to VTs* I think it’s just game’s problem"
	-- "I haven’t tried finding a better way tho :monkaHmm:"
	-- IDK I guess I could figure this out later? For now I'm just using the code as given and making it work as an SE/MCM mod.
	-- wtf am i doing with my life man
	
    ExecutionContext = "client"
}

local function toLower(value)
    return tostring(value or ""):lower()
end

local function normalizeToken(value)
    return toLower(value):gsub("[^%w]", "")
end

local function tryGet(resource, propertyName)
    local ok, value = pcall(function()
        return resource and resource[propertyName]
    end)

    if ok then
        return value
    end

    return nil
end

local function getEnabledVirtualTextures(material)
    local results = {}
    local parameters = material and material.VirtualTextureParameters or nil
    if not parameters then
        return results
    end

    for _, parameter in pairs(parameters) do
        local vtUuid = parameter and parameter.ID or nil
        if parameter and parameter.Enabled and vtUuid and vtUuid ~= "" then
            results[#results + 1] = parameter
        end
    end

    return results
end

local function findModInfoFromSource(sourceFile, modDirectoryOrder, modDirectoryMap)
    local lowerSourceFile = toLower(sourceFile)
    if lowerSourceFile == "" then
        return nil
    end

    for _, modDirectory in ipairs(modDirectoryOrder) do
        if lowerSourceFile:find(modDirectory, 1, true) then
            return modDirectoryMap[modDirectory]
        end
    end

    return nil
end

local function findModInfosFromIdentifiers(identifierHints, modSearchInfos)
    local matches = {}
    local seenMatches = {}

    for _, hint in ipairs(identifierHints) do
        local normalizedHint = normalizeToken(hint)
        if normalizedHint ~= "" then
            for _, modInfo in ipairs(modSearchInfos) do
                local token = modInfo.DirectoryToken
                if token ~= ""
                    and #token >= 5
                    and normalizedHint:find(token, 1, true)
                    and not seenMatches[modInfo.ModUuid]
                then
                    seenMatches[modInfo.ModUuid] = true
                    matches[#matches + 1] = modInfo
                end
            end
        end
    end

    return matches
end

local function resolveModInfos(candidateSourceFiles, candidateIdentifierHints, modDirectoryOrder, modDirectoryMap, modSearchInfos)
    local matches = {}
    local seenMatches = {}

    for _, candidateSourceFile in ipairs(candidateSourceFiles) do
        local modInfo = findModInfoFromSource(candidateSourceFile, modDirectoryOrder, modDirectoryMap)
        if modInfo and not seenMatches[modInfo.ModUuid] then
            seenMatches[modInfo.ModUuid] = true
            matches[#matches + 1] = modInfo
        end
    end

    if #matches == 0 then
        for _, modInfo in ipairs(findModInfosFromIdentifiers(candidateIdentifierHints, modSearchInfos)) do
            if not seenMatches[modInfo.ModUuid] then
                seenMatches[modInfo.ModUuid] = true
                matches[#matches + 1] = modInfo
            end
        end
    end

    return matches
end

local function rememberMod(modInfo, modOrder, seenMods)
    if not modInfo or seenMods[modInfo.ModUuid] then
        return
    end

    seenMods[modInfo.ModUuid] = true
    modOrder[#modOrder + 1] = modInfo
end

local function printModSection(title, modOrder)
    if #modOrder == 0 then
        return
    end

    _P(title)
    for index, modInfo in ipairs(modOrder) do
        local header = string.format("%i %s", index, modInfo.ModName)
        _P(header)
        _P(string.rep("-", #header))
    end
end

function Script.Run(api)
    local materialCount = 0
    local vtCount = 0
    local seenBroadMods = {}
    local seenStrictMods = {}
    local seenMaterials = {}
    local seenVirtualTextures = {}
    local baseVirtualTextures = {}
    local modDirectoryMap = {}
    local modDirectoryOrder = {}
    local modSearchInfos = {}
    local broadModOrder = {}
    local strictModOrder = {}
    local visuals = Ext.Resource.GetAll("Visual") or {}
    local virtualTextures = Ext.Resource.GetAll("VirtualTexture") or {}

    for _, vtUuid in pairs(virtualTextures) do
        local virtualTexture = Ext.Resource.Get(vtUuid, "VirtualTexture")
        if virtualTexture and not virtualTexture.IsModded then
            baseVirtualTextures[vtUuid] = true
        end
    end

    for _, modUuid in pairs(Ext.Mod.GetLoadOrder() or {}) do
        local mod = Ext.Mod.GetMod(modUuid)
        local info = mod and mod.Info or nil
        local directory = info and info.Directory or nil
        local author = info and info.Author or ""

        if author ~= "" and directory and directory ~= "" then
            local lowerDirectory = toLower(directory)
            local modInfo = {
                ModUuid = modUuid,
                ModName = info.Name or directory,
                DirectoryToken = normalizeToken(directory)
            }
            modDirectoryMap[lowerDirectory] = modInfo
            modDirectoryOrder[#modDirectoryOrder + 1] = lowerDirectory
            modSearchInfos[#modSearchInfos + 1] = modInfo
        end
    end

    for _, visualUuid in pairs(visuals) do
        local visual = Ext.Resource.Get(visualUuid, "Visual")
        if visual and visual.IsModded then
            local sourceFile = toLower(visual.SourceFile)
            local objects = visual.Objects or {}

            for _, object in pairs(objects) do
                local materialId = object.MaterialID
                local material = Ext.Resource.Get(materialId, "Material")
                local enabledVirtualTextures = getEnabledVirtualTextures(material)
                local materialSourceFile = tostring(material and material.SourceFile or "")
                local materialSourceFileLower = toLower(materialSourceFile)

                if material
                    and material.IsModded
                    and #enabledVirtualTextures > 0
                    and not materialSourceFileLower:find("char_skin_body", 1, true)
                    -- and not materialSourceFileLower:find("char_skin_head", 1, true)
                    -- and not materialSourceFileLower:find("char_skin_head_dgb", 1, true)
                then
                    local countsTowardUniqueVirtualTextures = false
                    local candidateSourceFiles = {
                        sourceFile,
                        materialSourceFile
                    }
                    local candidateIdentifierHints = {
                        tryGet(object, "ObjectID"),
                        tryGet(material, "Name")
                    }

                    for _, virtualTexture in ipairs(enabledVirtualTextures) do
                        local vtUuid = virtualTexture.ID

                        local vtResource = Ext.Resource.Get(vtUuid, "VirtualTexture")
                        local vtSourceFile = tryGet(vtResource, "SourceFile")
                        local vtName = tryGet(vtResource, "Name")
                        if vtSourceFile and vtSourceFile ~= "" then
                            candidateSourceFiles[#candidateSourceFiles + 1] = vtSourceFile
                        end
                        if vtName and vtName ~= "" then
                            candidateIdentifierHints[#candidateIdentifierHints + 1] = vtName
                        end

                        if not baseVirtualTextures[vtUuid] then
                            countsTowardUniqueVirtualTextures = true

                            if not seenVirtualTextures[vtUuid] then
                                seenVirtualTextures[vtUuid] = true
                                vtCount = vtCount + 1
                            end
                        end
                    end

                    if countsTowardUniqueVirtualTextures and not seenMaterials[materialId] then
                        seenMaterials[materialId] = true
                        materialCount = materialCount + 1
                    end

                    local resolvedMods = resolveModInfos(
                        candidateSourceFiles,
                        candidateIdentifierHints,
                        modDirectoryOrder,
                        modDirectoryMap,
                        modSearchInfos
                    )

                    for _, modInfo in ipairs(resolvedMods) do
                        rememberMod(modInfo, broadModOrder, seenBroadMods)
                    end

                    if countsTowardUniqueVirtualTextures then
                        for _, modInfo in ipairs(resolvedMods) do
                            rememberMod(modInfo, strictModOrder, seenStrictMods)
                        end
                    end
                end
            end
        end
    end

    printModSection("MODS USING UNIQUE VTS:", strictModOrder)
    printModSection("MODS WITH VT MATERIALS:", broadModOrder)
    _P(string.format("MATERIALS WITH VIRTUAL TEXTURE (NOT UNIQUE): %i", materialCount))
    _P("Materials we dont care about -----------------^")
    _P(string.format("UNIQUE VIRTUAL TEXTURES (VERY UNIQUE): %i", vtCount))
    _P("VT we care about -----------------------^")
end

return Script
