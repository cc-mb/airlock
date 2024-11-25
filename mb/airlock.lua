local Door = require "mb.interaction.door"
local Monitor = require "mb.interaction.monitor"

-- Controller of the door inside the protected area.
local door_inner = Door:new(
  settings.get("mb.airlock.door_inner") and peripheral.wrap(settings.get("mb.airlock.door_inner")) or redstone,
  settings.get("mb.airlock.door_inner_side")
)

local door_outer = Door:new(
  settings.get("mb.airlock.door_outer") and peripheral.wrap(settings.get("mb.airlock.door_outer")) or redstone,
  settings.get("mb.airlock.door_outer_side")
)

local monitor_chamber = Monitor:new(settings.get("mb.airlock.monitor_chamber"))
local monitor_inner = Monitor:new(settings.get("mb.airlock.monitor_inner"))
local monitor_outer = Monitor:new(settings.get("mb.airlock.monitor_outer"))
