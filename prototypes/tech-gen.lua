
local C = require("prototypes.config")
local U = require("prototypes.util")

local function lname(key, spec)
  local locale_key = "technology-name.more-infinite-research."..key
  local out = {locale_key}
  if spec.icon_item then
    table.insert(out, {"item-name."..spec.icon_item})
  elseif spec.items and #spec.items == 1 then
    table.insert(out, {"item-name."..spec.items[1]})
  elseif spec.icon_tech then
    table.insert(out, {"technology-name."..spec.icon_tech})
  end
  return out
end

local function make_stream(key, spec)
  if not U.enabled_for(key) then return end
  if spec.hide_in_space_age and U.is_space_age() then return end

  local base_cost = U.base_cost_for(key, spec)
  local growth_factor = U.growth_factor_for(key, spec)
  local max_level = U.max_level_for(key, spec)
  local count_formula = tostring(base_cost) .. " * " .. tostring(growth_factor) .. "^(L-1)"

  if spec.direct_effects then
    local t = {
      type = "technology",
      name = "recipe-prod-"..key.."-1",
      localised_name = lname(key, spec),
      localised_description = {""},
      icons = U.icons_for_stream(spec),
      effects = spec.direct_effects,
      prerequisites = U.build_prereqs_for(key),
      unit = { count_formula = count_formula, ingredients = U.pick_science_for_stream(spec, key), time = C.shared.research_time },
      upgrade = true,
      max_level = max_level,
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
    unit = { count_formula = count_formula, ingredients = U.pick_science_for_stream(spec, key), time = C.shared.research_time },
    upgrade = true,
    max_level = max_level,
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
