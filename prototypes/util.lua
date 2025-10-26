
local C = require("prototypes.config")
local U = {}

local function has_tool(name) return (data.raw.tool or {})[name] ~= nil end
local function has_tech(name) return (data.raw.technology or {})[name] ~= nil end

function U.is_space_age() return mods and mods["space-age"] ~= nil end
function U.enabled_for(key) local s=settings and settings.startup and settings.startup["ips-enable-"..key]; return (not s) or s.value end

local function icons_from_tech(name)
  local t = (data.raw.technology or {})[name]
  if not t then return nil end
  if t.icons then return t.icons end
  if t.icon then return { {icon=t.icon, icon_size=t.icon_size or 64} } end
  return nil
end
local function icon_from_item(name)
  local it = (data.raw.item or {})[name] or (data.raw.ammo or {})[name] or (data.raw.capsule or {})[name] or (data.raw.module or {})[name] or (data.raw.tool or {})[name]
  if not it then return nil end
  if it.icons then return it.icons end
  if it.icon then return { {icon=it.icon, icon_size=it.icon_size or 64} } end
  return nil
end
function U.icons_for_stream(stream)
  if stream.icon_tech then
    local ic = icons_from_tech(stream.icon_tech)
    if ic then return ic end
  end
  local src = stream.icon_item or ((stream.items or {})[1])
  return icon_from_item(src) or { { icon="__base__/graphics/technology/mining-productivity.png", icon_size=256 } }
end

local PACKS_ALL = {
  "automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack",
  "military-science-pack","utility-science-pack","space-science-pack",
  "agricultural-science-pack","metallurgic-science-pack","electromagnetic-science-pack","cryogenic-science-pack","prometheum-science-pack"
}

local EXTRA = {
  research_concrete            = { "space-science-pack" },
  research_furnace             = { "metallurgic-science-pack" },
  research_mining_drill        = { "metallurgic-science-pack" },
  research_walls               = { "military-science-pack", "space-science-pack" },
  research_grenades            = { "military-science-pack", "space-science-pack" },
  research_rails               = { "space-science-pack" },
  research_electric_energy     = { "electromagnetic-science-pack" },

  research_breeding            = { "agricultural-science-pack" },
  research_plastic             = { "agricultural-science-pack" },
  research_rocket_fuel         = { "agricultural-science-pack" },
  research_bioflux             = { "agricultural-science-pack" },
  research_carbon_fiber        = { "agricultural-science-pack" },
  research_rockets             = { "agricultural-science-pack", "military-science-pack" },

  research_sulfur              = { "metallurgic-science-pack" },
  research_explosives          = { "metallurgic-science-pack" },
  research_low_density_structure = { "metallurgic-science-pack" },
  research_engine              = { "metallurgic-science-pack" },
  research_tungsten            = { "metallurgic-science-pack" },

  research_batteries           = { "electromagnetic-science-pack" },
  research_electronic_circuit  = { "electromagnetic-science-pack" },
  research_advanced_circuit    = { "electromagnetic-science-pack" },
  research_processing_unit     = { "electromagnetic-science-pack" },
  research_electric_engine     = { "electromagnetic-science-pack" },
  research_flying_robot_frame  = { "electromagnetic-science-pack" },
  research_holmium             = { "electromagnetic-science-pack" },
  research_supercapacitor      = { "electromagnetic-science-pack" },
  research_superconductor      = { "electromagnetic-science-pack" },

  research_lithium             = { "cryogenic-science-pack" },
  research_quantum_processor   = { "cryogenic-science-pack" },
  research_modules             = { "cryogenic-science-pack" },

  research_belts               = { "space-science-pack" },
  research_inserters           = { "space-science-pack" },
  research_bullets             = { "military-science-pack", "space-science-pack" },

  research_inventory_capacity  = { "agricultural-science-pack" },
  research_robot_battery       = { "space-science-pack" },
  research_science_pack_productivity = {}
}

local function tool_exists(n) return (data.raw.tool or {})[n] ~= nil end
local function add_if_exists(list, name) if tool_exists(name) then table.insert(list, name) end end
local function merge_lists(a, b)
  local out = {}
  if a then for _,v in ipairs(a) do table.insert(out, v) end end
  if b then for _,v in ipairs(b) do table.insert(out, v) end end
  if #out == 0 then return nil end
  return out
end

function U.pick_science_for_stream(_, key)
  local packs = {}
  if key == "research_science_pack_productivity" then
    for _,p in ipairs(PACKS_ALL) do add_if_exists(packs, p) end
  else
    for _,p in ipairs({"automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack"}) do add_if_exists(packs, p) end
    for _,p in ipairs(EXTRA[key] or {}) do add_if_exists(packs, p) end
  end
  local out, seen = {}, {}
  for _,n in ipairs(packs) do if not seen[n] then seen[n]=true; table.insert(out, {n,1}) end end
  return out
