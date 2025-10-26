
local M = {}

M.shared = { per_level_default = 0.10, base_cost = 8000, growth_factor = 2, research_time = 60 }

M.streams = {
  research_breeding = { requires_space_age = true, items = {"raw-fish","biter-egg","pentapod-egg"}, mode = "by_category_or_match", match = { categories={"biochamber"}, name_patterns={"cultivation","culture"} }, icon_tech = "fish-breeding" },
  research_holmium = { requires_space_age = true, items={"holmium-plate"}, icon_tech="holmium-processing" },
  research_supercapacitor = { requires_space_age = true, items={"supercapacitor"}, icon_tech="supercapacitor" },
  research_superconductor = { requires_space_age = true, items={"superconductor"}, icon_tech="superconductor" },
  research_bioflux = { requires_space_age = true, items={"bioflux"}, icon_tech="bioflux" },
  research_quantum_processor = { requires_space_age = true, items={"quantum-processor"}, icon_tech="quantum-processor" },

  research_plastic = { hide_in_space_age = true, items={"plastic-bar"}, icon_tech="plastics" },
  research_sulfur  = { items={"sulfur"}, icon_tech="sulfur-processing", exclude_ingredient_patterns={"asteroid"} },
  research_batteries = { items={"battery"}, icon_tech="battery", exclude_ingredient_patterns={"scrap"} },
  research_explosives = { items={"explosives"}, icon_tech="explosives" },

  research_gears = { items={"iron-gear-wheel"}, icon_item="iron-gear-wheel", exclude_ingredient_patterns={"scrap"} },
  research_iron_sticks = { items={"iron-stick"}, icon_item="iron-stick", exclude_ingredient_patterns={"scrap"} },
  research_copper_cable = { items={"copper-cable"}, icon_item="copper-cable", exclude_ingredient_patterns={"scrap"} },

  research_electronic_circuit = { items={"electronic-circuit"}, icon_tech="electronics", exclude_ingredient_patterns={"scrap"} },
  research_advanced_circuit = { items={"advanced-circuit"}, icon_tech="advanced-circuit", exclude_ingredient_patterns={"scrap"} },
  research_processing_unit = { hide_in_space_age = true, items={"processing-unit"}, icon_tech="advanced-electronics-2" },

  research_low_density_structure = { hide_in_space_age = true, items={"low-density-structure"}, icon_tech="low-density-structure" },
  research_rocket_fuel = { hide_in_space_age = true, items={"rocket-fuel"} },

  research_copper = { items={"copper-plate"}, icon_item="copper-plate" },
  research_iron   = { items={"iron-plate"}, icon_item="iron-plate" },

  research_engine = { items={"engine-unit"}, icon_tech="engine" },
  research_electric_engine = { items={"electric-engine-unit"}, icon_tech="electric-engine" },
  research_flying_robot_frame = { items={"flying-robot-frame"}, icon_tech="robotics" },

  research_tungsten = { items={"tungsten-plate","tungsten-carbide"}, icon_item="tungsten-plate", icon_tech="tungsten-processing" },
  research_carbon_fiber = { items={"carbon-fiber"}, icon_tech="carbon-fiber" },
  research_lithium = { items={"lithium-plate"}, icon_tech="lithium-processing" },

  research_modules = { icon_tech="modules", groups = {
    { change=0.10, items={"productivity-module","speed-module","efficiency-module","quality-module"} },
    { change=0.05, items={"productivity-module-2","speed-module-2","efficiency-module-2","quality-module-2"} },
    { change=0.02, items={"productivity-module-3","speed-module-3","efficiency-module-3","quality-module-3"} }
  }},

  research_belts = { icon_tech="logistics", groups = {
    { change=0.10, items={"transport-belt","underground-belt","splitter"} },
    { change=0.05, items={"fast-transport-belt","fast-underground-belt","fast-splitter"} },
    { change=0.02, items={"express-transport-belt","express-underground-belt","express-splitter"} },
    { change=0.01, item_patterns={"turbo-transport-belt","turbo-underground-belt","turbo-splitter"} },
    { change=0.005, item_patterns={"hyper-transport-belt","hyper-underground-belt","hyper-splitter"} }
  }},

  research_inserters = { icon_tech="fast-inserter", groups = {
    { change=0.10, items={"inserter","burner-inserter"} },
    { change=0.05, items={"fast-inserter","long-handed-inserter"} },
    { change=0.02, items={"bulk-inserter"}, item_patterns={"bulk%-inserter"} },
    { change=0.01, items={"stack-inserter"}, item_patterns={"stack%-inserter"} }
  }},

  research_bullets = { icon_tech="military", groups = {
    { change=0.10, items={"firearm-magazine","shotgun-shell"} },
    { change=0.05, items={"piercing-rounds-magazine","piercing-shotgun-shell"} },
    { change=0.02, items={"uranium-rounds-magazine","uranium-shotgun-shell"} },
    { change=0.01, item_patterns={"^plutonium%-.+magazine$","^plutonium%-.+shotgun%-shell$"} }
  }},

  research_rockets = { icon_tech="rocketry", groups = {
    { change=0.10, items={"rocket"} },
    { change=0.05, items={"explosive-rocket"} },
    { change=0.02, items={"atomic-bomb"} },
    { change=0.01, items={"plutonium-bomb"}, item_patterns={"^plutonium%-bomb$","^plutonium%-.+bomb$"} }
  }},

  research_inventory_capacity = { icon_tech = "toolbelt", growth_factor = 1.10, direct_effects = { { type="character-inventory-slots-bonus", modifier=1 } } },
  research_robot_battery      = { icon_tech = "logistic-robotics", direct_effects = { { type="worker-robot-battery", modifier=0.10 } } },

  research_science_pack_productivity = { icon_tech = "automation-science-pack", groups = {
      { change=0.10, items={
        "automation-science-pack","logistic-science-pack","chemical-science-pack","production-science-pack",
        "military-science-pack","utility-science-pack","space-science-pack",
        "agricultural-science-pack","metallurgic-science-pack","electromagnetic-science-pack","cryogenic-science-pack","prometheum-science-pack"
      }}
  }},

  research_walls = { icon_item="stone-wall", groups = { {change=0.10, items={"stone-wall"}}, {change=0.05, items={"gate"}} } },
  research_grenades = { icon_item="grenade", groups = { {change=0.10, items={"grenade"}}, {change=0.05, items={"cluster-grenade"}} } },
  research_rails = { icon_item="rail", items={"rail"} },
  research_electric_energy = { icon_tech="electric-energy-accumulators", groups = { { change=0.10, items={"solar-panel","accumulator"} } } },
  research_concrete = { icon_tech = "concrete", groups = { { change = 0.10, items = { "stone-brick" } }, { change = 0.05, items = { "concrete", "hazard-concrete" } }, { change = 0.02, items = { "refined-concrete", "refined-hazard-concrete" } } }, exclude_ingredient_patterns={"scrap"} },
  research_furnace = { icon_tech = "advanced-material-processing-2", groups = { { change = 0.20, items = { "stone-furnace" } }, { change = 0.10, items = { "steel-furnace" } }, { change = 0.05, items = { "electric-furnace" } }, { change = 0.02, items = { "foundry" }, item_patterns = { "^foundry$" } } } },
  research_mining_drill = { icon_tech = "electric-mining", icon_item = "electric-mining-drill", groups = { { change = 0.20, items = { "burner-mining-drill" } }, { change = 0.10, items = { "electric-mining-drill" } }, { change = 0.05, items = { "big-mining-drill" }, item_patterns = { "^big%-mining%-drill$" } } } }
}

return M
