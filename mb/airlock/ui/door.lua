local Table = require "mb.algorithm.table"

--- UI for the inner and outer door.
---@class DoorUi
---@field private _state number Current state.
---@field private _ui table GuiH instance.
local DoorUi = {}
DoorUi.__index = DoorUi

local States = {
  LOCKED = 0,
  OPEN = 1,
  BUSY = 2,
  CLOSED = 3,
  COUNT = 4
}

--- Constructor
---@param ui table GuiH instance.
---@param name string? Room name.
---@param request_open function Callback used to request door opening.
function DoorUi.new(ui, name, request_open)
  local self = setmetatable({}, DoorUi)

  self._state = States.LOCKED
  self._ui = ui

  self:init_ui(name or "", request_open)
  
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
  if self._state ~= state and state >= 0 and state < States.COUNT then
    self:update_ui(self._state, state)
    self._state = state
  end
end

--- Init UI
---@param name string Room name.
---@param request_open function Callback used to request door opening.
---@private
function DoorUi:init_ui(name, request_open)
  self._elements = {}
  if name then
    self._elements._name = self._ui.new.text(
      self._ui.text{
        text = name,
        x = 1, y = 1,
        centered = true,
        transparent = true,
        width = self._ui.width,
        height = 3
      }
    )
  end

  local common_button_properties = {
    x = 3, y = 6,
    width = self._ui.width - 4, height = self._ui.height - 7,
  }

  local common_text_properties = {
    centered = true,
    transparent = true,
    fg = colors.white
  }

  local locked_button_properties = Table.merge(common_button_properties, {
    text = self._ui.text(Table.merge(common_text_properties, { 
      text = "LOCKED"
    })),
    background_color = colors.red
  })

  local open_button_properties = Table.merge(common_button_properties, {
    text = self._ui.text(Table.merge(common_text_properties, {
      text = "OPEN"
    })),
    background_color = colors.blue
  })

  local busy_button_properties = Table.merge(common_button_properties, {
    text = self._ui.text(Table.merge(common_text_properties, {
      text = "BUSY...",
      fg = colors.lightGray
    })),
    background_color = colors.blue
  })

  local closed_button_properties = Table.merge(common_button_properties, {
    text = self._ui.text(Table.merge(common_text_properties, {
      text = "OPEN"
    })),
    background_color = colors.green,
    on_click = function () request_open(); print("STFU") end
  })

  self._elements._buttons = {
    [States.LOCKED] = self._ui.new.button(locked_button_properties).cut(),
    [States.OPEN] = self._ui.new.button(open_button_properties).cut(),
    [States.BUSY] = self._ui.new.button(busy_button_properties).cut(),
    [States.CLOSED] = self._ui.new.button(closed_button_properties).cut()
  }

  self:update_ui(nil, self._state)
end

--- Update UI based on the state.
---@param from number? Original state. 
---@param to number New state.
---@private
function DoorUi:update_ui(from, to)
  if from then
    self._elements._buttons[from] = self._elements._buttons[from].cut()
  end

  self._elements._buttons[to] = self._elements._buttons[to].parse()
end

return DoorUi