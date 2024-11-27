local Table = require "mb.algorithm.table"

--- UI for the inner and outer door.
---@class DoorUi
---@field private _locked boolean If set controls are locked.
---@field private _request_open function? Callback used to request door opening.
---@field private _state number Current state.
---@field private _ui table GuiH instance.
local DoorUi = {}
DoorUi.__index = DoorUi

local States = {
  OPEN = 1,
  BUSY = 2,
  CLOSED = 3
}

--- Door UI creation parameters.
---@class DoorUiParams
---@field room_number number? Room number shown.
---@field room_name string? Room name shown.
---@field room_hazard string? Room hazard info shown.
---@field lock_level number? Room lock level shown.
---@field request_open function? Callback used to request door opening.
local DoorUiParams = {}

--- Constructor
---@param ui table GuiH instance.
---@param params DoorUiParams? Door UI creation parameters.
function DoorUi.new(ui, params)
  local self = setmetatable({}, DoorUi)

  self._state = States.CLOSED
  self._locked = false
  self._ui = ui

  self:init_ui(params or {})
  
  return self
end

--- Returns all available states.
function DoorUi.get_states()
  return States
end

--- Return current state.
function DoorUi:get_state()
  return self._state
end

--- Set new state.
function DoorUi:set_state(state)
  self._state = state
  self:update_ui()
end

--- Return current lock state.
function DoorUi:get_locked()
  return self._locked
end

-- Set new lock state.
function DoorUi:set_locked(locked)
  self._locked = locked
  self:update_ui()
end

--- Init UI
---@param params DoorUiParams Door UI creation parameters.
---@private
function DoorUi:init_ui(params)
  self._request_open = params.request_open

  self._ui.new.rectangle{
    name = "upper_area",
    graphic_order = 0,
    x = 1, y = 1,
    width = self._ui.width, height = 3,
    color = colors.white
  }

  self._ui.new.rectangle{
    name = "lower_area",
    graphic_order = -1,
    x = 1, y = 4,
    width = self._ui.width, height = self._ui.height - 3,
    color = colors.yellow
  }

  if params.room_number then
    self._ui.new.text{
      name = "room_number",
      text = self._ui.text{
        text = tostring(params.room_number),
        x = 1, y = 1,
        transparent = true,
        fg = colors.gray
      }
    }
  end

  if params.room_name then
    self._ui.new.text{
      name = "room_name",
      text = self._ui.text{
        text = params.room_name,
        x = 1, y = 2,
        centered = true,
        transparent = true,
        fg = colors.black,
        width = self._ui.width, height = 1
      }
    }
  end

  if params.room_hazard then
    self._ui.new.text{
      name = "room_hazard",
      text = self._ui.text{
        text = params.room_hazard,
        x = 1, y = 3,
        centered = true,
        transparent = true,
        fg = colors.red,
        width = self._ui.width, height = 1
      }
    }
  end

  if params.lock_level then
    local color = {
      [1] = { bg = colors.yellow, fg = colors.black },
      [2] = { bg = colors.orange, fg = colors.white },
      [3] = { bg = colors.red, fg = colors.white },
      [4] = { bg = colors.pink, fg = colors.black },
      [5] = { bg = colors.purple, fg = colors.white }
    }

    self._ui.new.text{
      name = "lock_level",
      text = self._ui.text{
        text = tostring(params.lock_level),
        x = self._ui.width, y = 1,
        bg = color[params.lock_level].bg,
        fg = color[params.lock_level].fg
      }
    }
  end

  self._ui.new.button{
    name = "button",
    x = 3, y = 5,
    width = self._ui.width - 4, height = self._ui.height - 5,
    text = self._ui.text{
      text = "OPEN",
      centered = true,
      transparent = true,
      fg = colors.white
    },
    background_color = colors.green
  }

  self._ui.new.rectangle{
    name = "lower_area_locked",
    visible = false,
    graphic_order = 0,
    x = 1, y = 4,
    width = self._ui.width, height = self._ui.height - 3,
    color = colors.red
  }

  self._ui.new.text{
    name = "locked",
    visible = false,
    text = self._ui.text{
      text = "LOCKED",
      x = 1, y = self._ui.height,
      centered = true,
      transparent = true,
      fg = colors.white,
      width = self._ui.width, height = 1
    }
  }

  self:update_ui()
end

--- Update UI based on the state.
---@private
function DoorUi:update_ui()
  local BUTTON_PROPS = {
    [States.OPEN] = {
      fg = colors.lightGray,
      bg = colors.gray,
      on_click = nil
    },
    [States.BUSY] = {
      fg = colors.lightGray,
      bg = colors.gray,
      on_click = nil
    },
    [States.CLOSED] = {
      fg = colors.white,
      bg = colors.green,
      on_click = self._request_open
    }
  }

  local props = BUTTON_PROPS[self._state]
  if self._locked then
    props.on_click = nil
  end

  local button = self._ui.elements.button["button"]
  button.text.fg = props.fg
  button.background_color = props.bg
  button.on_click = props.on_click

  local lower_area_locked = self._ui.elements.rectangle["lower_area_locked"]
  lower_area_locked.visible = self._locked

  local locked = self._ui.elements.text["locked"]
  locked.visible = self._locked
end

return DoorUi