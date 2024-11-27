local ChamberUi = require "ui.chamber"
local DoorUi = require "ui.door"

local Door = require "mb.peripheral.door"
local Monitor = require "mb.peripheral.monitor"
local RsDevice = require "mb.peripheral.rs_device"
local RsReader = require "mb.peripheral.rs_reader"

local GuiH = require "GuiH"

local DIR = fs.getDir(shell.getRunningProgram())

settings.load("/" .. fs.combine(DIR, ".settings"))

-- info panels
local ROOM_INNER_NUMBER = settings.get("mb.airlock.room.inner.number")
local ROOM_INNER_NAME = settings.get("mb.airlock.room.inner.name")
local ROOM_INNER_HAZARD = settings.get("mb.airlock.room.inner.hazard")
local ROOM_OUTER_NUMBER = settings.get("mb.airlock.room.outer.number")
local ROOM_OUTER_NAME = settings.get("mb.airlock.room.outer.name")
local ROOM_OUTER_HAZARD = settings.get("mb.airlock.room.outer.hazard")

  -- decontamination
local DECON_CONTROLLER = settings.get("mb.airlock.decon")
local DECON_DURATION = settings.get("mb.airlock.decon.duration")
local DECON_SIDE = settings.get("mb.airlock.decon.side")

  -- doors
local DOOR_INNER_CONTROLLER = settings("mb.airlock.door.inner")
local DOOR_INNER_SIDE = settings("mb.airlock.door.inner.side")
local DOOR_OUTER_CONTROLLER = settings("mb.airlock.door.outer")
local DOOR_OUTER_SIDE = settings("mb.airlock.door.outer.side")
local DOOR_OPEN_DURATION = settings("mb.airlock.door.duration")
local DOOR_TRANSITION_DURATION = settings("mb.airlock.door.transition.duration")

  -- locks
local LOCK_INNER_READER = settings.get("mb.airlock.lock.inner")
local LOCK_INNER_SIDE = settings.get("mb.airlock.lock.inner.side")
local LOCK_INNER_LEVEL = settings.get("mb.airlock.lock.inner.level")
local LOCK_OUTER_READER = settings.get("mb.airlock.lock.outer")
local LOCK_OUTER_SIDE = settings.get("mb.airlock.lock.outer.side")
local LOCK_OUTER_LEVEL = settings.get("mb.airlock.lock.outer.level")
local LOCK_UNLOCK_DURATION = settings.get("mb.airlock.lock.duration")

  -- monitors
local MONITOR_CHAMBER = settings.get("mb.airlock.monitor.chamber")
local MONITOR_INNER = settings.get("mb.airlock.monitor.inner")
local MONITOR_OUTER = settings.get("mb.airlock.monitor.outer")

-- peripherals
local decon = RsDevice.new(DECON_CONTROLLER, DECON_SIDE)

local door_inner = Door.new(DOOR_INNER_CONTROLLER, DOOR_INNER_SIDE)
local door_outer = Door.new(DOOR_OUTER_CONTROLLER, DOOR_OUTER_SIDE)

local door_inner_lock = LOCK_INNER_READER and RsReader.new(LOCK_INNER_READER, LOCK_INNER_SIDE)
local door_outer_lock = LOCK_OUTER_READER and RsReader.new(LOCK_OUTER_READER, LOCK_OUTER_SIDE)

local monitor_chamber = Monitor.new(MONITOR_CHAMBER)
local monitor_inner = Monitor.new(MONITOR_INNER)
local monitor_outer = Monitor.new(MONITOR_OUTER)

-- gui
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
-- remaining duration for which to keep the current state [s]
local keep_state = 0.0
-- total duration for which to keep the current state [s]
local keep_state_total = 0.0

local function inner_request_open()
  desired_state = States.INNER_OPEN
end

local function outer_request_open()
  desired_state = States.OUTER_OPEN
end

local door_inner_ui = DoorUi.new(gui_inner, {
  room_number = ROOM_INNER_NUMBER,
  room_name = ROOM_INNER_NAME,
  room_hazard = ROOM_INNER_HAZARD,
  lock_level = door_inner_lock and LOCK_INNER_LEVEL,
  request_open = inner_request_open
})

local door_outer_ui = DoorUi.new(gui_outer, {
  room_number = ROOM_OUTER_NUMBER,
  room_name = ROOM_OUTER_NAME,
  room_hazard = ROOM_OUTER_HAZARD,
  lock_level = door_outer_lock and LOCK_OUTER_LEVEL,
  request_open = outer_request_open
})

local chamber_ui = ChamberUi.new(gui_chamber, {
  name = ROOM_OUTER_NAME,
  inner_request_open = inner_request_open,
  outer_request_open = outer_request_open
})

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

-- mapping state -> chamber state
local chamber_states = {
  [States.INNER_OPEN] = ChamberUi.get_states().OPEN,
  [States.INNER_TRANSITION] = ChamberUi.get_states().BUSY,
  [States.INNER_CLOSED] = ChamberUi.get_states().CLOSED,
  [States.DECONTAMINATION] = ChamberUi.get_states().DECON,
  [States.OUTER_CLOSED] = ChamberUi.get_states().CLOSED,
  [States.OUTER_TRANSITION] = ChamberUi.get_states().BUSY,
  [States.OUTER_OPEN] = ChamberUi.get_states().OPEN
}

-- locks
local inner_unlocked_for = 0.0
local outer_unlocked_for = 0.0

-- last value of clock to get deltaT
local last_clock = os.clock()

local duration = {
  [States.INNER_OPEN] = DOOR_OPEN_DURATION,
  [States.INNER_TRANSITION] = DOOR_TRANSITION_DURATION,
  [States.DECONTAMINATION] = DECON_DURATION,
  [States.OUTER_TRANSITION] = DOOR_TRANSITION_DURATION,
  [States.OUTER_OPEN] = DOOR_OPEN_DURATION
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

local function update(delta_t)
  if keep_state > 0 then
    keep_state = keep_state - delta_t
    chamber_ui:set_progress((keep_state_total - keep_state) / keep_state_total * 100)
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
    keep_state_total = duration[t.state] or 0

    door_inner_ui:set_state(inner_door_states[state])
    door_outer_ui:set_state(outer_door_states[state])
    chamber_ui:set_state(chamber_states[state])
    chamber_ui:set_progress(0)
  end

  if door_inner_lock then
    if inner_unlocked_for > 0 then
      inner_unlocked_for = inner_unlocked_for - delta_t
    elseif not door_inner_ui:get_locked() then
      door_inner_ui:set_locked(true)
    end

    if door_inner_lock:is_on() then
      inner_unlocked_for = LOCK_UNLOCK_DURATION
      door_inner_ui:set_locked(false)
    end
  end

  if door_outer_lock then
    if outer_unlocked_for > 0 then
      outer_unlocked_for = outer_unlocked_for - delta_t
    elseif not door_outer_ui:get_locked() then
      door_outer_ui:set_locked(true)
    end

    if door_outer_lock:is_on() then
      outer_unlocked_for = LOCK_UNLOCK_DURATION
      door_outer_ui:set_locked(false)
    end
  end
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
