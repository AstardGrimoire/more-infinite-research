
local C = require("prototypes.config")
local defaults = require("defaults")
local U = {}

local function deepcopy(value)
  if table.deepcopy then return table.deepcopy(value) end
  local function copy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, vv in pairs(v) do
      out[copy(k)] = copy(vv)
    end
    return out
  end
  return copy(value)
end

local function has_tool(name) return (data.raw.tool or {})[name] ~= nil end
local function has_tech(name) return (data.raw.technology or {})[name] ~= nil end

function U.is_space_age() return mods and mods["space-age"] ~= nil end

local function startup_setting(name)
  local s = settings and settings.startup and settings.startup[name]
  if s then return s.value end
  return nil
end

local function ensure_minimum(value, fallback, minimum)
  minimum = minimum or 0
  if type(value) ~= "number" then return fallback end
  if value < minimum then return fallback end
  return value
end

local function lookup_default(key, field, spec, fallback)
  local stream_defaults = defaults.streams and defaults.streams[key]
  if stream_defaults and stream_defaults[field] ~= nil then return stream_defaults[field] end
  if spec and spec[field] ~= nil then return spec[field] end
  local shared_defaults = defaults.shared or {}
  if shared_defaults[field] ~= nil then return shared_defaults[field] end
  return fallback
end

local function default_base_cost_for(key, spec)
  return lookup_default(key, "base_cost", spec, C.shared.base_cost)
end

local function default_growth_for(key, spec)
  return lookup_default(key, "growth_factor", spec, C.shared.growth_factor)
end

local function default_max_for(key, spec)
  return lookup_default(key, "max_level", spec, nil)
end

local function default_enabled_for(key, spec)
  return lookup_default(key, "enabled", spec, true)
end

function U.enabled_for(key, spec)
  local s = settings and settings.startup and settings.startup["ips-enable-"..key]
  if s ~= nil then return s.value end
  return default_enabled_for(key, spec)
end

function U.base_cost_for(key, spec)
  local default = default_base_cost_for(key, spec)
  local value = startup_setting("ips-cost-base-"..key)
  if value ~= nil then return ensure_minimum(value, default, 1) end
  return ensure_minimum(default, C.shared.base_cost, 1)
end

function U.growth_factor_for(key, spec)
  local default = default_growth_for(key, spec)
  local value = startup_setting("ips-cost-growth-"..key)
  if value ~= nil then return ensure_minimum(value, default, 1) end
  return ensure_minimum(default, C.shared.growth_factor, 1)
end

local function coerce_max_level(value)
  if value == nil then return nil end
  if value == "infinite" then return "infinite" end
  if type(value) == "number" then
    if value <= 0 then return "infinite" end
    return math.floor(value)
  end
  if type(value) == "string" then
    local num = tonumber(value)
    if not num then return "infinite" end
    if num <= 0 then return "infinite" end
    return math.floor(num)
  end
  return "infinite"
end

function U.max_level_for(key, spec)
  local setting_value = startup_setting("ips-max-level-"..key)
  if setting_value ~= nil then
    if setting_value <= 0 then return "infinite" end
    return math.floor(setting_value)
  end
  local from_spec = coerce_max_level(default_max_for(key, spec))
  if from_spec ~= nil then return from_spec end
  return "infinite"
end

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
  if stream.icons then
    return deepcopy(stream.icons)
  end
  if stream.icon then
    local entry = { icon = stream.icon, icon_size = stream.icon_size or 64 }
    if stream.icon_mipmaps then entry.icon_mipmaps = stream.icon_mipmaps end
    if stream.icon_tint then entry.tint = stream.icon_tint end
    return { entry }
  end
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
    "agricultural-science-pack","metallurgic-science-pack","electromagnetic-science-pack","cryogenic-science-pack","promethium-science-pack"
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
  research_character_trash_slots = { "agricultural-science-pack" },
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

function U.pick_science_for_stream(spec, key)
  local packs = {}
  local desired = spec and spec.science_packs
  if desired == "all" then
    for _,p in ipairs(PACKS_ALL) do add_if_exists(packs, p) end
  elseif type(desired) == "table" then
    for _,p in ipairs(desired) do add_if_exists(packs, p) end
  elseif type(desired) == "string" then
    local list = U.pack_list_for_extension(key, desired)
    if not list then list = U.pack_list_for_extension(desired) end
    if list then for _,p in ipairs(list) do add_if_exists(packs, p) end end
  elseif key == "research_science_pack_productivity" then
    for _,p in ipairs(PACKS_ALL) do add_if_exists(packs, p) end
  else
    for _,p in ipairs({"automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack"}) do add_if_exists(packs, p) end
    for _,p in ipairs(EXTRA[key] or {}) do add_if_exists(packs, p) end
  end
  local out, seen = {}, {}
  for _,n in ipairs(packs) do if not seen[n] then seen[n]=true; table.insert(out, {n,1}) end end
  return out
end

function U.pack_list_all()
  return deepcopy(PACKS_ALL)
end

function U.pack_list_for_extension(key, desired)
  if desired == "all" then
    return U.pack_list_all()
  end
  if type(desired) == "table" then
    local out = {}
    for _, name in ipairs(desired) do table.insert(out, name) end
    return out
  end
  local map = {
    ["braking-force"] = { "automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack","space-science-pack" },
    ["research-speed"] = PACKS_ALL,
    ["worker-robots-storage"] = { "automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack","agricultural-science-pack" },
    ["inserter-capacity-bonus"] = { "automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack","agricultural-science-pack" },
    ["weapon-shooting-speed"] = { "automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack","military-science-pack","space-science-pack" },
    ["laser-shooting-speed"] = { "automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack","military-science-pack","space-science-pack" },
    ["research_electric_shooting_speed"] = { "automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack","military-science-pack","electromagnetic-science-pack" },
    ["research_flamethrower_shooting_speed"] = { "automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack","military-science-pack","space-science-pack" },
    ["research_rocket_shooting_speed"] = { "automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack","military-science-pack","agricultural-science-pack" }
  }
  local list = map[key]
  if not list then return nil end
  return deepcopy(list)
end

function U.build_prereqs_for(key)
  local packs = U.pick_science_for_stream(C.streams[key], key)
  local reqs, seen = {}, {}
  local function add(t) if t and has_tech(t) and not seen[t] then seen[t]=true; table.insert(reqs,t) end end
  for _,pair in ipairs(packs) do add(pair[1]) end
  local gate_on = (settings and settings.startup and settings.startup["ips-require-space-gate"] and settings.startup["ips-require-space-gate"].value) ~= false
  if gate_on then
    local PROM = "promethium-science-pack"
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
