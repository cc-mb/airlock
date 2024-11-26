local DoorUi = require "ui.door"

local Door = require "mb.peripheral.door"
local Monitor = require "mb.peripheral.monitor"
local RsDevice = require "mb.peripheral.rs_device"
local RsReader = require "mb.peripheral.rs_reader"

local GuiH = require "GuiH"

settings.load()

-- Controller of the door inside the protected area.
local door_inner = Door.new(
  settings.get("mb.airlock.door.inner"),
  settings.get("mb.airlock.door.inner.side")
)

local door_inner_lock = nil
if settings.get("mb.airlock.door.inner.lock") then
  door_inner_lock = RsReader.new(
    settings.get("mb.airlock.door.inner.lock"),
    settings.get("mb.airlock.door.inner.lock.side")
  )
end

local door_outer = Door.new(
  settings.get("mb.airlock.door.outer"),
  settings.get("mb.airlock.door.outer.side")
)

local door_outer_lock = nil
if settings.get("mb.airlock.door.inner.lock") then
  door_outer_lock = RsReader.new(
    settings.get("mb.airlock.door.inner.lock"),
    settings.get("mb.airlock.door.inner.lock.side")
  )
end

local monitor_chamber = Monitor.new(settings.get("mb.airlock.monitor_chamber"))
local monitor_inner = Monitor.new(settings.get("mb.airlock.monitor_inner"))
local monitor_outer = Monitor.new(settings.get("mb.airlock.monitor_outer"))

local decon = RsDevice.new(
  settings.get("mb.airlock.decon"),
  settings.get("mb.airlock.decon_side")
)

local DECON_DURATION = settings.get("mb.airlock.decon.duration")
local DOOR_DURATION = settings.get("mb.airlock.door.duration")
local DOOR_UNLOCK_PERIOD = settings.get("mb.airlock.door.lock.duration")

local gui_chamber = GuiH.new(monitor_chamber)
local gui_inner = GuiH.new(monitor_inner)
local gui_outer = GuiH.new(monitor_outer)

local door_ui_inner = DoorUi.new(gui_inner, "Foo", function() end)
local door_ui_outer = DoorUi.new(gui_outer, "Bar", function() end)

local States = {
  INNER_OPEN = 0,
  INNER_TRANSITION = 1,
  INNER_CLOSED = 2,
  DECONTAMINATION = 3,
  OUTER_CLOSED = 4,
  OUTER_TRANSITION = 5,
  OUTER_OPEN = 6
}

-- current state
local state = States.OUTER_CLOSED
-- desired state
local desired_state = States.OUTER_CLOSED
-- duration for which to keep the current state [s]
local keep_state = 0.0

local function init()
  -- reset door
  door_inner:open()
  door_inner:close()

  door_outer:open()
  door_outer:close()
end

local function main()
  while true do
    print("Main baby!")
    os.sleep(1)
  end
end

init()

gui_chamber.async(gui_inner.execute)
gui_chamber.async(gui_outer.execute)

gui_chamber.execute(main)
