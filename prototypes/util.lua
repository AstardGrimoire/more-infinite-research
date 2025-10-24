
local C = require("prototypes.config")
local U = {}

local function has_tool(name) return (data.raw.tool or {})[name] ~= nil end
local function has_item(name)
  if (data.raw.item or {})[name] then return true end
  if (data.raw.ammo or {})[name] then return true end
  if (data.raw.capsule or {})[name] then return true end
  if (data.raw.gun or {})[name] then return true end
  return false
end
local function has_tech(name) return (data.raw.technology or {})[name] ~= nil end

function U.is_space_age() return mods["space-age"] ~= nil end
function U.env_key() return U.is_space_age() and "space_age" or "vanilla" end

function U.enabled_for(key)
  local s = settings and settings.startup and settings.startup["ips-enable-"..key]
  return not s or s.value
end

-- icon helpers
local function icons_from_tech(name)
  local t = (data.raw.technology or {})[name]
  if not t then return nil end
  if t.icons then return t.icons end
  if t.icon then return { {icon=t.icon, icon_size=t.icon_size or 64} } end
  return nil
end
local function icons_from_entity(name)
  for _,type in ipairs({"assembling-machine","furnace","lab","beacon","mining-drill","rocket-silo"}) do
    local e = (data.raw[type] or {})[name]
    if e then
      if e.icons then return e.icons end
      if e.icon then return { {icon=e.icon, icon_size=e.icon_size or 64} } end
    end
  end
  return nil
end
local function icon_from_item(name)
  local it = (data.raw.item or {})[name] or (data.raw.ammo or {})[name] or (data.raw.capsule or {})[name]
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
  if stream.icon_entity then
    local ic = icons_from_entity(stream.icon_entity)
    if ic then return ic end
  end
  local src = stream.icon_item or ((stream.items or {})[1])
  return icon_from_item(src) or { { icon="__base__/graphics/technology/mining-productivity.png", icon_size=256 } }
end

-- packs
local PACK_A = "automation-science-pack"
local PACK_L = "logistic-science-pack"
local PACK_C = "chemical-science-pack"
local PACK_P = "production-science-pack"
local PACK_SPACE            = "space-science-pack"
local PACK_MILITARY         = "military-science-pack"
local PACK_AGRICULTURAL     = "agricultural-science-pack"
local PACK_METALLURGIC      = "metallurgic-science-pack"
local PACK_ELECTROMAGNETIC  = "electromagnetic-science-pack"
local PACK_CRYOGENIC        = "cryogenic-science-pack"

local EXTRA = {
  research_breeding        = { PACK_AGRICULTURAL },
  research_plastic         = { PACK_AGRICULTURAL },
  research_rocket_fuel     = { PACK_AGRICULTURAL },
  research_bioflux         = { PACK_AGRICULTURAL },
  research_carbon_fiber    = { PACK_AGRICULTURAL },
  research_rockets         = { PACK_AGRICULTURAL, PACK_MILITARY },

  research_sulfur                 = { PACK_METALLURGIC },
  research_explosives             = { PACK_METALLURGIC },
  research_low_density_structure  = { PACK_METALLURGIC },
  research_engine                 = { PACK_METALLURGIC },
  research_tungsten               = { PACK_METALLURGIC },

  research_batteries            = { PACK_ELECTROMAGNETIC },
  research_electronic_circuit   = { PACK_ELECTROMAGNETIC },
  research_advanced_circuit     = { PACK_ELECTROMAGNETIC },
  research_processing_unit      = { PACK_ELECTROMAGNETIC },
  research_electric_engine      = { PACK_ELECTROMAGNETIC },
  research_flying_robot_frame   = { PACK_ELECTROMAGNETIC },
  research_holmium              = { PACK_ELECTROMAGNETIC },
  research_supercapacitor       = { PACK_ELECTROMAGNETIC },
  research_superconductor       = { PACK_ELECTROMAGNETIC },

  research_lithium              = { PACK_CRYOGENIC },
  research_quantum_processor    = { PACK_CRYOGENIC },
  research_modules              = { PACK_CRYOGENIC },

  research_belts                = { PACK_SPACE },
  research_inserters            = { PACK_SPACE },
  research_bullets              = { PACK_MILITARY, PACK_SPACE },
  -- gears/iron_sticks/copper_cable/copper/iron → no extras
}

local function norm_pack(p) return (type(p)=="table") and {p[1] or p.name, p[2] or p.count or 1} or {p,1} end
local function map_add(map, p) local n,c = table.unpack(norm_pack(p)); if has_tool(n) then map[n] = (map[n] or 0) + (c or 1) end end

function U.pick_science_for_stream(_, key)
  local map = {}
  map_add(map, PACK_A); map_add(map, PACK_L); map_add(map, PACK_C); map_add(map, PACK_P)
  for _,p in ipairs(EXTRA[key] or {}) do map_add(map, p) end
  local out = {}; for n,c in pairs(map) do table.insert(out, {n,c}) end
  table.sort(out, function(a,b) return a[1] < b[1] end)
  return out
