local defaults = {
  -- Global defaults used when a stream does not provide an override here or in its definition.
  shared = {
    base_cost = 8000,
    growth_factor = 2,
    max_level = 0 -- 0 or nil => infinite
  },
  -- Per-stream overrides. Add, remove, or modify entries as needed.
  streams = {
    research_inventory_capacity = { base_cost = 8000, growth_factor = 1.10, max_level = 0 }
  }
}

return defaults
