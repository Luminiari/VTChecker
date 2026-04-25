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

local function normalizePath(path)
    return tostring(path or ""):gsub("\\", "/")
end

local function tryGetModName(modUuid, fallbackName)
    if not modUuid then
        return fallbackName or "Unknown"
    end

    local ok, mod = pcall(Ext.Mod.GetMod, modUuid)
    if ok and mod and mod.Info and mod.Info.Name and mod.Info.Name ~= "" then
        return mod.Info.Name
    end

    return fallbackName or "Unknown"
end

function Script.Run(api)
    local all = Ext.Resource.GetAll("Material")
    local seen = {}
    local vtsCount = 0

    for _, uuid in pairs(all) do
        local material = Ext.Resource.Get(uuid, "Material")
        if material
            and material.IsModded
            and material.VirtualTextureParameters
            and material.VirtualTextureParameters[1]
            and material.VirtualTextureParameters[1].Enabled then
            local sourceFile = normalizePath(material.SourceFile)

            if not sourceFile:find("Baldurs Gate 3/Data/Public/Shared/", 1, true) then
                local modUuid = sourceFile:match("Public/.+_([%w%-]+)/")
                local projectName = sourceFile:match("Baldurs Gate 3/Data/Public/([^/]+)")
                    or sourceFile:match("Public/([^/]+)")
                    or "Unknown"
                local seenKey = modUuid or projectName

                if not seen[seenKey] then
                    seen[seenKey] = true
                    vtsCount = vtsCount + 1

                    local modName = tryGetModName(modUuid, projectName)

                    api.Append(vtsCount)
                    api.Append("Name: " .. modName)
                    api.Append("Project name: " .. projectName)
                    api.Append("----------------------------------------------------------------------------------")
                end
            end
        end
    end

    if vtsCount == 0 then
        api.Append("No modded materials with enabled virtual textures were found.")
    end
end

return Script
