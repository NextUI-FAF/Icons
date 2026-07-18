local oldCreateUI = CreateUI
local MOD_UID = "b36f7a42-7d65-4b9b-a4f3-6b8e3f1c2d90"
local overlaysStarted = false

local function GetModLocation()
    for _, mod in ipairs(__active_mods or {}) do
        if mod.uid == MOD_UID then
            return mod.location
        end
    end
end

local function StartStrategicIconOverlays()
    if overlaysStarted then
        return
    end
    overlaysStarted = true

    local location = GetModLocation()
    if not location then
        LOG("NEXTUI ICONS: active mod location not found; overlays disabled")
        return
    end

    local ok, overlayModule = pcall(
        import,
        location .. "/modules/strategicIconOverlays.lua"
    )
    if not ok then
        LOG("NEXTUI ICONS: overlay module failed to load: " .. tostring(overlayModule))
        return
    end

    if not overlayModule or type(overlayModule.Init) ~= "function" then
        LOG("NEXTUI ICONS: overlay module has no Init function; overlays disabled")
        return
    end

    local initialized, initError = pcall(overlayModule.Init, location)
    if not initialized then
        LOG("NEXTUI ICONS: overlay initialization failed: " .. tostring(initError))
    end
end

function CreateUI(isReplay)
    oldCreateUI(isReplay)
    StartStrategicIconOverlays()
end
