local defaults = require("defaults")

local base_defaults = defaults.base_extensions or {}

local U = require("prototypes.util")

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

local function escape_pattern(text)
  return text:gsub("([^%w])", "%%%1")
end

local function format_number(value)
  if type(value) ~= "number" then return tostring(value) end
  if math.abs(value - math.floor(value)) < 1e-6 then
    return tostring(math.floor(value + 0.5))
  end
  return string.format("%.6g", value)
end

local function tool_exists(name)
  return (data.raw.tool or {})[name] ~= nil
end

local function startup_setting(name)
  local s = settings and settings.startup and settings.startup[name]
  if s then return s.value end
  return nil
end

local function is_enabled(key, spec)
  local value = startup_setting("mir-enable-" .. key)
  if value ~= nil then return value end
  if spec and spec.enabled ~= nil then return spec.enabled end
  return true
end

local function sanitize_number(value)
  if type(value) ~= "number" then return nil end
  return value
end

local function build_prerequisites(previous_name, last_prereqs)
  local out, seen = {}, {}
  if last_prereqs then
    for _, name in ipairs(last_prereqs) do
      if name ~= previous_name and not seen[name] then
        seen[name] = true
        table.insert(out, name)
      end
    end
  end
  if previous_name and not seen[previous_name] then
    table.insert(out, previous_name)
  end
  return out
end

local function compute_growth_from_counts(levels, counts)
  local ratios = {}
  for idx = 1, #counts - 1 do
    local current = counts[idx]
    local next_value = counts[idx + 1]
    if current and current > 0 and next_value and next_value > 0 then
      table.insert(ratios, next_value / current)
    end
  end
  if #ratios == 0 then return nil end
  local first = ratios[1]
  local consistent = true
  for i = 2, #ratios do
    if math.abs(ratios[i] - first) > 1e-6 then
      consistent = false
      break
    end
  end
  if consistent and first >= 1 then return first end
  return nil
end

