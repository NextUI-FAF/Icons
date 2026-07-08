local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CommandMode = import("/lua/ui/game/commandmode.lua")
local GameMain = import("/lua/ui/game/gamemain.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local GetFocusArmy = GetFocusArmy
local GetIsPausedOfUnit = GetIsPausedOfUnit
local GetSelectedUnits = GetSelectedUnits
local IsDestroyed = IsDestroyed
local SelectUnits = SelectUnits
local UISelectionByCategory = UISelectionByCategory

local DISCOVERY_INTERVAL_TICKS = 50
local OVERLAY_TEXTURES = {}
local PAUSED_OVERLAY_TEXTURE
local ANIMATION_FRAME_SECONDS = 0.16

local knownStructures = {}
local overlays = {}
local currentArmy = false
local lastDiscoveryTick = -DISCOVERY_INTERVAL_TICKS
local initialized = false

local UpgradeOverlay = Class(Bitmap) {
    __init = function(self, parent, unit)
        Bitmap.__init(self, parent)

        self.unit = unit
        self.paused = false
        self.animationTime = 0
        self.animationFrame = 1

        self:DisableHitTest()
        self:SetTexture(OVERLAY_TEXTURES[1])
        LayoutHelpers.SetDimensions(self, 12, 12)
        self:SetNeedsFrameUpdate(true)
        self:Hide()
    end,

    SetPaused = function(self, paused)
        if self.paused == paused then
            return
        end

        self.paused = paused
        if paused then
            self:SetTexture(PAUSED_OVERLAY_TEXTURE)
        else
            self:SetTexture(OVERLAY_TEXTURES[self.animationFrame])
        end
    end,

    OnFrame = function(self, delta)
        if self.unit:IsDead() then
            self:Destroy()
            return
        end

        local parent = self:GetParent()
        local position = parent:GetScreenPos(self.unit)
        if not position then
            self:Hide()
            return
        end

        self.Left:Set(parent.Left() + position.x - 2)
        self.Top:Set(parent.Top() + position.y - 9)

        if not self.paused then
            self.animationTime = self.animationTime + delta
            if self.animationTime >= ANIMATION_FRAME_SECONDS then
                self.animationTime = self.animationTime - ANIMATION_FRAME_SECONDS
                self.animationFrame = self.animationFrame + 1
                if self.animationFrame > table.getn(OVERLAY_TEXTURES) then
                    self.animationFrame = 1
                end
                self:SetTexture(OVERLAY_TEXTURES[self.animationFrame])
            end
        end

        self:Show()
    end,
}

local function DestroyOverlay(id)
    local overlay = overlays[id]
    if overlay and not IsDestroyed(overlay) then
        overlay:Destroy()
    end
    overlays[id] = nil
end

local function ClearState()
    for id, overlay in pairs(overlays) do
        if overlay and not IsDestroyed(overlay) then
            overlay:Destroy()
        end
    end

    knownStructures = {}
    overlays = {}
end

local function RememberStructures(units)
    for _, unit in ipairs(units or {}) do
        if not unit:IsDead() then
            knownStructures[unit:GetEntityId()] = unit
        end
    end
end

local function DiscoverStructures()
    local previousSelection = GetSelectedUnits()

    CommandMode.CacheAndClearCommandMode()
    GameMain.SetIgnoreSelection(true)
    UISelectionByCategory("STRUCTURE", false, false, false, false)
    RememberStructures(GetSelectedUnits())
    SelectUnits(previousSelection)
    GameMain.SetIgnoreSelection(false)
    CommandMode.RestoreCommandMode(true)
end

local function IsUpgrading(unit)
    if unit:IsDead() or unit:GetWorkProgress() <= 0 then
        return false
    end

    local focus = unit:GetFocus()
    return focus and not focus:IsDead() and focus:IsInCategory("STRUCTURE")
end

local function UpdateOverlays()
    local worldView = import("/lua/ui/game/worldview.lua").viewLeft
    if not worldView or IsDestroyed(worldView) then
        return
    end

    for id, unit in pairs(knownStructures) do
        if unit:IsDead() then
            knownStructures[id] = nil
            DestroyOverlay(id)
        elseif IsUpgrading(unit) then
            local overlay = overlays[id]
            if not overlay or IsDestroyed(overlay) then
                overlay = UpgradeOverlay(worldView, unit)
                overlays[id] = overlay
            end
            overlay:SetPaused(GetIsPausedOfUnit(unit))
        else
            DestroyOverlay(id)
        end
    end
end

local function OnBeat()
    local army = GetFocusArmy()
    if army ~= currentArmy then
        ClearState()
        currentArmy = army
        lastDiscoveryTick = -DISCOVERY_INTERVAL_TICKS
    end

    if army == -1 then
        return
    end

    local tick = GameTick()
    if tick - lastDiscoveryTick >= DISCOVERY_INTERVAL_TICKS then
        DiscoverStructures()
        lastDiscoveryTick = tick
    end

    UpdateOverlays()
end

function Init(modLocation)
    if initialized then
        return
    end

    OVERLAY_TEXTURES = {
        modLocation .. "/textures/strategic-overlays/upgrading.dds",
        modLocation .. "/textures/strategic-overlays/upgrading_1.dds",
        modLocation .. "/textures/strategic-overlays/upgrading_2.dds",
    }
    PAUSED_OVERLAY_TEXTURE = modLocation .. "/textures/strategic-overlays/upgrading_paused.dds"

    initialized = true
    GameMain.AddBeatFunction(OnBeat, true, "NextUIIconsStrategicIconOverlays")
end
