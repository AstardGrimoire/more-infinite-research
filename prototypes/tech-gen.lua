
local C = require("prototypes.config")
local U = require("prototypes.util")

local function lname(key, spec)
  local by_key = {
    research_bullets = {"", "Bullet productivity"},
    research_rockets = {"", "Rocket productivity"},
    research_inventory_capacity = {"", "Character inventory slots"}
  }
  if by_key[key] then return by_key[key] end
  if spec.icon_item then return {"", {"item-name."..spec.icon_item}, " productivity"} end
  if spec.items and #spec.items == 1 then return {"", {"item-name."..spec.items[1]}, " productivity"} end
  if spec.icon_tech then return {"", {"technology-name."..spec.icon_tech}, " productivity"} end
  return {"", "Productivity"}
end

local function make_stream(key, spec)
  if not U.enabled_for(key) then return end
  if spec.hide_in_space_age and U.is_space_age() then return end

  if spec.direct_effects then
    local t = {
      type = "technology",
      name = "recipe-prod-"..key.."-1",
      localised_name = lname(key, spec),
      localised_description = {""},
      icons = U.icons_for_stream(spec),
      effects = spec.direct_effects,
      prerequisites = U.build_prereqs_for(key),
      unit = { count_formula = tostring(C.shared.base_cost) .. " * " .. tostring(spec.growth_factor or C.shared.growth_factor) .. "^(L-1)", ingredients = U.pick_science_for_stream(spec, key), time = C.shared.research_time },
      upgrade = true,
      max_level = "infinite",
      order = "p["..key.."]"
    }
    if key == "research_rails" then
      t.icons = nil
      t.icon = "__base__/graphics/icons/rail.png"
      t.icon_size = 64
    end
    data:extend({t})
    return
  end

  local buckets = require("prototypes.util").recipes_for_stream(spec)
  local effects = {}
  for _,b in ipairs(buckets) do
    for _,r in ipairs(b.recipes) do
      table.insert(effects, { type="change-recipe-productivity", recipe=r, change=b.change or C.shared.per_level_default })
    end
  end
  if #effects == 0 then return end

  local t = {
    type = "technology",
    name = "recipe-prod-"..key.."-1",
    localised_name = lname(key, spec),
    localised_description = {""},
    icons = U.icons_for_stream(spec),
    effects = effects,
    prerequisites = U.build_prereqs_for(key),
    unit = { count_formula = tostring(C.shared.base_cost) .. " * " .. tostring(spec.growth_factor or C.shared.growth_factor) .. "^(L-1)", ingredients = U.pick_science_for_stream(spec, key), time = C.shared.research_time },
    upgrade = true,
    max_level = "infinite",
    order = "p["..key.."]"
  }
  if key == "research_rails" then
    t.icons = nil
    t.icon = "__base__/graphics/icons/rail.png"
    t.icon_size = 64
  end
  data:extend({t})
end

for key, spec in pairs(require("prototypes.config").streams) do
  make_stream(key, spec)
end
