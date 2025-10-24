local settings_data = {}

local tech_keys = {
  "research_breeding",
  -- farming removed
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
  "research_rockets"
}

for _,k in ipairs(tech_keys) do
  table.insert(settings_data, {
    type = "bool-setting",
    name = "ips-enable-" .. k,
    setting_type = "startup",
    default_value = true,
    order = "a-" .. k
  })
end

data:extend(settings_data)
