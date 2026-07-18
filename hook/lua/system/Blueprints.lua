local oldPostModBlueprints = PostModBlueprints

local MOD_UID = "b36f7a42-7d65-4b9b-a4f3-6b8e3f1c2d90"
local CONFIG_FILE = "/strategic_icon_priorities.lua"
local fallbackConfigPath = "/mods/NextUI.Icons" .. CONFIG_FILE

local function GetModLocation()
    for _, mod in __active_mods or {} do
        if mod.uid == MOD_UID then
            return mod.location
        end
    end
end

local function ImportPriorityConfig()
    local location = GetModLocation()
    if location then
        local ok, config = pcall(import, location .. CONFIG_FILE)
        if ok and config then
            return config
        end
        WARN("NEXTUI ICONS: unable to load strategic icon priorities from " .. location .. CONFIG_FILE .. ": " .. repr(config))
    end

    local ok, config = pcall(import, fallbackConfigPath)
    if ok and config then
        return config
    end

    WARN("NEXTUI ICONS: unable to load strategic icon priorities from " .. fallbackConfigPath .. ": " .. repr(config))
end

local function ApplyPriorityConfig(config, all_bps, phase)
    if not config or type(config.ApplyStrategicIconPriorities) ~= "function" then
        return
    end

    local ok, changed = pcall(config.ApplyStrategicIconPriorities, all_bps.Unit)
    if not ok then
        WARN("NEXTUI ICONS: strategic icon priority rules failed: " .. repr(changed))
        return
    end

    if changed and changed > 0 then
        LOG("NEXTUI ICONS: applied strategic icon priority rules to " .. changed .. " unit blueprints (" .. phase .. ").")
    end
end

function PostModBlueprints(all_bps)
    local config = ImportPriorityConfig()

    -- Before the native post-processing runs, StrategicIconName still has the
    -- original FAF icon set. This lets user rules target native icon names.
    ApplyPriorityConfig(config, all_bps, "before icon replacement")

    oldPostModBlueprints(all_bps)

    -- After post-processing, StrategicIconName may point at this mod's icon
    -- sets. This lets user rules target nextui_* names if they prefer.
    ApplyPriorityConfig(config, all_bps, "after icon replacement")
end
