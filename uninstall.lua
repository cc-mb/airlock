local TARGET_DIR = "/usr/bin"

local FILES = {
  "mb/airlock.lua"
}

for _, file in ipairs(FILES) do
  local local_file = "/" .. fs.combine(TARGET_DIR, file)
  fs.delete(local_file)
end

settings.undefine("mb.airlock.door_inner")
settings.undefine("mb.airlock.door_inner_side")
settings.undefine("mb.airlock.door_outer")
settings.undefine("mb.airlock.door_outer_side")
settings.undefine("mb.airlock.monitor_chamber")
settings.undefine("mb.airlock.monitor_inner")
settings.undefine("mb.airlock.monitor_outer")
