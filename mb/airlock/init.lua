local DoorUi = require "ui.door"

local Door = require "mb.peripheral.door"
local Monitor = require "mb.peripheral.monitor"
local RsDevice = require "mb.peripheral.rs_device"
local RsReader = require "mb.peripheral.rs_reader"

local GuiH = require "GuiH"

local DIR = fs.getDir(shell.getRunningProgram())

settings.load("/" .. fs.combine(DIR, ".settings"))

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

local monitor_chamber = Monitor.new(settings.get("mb.airlock.monitor.chamber"))
local monitor_inner = Monitor.new(settings.get("mb.airlock.monitor.inner"))
local monitor_outer = Monitor.new(settings.get("mb.airlock.monitor.outer"))

local decon = RsDevice.new(
  settings.get("mb.airlock.decon"),
  settings.get("mb.airlock.decon.side")
)

local DECON_DURATION = settings.get("mb.airlock.decon.duration")
local DOOR_DURATION = settings.get("mb.airlock.door.duration")
local DOOR_TRANSITION_DURATION = settings.get("mb.airlock.door.transition.duration")
local DOOR_UNLOCK_PERIOD = settings.get("mb.airlock.door.lock.duration")

local gui_chamber = GuiH.new(monitor_chamber)
local gui_inner = GuiH.new(monitor_inner)
local gui_outer = GuiH.new(monitor_outer)

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
local state = States.INNER_CLOSED
-- desired state
local desired_state = States.INNER_CLOSED
-- duration for which to keep the current state [s]
local keep_state = 0.0

local door_inner_ui = DoorUi.new(gui_inner, "EXIT", function() desired_state = States.INNER_OPEN end)
local door_outer_ui = DoorUi.new(gui_outer, settings.get("mb.airlock.name"), function() desired_state = States.OUTER_OPEN end)

-- mapping state -> door state
local inner_door_states = {
  [States.INNER_OPEN] = DoorUi.get_states().OPEN,
  [States.INNER_TRANSITION] = DoorUi.get_states().BUSY,
  [States.INNER_CLOSED] = DoorUi.get_states().CLOSED,
  [States.DECONTAMINATION] = DoorUi.get_states().BUSY,
  [States.OUTER_CLOSED] = DoorUi.get_states().CLOSED,
  [States.OUTER_TRANSITION] = DoorUi.get_states().BUSY,
  [States.OUTER_OPEN] = DoorUi.get_states().BUSY
}
-- mapping state -> door state
local outer_door_states = {
  [States.INNER_OPEN] = DoorUi.get_states().BUSY,
  [States.INNER_TRANSITION] = DoorUi.get_states().BUSY,
  [States.INNER_CLOSED] = DoorUi.get_states().CLOSED,
  [States.DECONTAMINATION] = DoorUi.get_states().BUSY,
  [States.OUTER_CLOSED] = DoorUi.get_states().CLOSED,
  [States.OUTER_TRANSITION] = DoorUi.get_states().BUSY,
  [States.OUTER_OPEN] = DoorUi.get_states().OPEN
}

-- locks
local inner_door_locked = false
local outer_door_locked = false

-- last value of clock to get deltaT
local last_clock = os.clock()

local duration = {
  [States.INNER_OPEN] = DOOR_DURATION,
  [States.INNER_TRANSITION] = DOOR_TRANSITION_DURATION,
  [States.DECONTAMINATION] = DECON_DURATION,
  [States.OUTER_TRANSITION] = DOOR_TRANSITION_DURATION,
  [States.OUTER_OPEN] = DOOR_DURATION
}

local transition = {
  [States.INNER_OPEN] = { 
    next = {
      state = States.INNER_TRANSITION,
      action = function () door_inner:close() end
    }
  },
  [States.INNER_TRANSITION] = {
    next = { 
      state = States.INNER_CLOSED,
      action = function () end
    },
    prev = { 
      state = States.INNER_OPEN,
      action = function() desired_state = States.INNER_CLOSED end
    }
  },
  [States.INNER_CLOSED] = {
    next = {
      state = States.DECONTAMINATION,
      action = function () decon:set_on() end
    },
    prev = {
      state = States.INNER_TRANSITION,
      action = function () door_inner:open() end
    }
  },
  [States.DECONTAMINATION] = {
    next = {
      state = States.OUTER_TRANSITION,
      action = function () decon:set_off(); door_outer:open() end
    },
    prev = {
      state = States.INNER_TRANSITION,
      action = function () decon:set_off(); door_inner:open() end
    }
  },
  [States.OUTER_CLOSED] = {
    next = {
      state = States.OUTER_TRANSITION,
      action = function () door_outer:open() end
    },
    prev = {
      state = States.INNER_TRANSITION,
      action = function () door_inner:open() end
    }
  },
  [States.OUTER_TRANSITION] = {
    next = {
      state = States.OUTER_OPEN,
      action = function () desired_state = States.OUTER_CLOSED end
    },
    prev = {
      state = States.OUTER_CLOSED,
      action = function () end
    }
  },
  [States.OUTER_OPEN] = {
    prev = {
      state = States.OUTER_TRANSITION,
      action = function () door_outer:close() end
    }
  }
}

local function init()
  local INIT = 0.5
  -- reset door
  door_inner:open()
  os.sleep(INIT)
  door_inner:close()
  os.sleep(INIT)
  
  door_outer:open()
  os.sleep(INIT)
  door_outer:close()
  os.sleep(INIT)

  decon:set_on()
  os.sleep(INIT)
  decon:set_off()
  os.sleep(INIT)
end

local function update_ui()
  door_inner_ui:set_state(inner_door_locked and DoorUi.get_states().LOCKED or inner_door_states[state])
  door_outer_ui:set_state(outer_door_locked and DoorUi.get_states().LOCKED or outer_door_states[state])
end

local function update(delta_t)
  if keep_state > 0 then
    keep_state = keep_state - delta_t
  elseif state ~= desired_state then
    local t = { state = state, action = function () print("Invalid transition!") end }
    if state < desired_state then
      t = transition[state].next or t
    elseif state > desired_state then
      t = transition[state].prev or t
    end

    t.action()
    state = t.state
    keep_state = duration[t.state] or 0
  end

  update_ui()
end

local function main()
  while true do
    local clock = os.clock()
    local delta_t = clock - last_clock
    last_clock = clock

    update(delta_t)

    -- limit to 4 Hz
    os.sleep(0.25)
  end
end

init()

gui_chamber.async(function () gui_inner.execute() end)
gui_chamber.async(function () gui_outer.execute() end)

gui_chamber.execute(main)
