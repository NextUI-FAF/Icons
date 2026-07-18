-- User-editable strategic icon draw-order rules.
--
-- FAF draws lower StrategicIconSortPriority values above higher values:
--   0   = highest / most important
--   255 = lowest / least important
--
-- These rules only raise matching units by default. If a unit already has a
-- lower priority than the rule, it keeps its existing value.

local PriorityRules = {
    {
        name = "T3 strategic missile launchers",
        priority = 1,
        techs = { [3] = true },
        strategicIconNames = { "icon_structure3_missile" },
    },
    {
        name = "T2 tactical missile launchers",
        priority = 90,
        techs = { [2] = true },
        strategicIconNames = { "icon_structure2_missile" },
    },
    {
        name = "T3 strategic missile defense",
        priority = 80,
        techs = { [3] = true },
        categories = { "STRUCTURE", "ANTIMISSILE" },
    },
    {
        name = "T3 strategic artillery",
        priority = 110,
        techs = { [3] = true },
        categories = { "STRUCTURE", "ARTILLERY" },
        excludedBlueprints = { "xab2307" },
    },
}

local function HasCategory(bp, wanted)
    if bp.CategoriesHash and bp.CategoriesHash[wanted] then
        return true
    end

    if not bp.Categories then
        return false
    end

    for _, category in bp.Categories do
        if category == wanted then
            return true
        end
    end

    return false
end

local function Contains(values, wanted)
    if not values then
        return false
    end

    for _, value in values do
        if value == wanted then
            return true
        end
    end

    return false
end

local function GetTech(bp)
    if HasCategory(bp, "EXPERIMENTAL") then
        return 4
    elseif HasCategory(bp, "TECH3") then
        return 3
    elseif HasCategory(bp, "TECH2") then
        return 2
    end

    return 1
end

local function MatchesRule(rule, id, bp)
    if Contains(rule.excludedBlueprints, string.lower(id)) then
        return false
    end

    if rule.techs and not rule.techs[GetTech(bp)] then
        return false
    end

    for _, category in rule.categories or {} do
        if not HasCategory(bp, category) then
            return false
        end
    end

    if rule.strategicIconNames and not Contains(rule.strategicIconNames, bp.StrategicIconName) then
        return false
    end

    return true
end

function ApplyStrategicIconPriorities(units)
    local changed = 0

    for id, bp in units do
        for _, rule in PriorityRules do
            if MatchesRule(rule, id, bp) then
                local current = bp.StrategicIconSortPriority or 255
                if rule.priority < current then
                    bp.StrategicIconSortPriority = rule.priority
                    changed = changed + 1
                end
                break
            end
        end
    end

    return changed
end
