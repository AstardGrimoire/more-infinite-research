
local C = require("prototypes.config")
local U = require("prototypes.util")

local existing = U.existing_productivity_recipes_set()

local function trim_conflicts(buckets)
  local any = false
  for _,b in ipairs(buckets) do
    local kept = {}
    for _,r in ipairs(b.recipes or {}) do
      if not existing[r] then table.insert(kept, r) end
    end
    b.recipes = kept
    if #kept > 0 then any = true end
  end
  return any
end

local function localized_name_for(key, spec)
  if spec.icon_item then
    return {"", {"item-name."..spec.icon_item}, " productivity"}
  end
  if spec.items and #spec.items == 1 then
    local item = spec.items[1]
    return {"", {"item-name."..item}, " productivity"}
  end
  local fallback = {
    research_modules = {"", "Modules productivity"},
    research_belts = {"", "Belts productivity"},
    research_inserters = {"", "Inserters productivity"},
    research_bullets = {"", "Bullets productivity"},
    research_rockets = {"", "Rockets productivity"},
    research_breeding = {"", "Breeding productivity"}
  }
  if fallback[key] then return fallback[key] end
  if spec.icon_tech then return {"", {"technology-name."..spec.icon_tech}, " productivity"} end
  return {"", "Productivity"}
end

local function make_stream(key, spec)
  if not U.enabled_for(key) then return end
  if spec.requires_space_age and not U.is_space_age() then return end

  local buckets = U.recipes_for_stream(spec)
  local any = false
  for _,b in ipairs(buckets) do if #b.recipes > 0 then any = true; break end end
  if not any then return end
  if not trim_conflicts(buckets) then return end

  local effects = {}
  for _,b in ipairs(buckets) do
    for _,r in ipairs(b.recipes) do
      table.insert(effects, { type="change-recipe-productivity", recipe=r, change=b.change })
    end
  end

  data:extend({
    {
      type = "technology",
      name = "recipe-prod-"..key.."-1",
      localised_name = localized_name_for(key, spec),
      localised_description = {""},
      icons = U.icons_for_stream(spec),
      effects = effects,
      prerequisites = U.build_prereqs_for(key),
      unit = {
        count_formula = U.count_formula(),
        ingredients   = U.pick_science_for_stream(spec, key),
        time          = C.shared.research_time
      },
      upgrade = true,
      max_level = "infinite",
      order = "p["..key.."]"
    }
  })
end

for key, spec in pairs(require("prototypes.config").streams) do
  make_stream(key, spec)
end
