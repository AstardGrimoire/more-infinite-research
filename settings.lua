local C = require("prototypes.config")
local defaults = require("defaults")

local settings_data = {}

local function lookup_default(key, field, stream, fallback)
  local stream_defaults = defaults.streams and defaults.streams[key]
  if stream_defaults and stream_defaults[field] ~= nil then return stream_defaults[field] end
  if stream and stream[field] ~= nil then return stream[field] end
  local shared_defaults = defaults.shared or {}
  if shared_defaults[field] ~= nil then return shared_defaults[field] end
  return fallback
end

local function default_base_cost(key, stream)
  return lookup_default(key, "base_cost", stream, C.shared.base_cost)
end

local function default_growth_factor(key, stream)
  return lookup_default(key, "growth_factor", stream, C.shared.growth_factor)
end

local function default_max_level_setting(key, stream)
  local ml = lookup_default(key, "max_level", stream, 0)
  if ml == nil or ml == "infinite" then return 0 end
  local num = tonumber(ml)
  if not num or num <= 0 then return 0 end
  return math.floor(num)
end

local function default_enabled(key, stream)
  local value = lookup_default(key, "enabled", stream, true)
  return not not value
end

table.insert(settings_data, {
  type = "bool-setting",
  name = "ips-require-space-gate",
  setting_type = "startup",
  default_value = true,
  order = "a-00",
  localised_name = {"mod-setting-name.ips-require-space-gate"},
  localised_description = {"mod-setting-description.ips-require-space-gate"}
})

local stream_order = {
  "research_breeding",
  "research_plastic",
  "research_sulfur",
  "research_batteries",
  "research_explosives",
  "research_gears",
  "research_iron_sticks",
  "research_copper_cable",
  "research_electronic_circuit",
  "research_advanced_circuit",
  "research_processing_unit",
  "research_low_density_structure",
  "research_rocket_fuel",
  "research_copper",
  "research_iron",
  "research_engine",
  "research_electric_engine",
  "research_flying_robot_frame",
  "research_tungsten",
  "research_holmium",
  "research_supercapacitor",
  "research_superconductor",
  "research_bioflux",
  "research_carbon_fiber",
  "research_lithium",
  "research_quantum_processor",
  "research_modules",
  "research_belts",
  "research_inserters",
  "research_bullets",
  "research_rockets",
  "research_inventory_capacity",
  "research_robot_battery",
  "research_science_pack_productivity",
  "research_walls",
  "research_grenades",
  "research_rails",
  "research_electric_energy",
  "research_concrete",
  "research_furnace",
  "research_mining_drill"
}

local known = {}
for _, key in ipairs(stream_order) do known[key] = true end

local extras = {}
for key, _ in pairs(C.streams) do
  if not known[key] then table.insert(extras, key) end
end
table.sort(extras)
for _, key in ipairs(extras) do table.insert(stream_order, key) end

for _, key in ipairs(stream_order) do
  local stream = C.streams[key]
  if stream then
    local tech_locale = {"technology-name.more-infinite-research."..key}
    table.insert(settings_data, {
      type = "bool-setting",
      name = "ips-enable-"..key,
      setting_type = "startup",
      default_value = default_enabled(key, stream),
      order = "a-"..key,
      localised_name = {"mod-setting-name.ips-enable-stream", tech_locale},
      localised_description = {"mod-setting-description.ips-enable-stream", tech_locale}
    })
    table.insert(settings_data, {
      type = "int-setting",
      name = "ips-cost-base-"..key,
      setting_type = "startup",
      default_value = default_base_cost(key, stream),
      minimum_value = 1,
      maximum_value = 2147483647,
      order = "b-"..key.."-base",
      localised_name = {"mod-setting-name.ips-cost-base-stream", tech_locale},
      localised_description = {"mod-setting-description.ips-cost-base-stream", tech_locale}
    })
    table.insert(settings_data, {
      type = "double-setting",
      name = "ips-cost-growth-"..key,
      setting_type = "startup",
      default_value = default_growth_factor(key, stream),
      minimum_value = 1,
      order = "b-"..key.."-growth",
      localised_name = {"mod-setting-name.ips-cost-growth-stream", tech_locale},
      localised_description = {"mod-setting-description.ips-cost-growth-stream", tech_locale}
    })
    table.insert(settings_data, {
      type = "int-setting",
      name = "ips-max-level-"..key,
      setting_type = "startup",
      default_value = default_max_level_setting(key, stream),
      minimum_value = 0,
      maximum_value = 2147483647,
      order = "b-"..key.."-max",
      localised_name = {"mod-setting-name.ips-max-level-stream", tech_locale},
      localised_description = {"mod-setting-description.ips-max-level-stream", tech_locale}
    })
  end
end

data:extend(settings_data)