local function compute_growth_from_span(levels, counts)
  if #levels < 2 then return nil end
  local first = counts[1]
  local last = counts[#counts]
  if not first or first <= 0 or not last or last <= 0 then return nil end
  local span = levels[#levels] - levels[1]
  if span <= 0 then return nil end
  local ratio = last / first
  if ratio <= 0 then return nil end
  return ratio ^ (1 / span)
end

local function compute_growth_from_prev(last_unit, prev_unit)
  if not last_unit or not prev_unit then return nil end
  if not last_unit.count or not prev_unit.count then return nil end
  if prev_unit.count <= 0 then return nil end
  local ratio = last_unit.count / prev_unit.count
  if ratio < 1 then return nil end
  return ratio
end

local function resolve_science_packs(spec, fallback_unit, key)
  local desired = spec and spec.science_packs or nil
  local list = nil
  if desired == "all" then
    list = U.pack_list_all and U.pack_list_all()
  elseif desired then
    if type(desired) == "table" then
      list = {}
      for _, name in ipairs(desired) do table.insert(list, name) end
    else
      list = U.pack_list_for_extension and U.pack_list_for_extension(desired)
    end
  else
    list = U.pack_list_for_extension and U.pack_list_for_extension(key)
  end
  if list and #list > 0 then
    local out = {}
    for _, pack in ipairs(list) do
      if tool_exists(pack) then
        table.insert(out, {pack, 1})
      end
    end
    if #out > 0 then return out end
  end
  return deepcopy((fallback_unit or {}).ingredients or {})
end

local function build_inserter_effects(last, spec)
  spec = spec or {}
  local bulk_increment = spec.bulk_increment or spec.stack_increment or 4
  local non_bulk_increment = spec.non_bulk_increment or spec.non_stack_increment or 2
  local out = {}
  for _, effect in ipairs(last.effects or {}) do
    local copy = deepcopy(effect)
    if copy.type == "bulk-inserter-capacity-bonus" or copy.type == "stack-inserter-capacity-bonus" then
      copy.modifier = bulk_increment
    elseif copy.type == "inserter-stack-size-bonus" then
      copy.modifier = non_bulk_increment
    end
    table.insert(out, copy)
  end
  return out
end

local SPECIALS = {
  ["inserter-capacity-bonus"] = {
    effect_builder = build_inserter_effects
  }
}

local function extend_chain(key)
  local spec = base_defaults[key] or {}
  if not is_enabled(key, spec) then return end

  local pattern = "^" .. escape_pattern(key) .. "%-(%d+)$"
  local levels, by_level = {}, {}
  local has_infinite = false

  for name, tech in pairs(data.raw.technology) do
    local level = tonumber(string.match(name, pattern))
    if level then
      if tech.max_level == "infinite" then
        has_infinite = true
      end
      table.insert(levels, level)
      by_level[level] = tech
    end
  end

  if has_infinite or #levels == 0 then return end
  table.sort(levels)

  local detected_highest = levels[#levels]
  local min_level = spec.min_level or (detected_highest + 1)
  if detected_highest < min_level - 1 then
    -- Vanilla chain does not reach the expected prerequisite tier.
    return
  end

  local extend_from_level = math.max(detected_highest, min_level - 1)
  if extend_from_level < min_level - 1 then extend_from_level = min_level - 1 end
  local base_level = extend_from_level
  local desired_new_level = extend_from_level + 1

  if desired_new_level < min_level then
    -- Need to catch up to the minimum level; treat the next vanilla level as base.
    base_level = min_level - 1
    desired_new_level = min_level
  end

  local base_tech = by_level[base_level]
  if not base_tech or not base_tech.unit then return end
  if base_tech.max_level == "infinite" then return end
  -- Allow anchoring even if vanilla used a formula.

  local new_name = key .. "-" .. desired_new_level
  if data.raw.technology[new_name] then return end

  local max_level_setting = spec.max_level
  local max_level_value = "infinite"
  if type(max_level_setting) == "number" and max_level_setting > 0 then
    max_level_value = max_level_setting
  end

  local last_count = base_tech.unit.count
  local prev_unit = nil
  if base_level > 1 then
    local prev_level = base_level - 1
    while prev_level >= 1 do
      local prev = by_level[prev_level]
      if prev and prev.unit then
        prev_unit = prev.unit
        break
      end
      prev_level = prev_level - 1
    end
  end

  local function compute_growth_fallback()
    if prev_unit and prev_unit.count and prev_unit.count > 0 and last_count and last_count > 0 then
      return last_count / prev_unit.count
    end
    if prev_unit == nil then
      -- Attempt to infer using earlier tiers if available.
      local ratios = {}
      local prev = nil
      for _, lvl in ipairs(levels) do
        if lvl < base_level then
          local tech = by_level[lvl]
          if tech and tech.unit and tech.unit.count then
            if prev and prev.count and prev.count > 0 then
              table.insert(ratios, tech.unit.count / prev.count)
            end
            prev = tech.unit
          end
        end
      end
      if #ratios > 0 then
        local first = ratios[1]
        local consistent = true
        for i = 2, #ratios do
          if math.abs(ratios[i] - first) > 1e-6 then
            consistent = false
            break
          end
        end
        if consistent then return first end
      end
    end
    return nil
  end

  local growth_setting = sanitize_number(startup_setting("mir-cost-growth-" .. key))
  local growth = nil
  if growth_setting and growth_setting > 0 then
    growth = growth_setting
  end
  if not growth then
    local default_growth = sanitize_number(spec.growth_factor)
    if default_growth and default_growth > 0 then
      growth = default_growth
    end
  end
  if not growth then
    growth = compute_growth_from_prev(base_tech.unit, prev_unit)
  end
  if not growth then
    growth = compute_growth_fallback()
  end
  if not growth or growth <= 0 then
    growth = 1
  end

  local base_setting = sanitize_number(startup_setting("mir-cost-base-" .. key))
  local base_value = nil
  if base_setting and base_setting > 0 then
    base_value = base_setting
  end

  if not base_value then
    local spec_base = sanitize_number(spec.base_cost)
    if spec_base and spec_base > 0 then
      base_value = spec_base
    end
  end
  if not base_value then
    if last_count and growth > 0 then
      base_value = last_count / (growth ^ (base_level - 1))
    end
  end
  if not base_value or base_value <= 0 then
    base_value = 1000
  end

  local new = deepcopy(base_tech)
  new.name = new_name
  new.localised_name = base_tech.localised_name
  new.localised_description = base_tech.localised_description
  new.prerequisites = build_prerequisites(key .. "-" .. base_level, base_tech.prerequisites)
  new.level = desired_new_level

  local special = SPECIALS[key]
  if special and special.effect_builder then
    new.effects = special.effect_builder(base_tech, spec)
  else
    new.effects = deepcopy(base_tech.effects or {})
  end

  new.max_level = max_level_value
  new.upgrade = true

  local research_setting = sanitize_number(startup_setting("mir-research-time-" .. key))
  local research_time = research_setting
  if not research_time or research_time <= 0 then
    research_time = sanitize_number(spec.research_time)
  end
  if not research_time or research_time <= 0 then
    research_time = base_tech.unit.time or 60
  end

  new.unit = {
    count_formula = format_number(base_value) .. " * " .. format_number(growth) .. "^(L-1)",
    ingredients = resolve_science_packs(spec, base_tech.unit, key),
    time = research_time
  }

  if special and special.on_extend then
    special.on_extend(new, base_tech, spec)
  end

  data:extend({ new })
end

for key, _ in pairs(base_defaults) do
  extend_chain(key)
end