end

function U.build_prereqs_for(key)
  local packs = U.pick_science_for_stream({}, key)
  local reqs, seen = {}, {}
  local function add(t) if t and has_tech(t) and not seen[t] then seen[t]=true; table.insert(reqs,t) end end
  for _,pair in ipairs(packs) do add(pair[1]) end
  local gate_on = (settings and settings.startup and settings.startup["ips-require-space-gate"] and settings.startup["ips-require-space-gate"].value) ~= false
  if gate_on then
    local PROM = "prometheum-science-pack"
    local SPACE = "space-science-pack"
    if U.is_space_age() and tool_exists(PROM) and has_tech(PROM) then add(PROM) else if tool_exists(SPACE) and has_tech(SPACE) then add(SPACE) end end
  end
  return reqs
end

local function recipe_outputs(rec)
  local out = {}
  local function push(p) if p then out[p.name or p[1]] = true end end
  local function scan(def)
    if not def then return end
    if def.results then for _,pp in pairs(def.results) do push(pp) end
    elseif def.result then push({def.result}) end
  end
  if rec.normal or rec.expensive then scan(rec.normal); scan(rec.expensive) else scan(rec) end
  return out
end

local function recipe_uses_blocked_ingredient(rec, patterns)
  if not patterns then return false end
  local function matches(name)
    for _,pat in ipairs(patterns) do
      if string.find(name, pat) then return true end
    end
    return false
  end
  local function scan(def)
    if not def or not def.ingredients then return false end
    for _,ing in pairs(def.ingredients) do
      local name = ing.name or ing[1]
      if name and matches(name) then return true end
    end
    return false
  end
  if rec.normal or rec.expensive then
    if scan(rec.normal) then return true end
    if scan(rec.expensive) then return true end
  else
    if scan(rec) then return true end
  end
  return false
end

local function gather_by_items(items, patterns, options)
  local want = {}
  options = options or {}
  local exclude_recipe_patterns = options.exclude_recipe_patterns
  local exclude_ingredient_patterns = options.exclude_ingredient_patterns
  if items then for _,n in ipairs(items) do want[n]=true end end
  if patterns then
    if data.raw.item then for iname,_ in pairs(data.raw.item) do for _,pat in ipairs(patterns) do if string.find(iname, pat) then want[iname]=true end end end end
    if data.raw.ammo then for iname,_ in pairs(data.raw.ammo) do for _,pat in ipairs(patterns) do if string.find(iname, pat) then want[iname]=true end end end end
    if data.raw.capsule then for iname,_ in pairs(data.raw.capsule) do for _,pat in ipairs(patterns) do if string.find(iname, pat) then want[iname]=true end end end end
    if data.raw.module then for iname,_ in pairs(data.raw.module) do for _,pat in ipairs(patterns) do if string.find(iname, pat) then want[iname]=true end end end end
  end
  local strict_rail = want["rail"] == true
  local seen, list = {}, {}
  for rname, r in pairs(data.raw.recipe or {}) do
    local skip = false
    if exclude_recipe_patterns then
      for _,pat in ipairs(exclude_recipe_patterns) do
        if string.find(rname, pat) then skip = true; break end
      end
    end
    if not skip and recipe_uses_blocked_ingredient(r, exclude_ingredient_patterns) then skip = true end
    if not skip then
      local outs = recipe_outputs(r)
      local match = false
      for it,_ in pairs(want) do
        if strict_rail then
          if it == "rail" and outs["rail"] then match=true; break end
        else
          if outs[it] then match=true; break end
        end
      end
      if match and not seen[rname] then seen[rname]=true; table.insert(list, rname) end
    end
  end
  return list
end

function U.recipes_for_stream(spec)
  if spec.groups then
    local buckets = {}
    for _,g in ipairs(spec.groups) do
      local list = gather_by_items(g.items, g.item_patterns, {
        exclude_recipe_patterns = merge_lists(spec.exclude_recipe_patterns, g.exclude_recipe_patterns),
        exclude_ingredient_patterns = merge_lists(spec.exclude_ingredient_patterns, g.exclude_ingredient_patterns)
      })
      if #list > 0 then table.insert(buckets, {change=g.change or C.shared.per_level_default, recipes=list}) end
    end
    return buckets
  else
    local list = gather_by_items(spec.items, spec.item_patterns or spec.extra_outputs, {
      exclude_recipe_patterns = spec.exclude_recipe_patterns,
      exclude_ingredient_patterns = spec.exclude_ingredient_patterns
    })
    return { {change=C.shared.per_level_default, recipes=list} }
  end
end

return U