end

local function tech_for_pack(pack_name) return has_tech(pack_name) and pack_name or nil end

function U.build_prereqs_for(key)
  local packs = U.pick_science_for_stream({}, key)
  local reqs, seen = {}, {}
  local function add(t) if t and has_tech(t) and not seen[t] then seen[t]=true; table.insert(reqs,t) end end
  for _,pair in ipairs(packs) do add(tech_for_pack(pair[1])) end
  if U.is_space_age() then add(PACK_CRYOGENIC) else add(PACK_SPACE) end
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

local function build_item_set(items, patterns)
  local set = {}
  for _,n in ipairs(items or {}) do if has_item(n) then set[n]=true end end
  if patterns and data.raw.item then
    for iname,_ in pairs(data.raw.item) do
      for _,pat in ipairs(patterns) do if string.find(iname, pat) then set[iname]=true end end
    end
  end
  if patterns and data.raw.ammo then
    for iname,_ in pairs(data.raw.ammo) do
      for _,pat in ipairs(patterns) do if string.find(iname, pat) then set[iname]=true end end
    end
  end
  return set
end

function U.recipes_for_stream(spec)
  local function gather_by_items(items, patterns)
    local set = {}
    if items then for _,n in ipairs(items) do if has_item(n) then set[n]=true end end end
    if patterns and data.raw.item then
      for iname,_ in pairs(data.raw.item) do for _,pat in ipairs(patterns) do if string.find(iname, pat) then set[iname]=true end end end
    end
    if patterns and data.raw.ammo then
      for iname,_ in pairs(data.raw.ammo) do for _,pat in ipairs(patterns) do if string.find(iname, pat) then set[iname]=true end end end
    end
    local seen, list = {}, {}
    for rname, r in pairs(data.raw.recipe or {}) do
      local outs = recipe_outputs(r)
      for it,_ in pairs(set) do
        if outs[it] then if not seen[rname] then seen[rname]=true; table.insert(list, rname) end; break end
      end
    end
    return list
  end

  if spec.groups then
    local buckets = {}
    for _,g in ipairs(spec.groups) do
      local list = gather_by_items(g.items, g.item_patterns)
      if #list > 0 then table.insert(buckets, {change=g.change or C.shared.per_level_default, recipes=list}) end
    end
    return buckets
  elseif spec.mode == "by_entity_or_category" or spec.mode == "by_category_or_match" then
  local out, seen = {}, {}
  local want_cat = {}
  local cats = (spec.categories or (spec.match and spec.match.categories)) or {}
  for _,c in ipairs(cats) do want_cat[c]=true end
  for rname, r in pairs(data.raw.recipe or {}) do
    local match = want_cat[r.category or "crafting"] or false
    if not match and spec.match and spec.match.name_patterns then
      for _,pat in ipairs(spec.match.name_patterns) do if string.find(rname, pat) then match=true; break end end
    end
    if match and not seen[rname] then seen[rname]=true; table.insert(out, rname) end
  end
  if spec.items then
    local extra = (function()
      local set = {}
      for _,n in ipairs(spec.items) do if has_item(n) then set[n]=true end end
      local seen2, list = {}, {}
      for rname, r in pairs(data.raw.recipe or {}) do
        local outs = (function(rec)
          local outx = {}
          local function push(p) if p then outx[p.name or p[1]] = true end end
          local function scan(def)
            if not def then return end
            if def.results then for _,pp in pairs(def.results) do push(pp) end
            elseif def.result then push({def.result}) end
          end
          if rec.normal or rec.expensive then scan(rec.normal); scan(rec.expensive) else scan(rec) end
          return outx
        end)(r)
        for it,_ in pairs(set) do if outs[it] then if not seen2[rname] then seen2[rname]=true; table.insert(list, rname) end; break end end
      end
      return list
    end)()
    local mark = {}; for _,n in ipairs(out) do mark[n]=true end
    for _,n in ipairs(extra) do if not mark[n] then table.insert(out, n) end end
  end
  return { {change=C.shared.per_level_default, recipes=out} }
else
    local list = gather_by_items(spec.items, spec.item_patterns or spec.extra_outputs)
    return { {change=C.shared.per_level_default, recipes=list} }
  end
end

function U.existing_productivity_recipes_set()
  local covered = {}
  for _,tech in pairs(data.raw.technology or {}) do
    local effects = tech.effects
    if effects then
      for _,ef in ipairs(effects) do
        if ef and ef.type == "change-recipe-productivity" and ef.recipe then
          covered[ef.recipe] = true
        end
      end
    end
  end
  return covered
end

function U.count_formula()
  return tostring(C.shared.base_cost) .. " * " .. tostring(C.shared.growth_factor) .. "^(L-1)"
end

return U
