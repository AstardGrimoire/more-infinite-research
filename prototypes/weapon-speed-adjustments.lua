local function strip_weapon_speed_effects()
  local techs = data.raw.technology or {}
  for name, tech in pairs(techs) do
    if string.match(name, "^weapon%-shooting%-speed%-%d+$") and tech.effects then
      local filtered = {}
      for _, effect in ipairs(tech.effects) do
        if effect.type == "gun-speed" then
          local category = effect.ammo_category
          if category == "rocket" or category == "cannon-shell" then
            -- Skip; handled by dedicated technologies.
          else
            table.insert(filtered, effect)
          end
        else
          table.insert(filtered, effect)
        end
      end
      tech.effects = filtered
    end
  end
end

strip_weapon_speed_effects()
