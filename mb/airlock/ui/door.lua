--- UI for the inner and outer door.
---@class DoorUi
---@field private _state number Current state.
---@field private _ui table GuiH instance.
local DoorUi = {}
DoorUi.__index = DoorUi

local States = {
  OPEN = 0,
  LOCKED = 1,
  CLOSED = 2,
  COUNT = 3
}

--- Constructor
---@param ui table GuiH instance.
---@param name string? Room name.
---@param request_open function Callback used to request door opening.
function DoorUi.new(ui, name, request_open)
  local self = setmetatable({}, DoorUi)

  self._state = States.CLOSED
  self._ui = ui

  self:init_ui(name or "", request_open)
  
  return self
end

--- Returns all available states.
function DoorUi:get_states()
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
  if self._name then
    self._elements._name = self._ui.new.text(
      self._ui.text{
        text = self._name,
        x = 0, y = 0,
        centered = true,
        transparent = true,
        height = 3
      }
    )
  end

  local merge = require("GuiH").apis.general.tables.merge

  local common_button_properties = {
    x = 2, y = 5,
    width = self._ui.width - 4, height = self._ui.height - 7,
  }

  local open_button_properties =   merge(common_button_properties, {
    text = self._ui.text{
      text = "OPEN",
      centered = true,
      transparent = true,
      fg = colors.white
    },
    background_color = colors.lime
  })

  local locked_button_properties = merge(common_button_properties, {
    text = self._ui.text{
      text = "🔒",
      centered = true,
      transparent = true,
      fg = colors.white
    },
    background_color = colors.red
  })

  local closed_button_properties = merge(common_button_properties, {
    text = self._ui.text{
      text = "OPEN",
      centered = true,
      transparent = true,
      fg = colors.lightGray
    },
    background_color = colors.green,
    on_click = request_open
  })

  self._elements._buttons = {
    [States.OPEN] = self._ui.new.button(open_button_properties).cut(),
    [States.LOCKED] = self._ui.new.button(locked_button_properties).cut(),
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
    self._elements._buttons = self._elements._buttons[from].cut()
  end

  self._elements._buttons = self._elements._buttons[to].parse()
end

return DoorUi