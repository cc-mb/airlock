local DoorUi = require "ui.door"

local Door = require "mb.peripheral.door"
local Monitor = require "mb.peripheral.monitor"
local RsDevice = require "mb.peripheral.rs_device"

local GuiH = require "GuiH"

-- Controller of the door inside the protected area.
local door_inner = Door:new(
  settings.get("mb.airlock.door_inner"),
  settings.get("mb.airlock.door_inner_side")
)

local door_outer = Door:new(
  settings.get("mb.airlock.door_outer"),
  settings.get("mb.airlock.door_outer_side")
)

local monitor_chamber = Monitor:new(settings.get("mb.airlock.monitor_chamber"))
local monitor_inner = Monitor:new(settings.get("mb.airlock.monitor_inner"))
local monitor_outer = Monitor:new(settings.get("mb.airlock.monitor_outer"))

local decon = RsDevice:new(
  settings.get("mb.airlock.decon"),
  settings.get("mb.airlock.decon_side")
)

local DECON_INTERVAL = settings.get("mb.airlock.decon_interval")

local gui_chamber = GuiH.new(monitor_chamber)
local gui_inner = GuiH.new(monitor_inner)
local gui_outer = GuiH.new(monitor_outer)

local door_ui_inner = DoorUi.new(gui_inner, nil, function() end)
local door_ui_outer = DoorUi.new(gui_outer, "Test", function() end)
