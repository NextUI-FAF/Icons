local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local oldStratIconReplacement = StratIconReplacement

local MOD_UID = "b36f7a42-7d65-4b9b-a4f3-6b8e3f1c2d90"
local MOD_IDENTIFIER = "nextui-icons"
local modLocation
local missingCustomIcons = {}

local function GetModLocation()
    if modLocation then
        return modLocation
    end

    for _, mod in ipairs(__active_mods or {}) do
        if mod.uid == MOD_UID then
            modLocation = mod.location
            return modLocation
        end
    end
end

local function ApplyNextUICustomStratIcon(control, iconName)
    local iconSet = string.match(iconName, "^" .. MOD_IDENTIFIER .. "/(.+)$")
    if not iconSet then
        return false
    end

    local location = GetModLocation()
    if not location then
        return true
    end

    local texture = location .. "/custom-strategic-icons/" .. iconSet .. "_rest.dds"
    local width, height = GetTextureDimensions(texture)
    if not width or not height then
        if not missingCustomIcons[iconName] then
            missingCustomIcons[iconName] = true
            LOG("NEXTUI ICONS: missing build-menu strategic icon: " .. texture)
        end
        return true
    end

    control.StratIcon:SetTexture(texture)
    LayoutHelpers.SetDimensions(control.StratIcon, width, height)
    LayoutHelpers.AtTopIn(control.StratIcon, control.Icon, 1)
    LayoutHelpers.AtRightIn(control.StratIcon, control.Icon, 1)
    LayoutHelpers.ResetBottom(control.StratIcon)
    LayoutHelpers.ResetLeft(control.StratIcon)
    control.StratIcon:SetAlpha(0.8)

    return true
end

function StratIconReplacement(control)
    local bp = control.Data and __blueprints[control.Data.id]
    local iconName = bp and bp.StrategicIconName

    if iconName and ApplyNextUICustomStratIcon(control, iconName) then
        return
    end

    oldStratIconReplacement(control)
end
