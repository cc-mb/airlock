local Table = require "mb.algorithm.table"

--- UI for the inner and outer door.
---@class ChamberUi
---@field private _state number Current state.
---@field private _ui table GuiH instance.
local ChamberUi = {}
ChamberUi.__index = ChamberUi

local States = {
  OPEN = 1,
  BUSY = 2,
  CLOSED = 3,
  DECON = 4
}

--- Door UI creation parameters.
---@class ChamberUiParams
---@field name string? Airlock name shown.
---@field inner_request_open function? Callback used to request inner door opening.
---@field outer_request_open function? Callback used to request outer door opening.
local ChamberUiParams = {}

--- Constructor
---@param ui table GuiH instance.
---@param params ChamberUiParams? Chamber UI creation parameters.
function ChamberUi.new(ui, params)
  local self = setmetatable({}, ChamberUi)

  self._state = States.CLOSED
  self._ui = ui

  self:init_ui(params or {})
  
  return self
end

--- Returns all available states.
function ChamberUi.get_states()
  return States
end

--- Return current state.
function ChamberUi:get_state()
  return self._state
end

--- Set new state.
function ChamberUi:set_state(state)
  self._state = state
  self:update_ui()
end

--- Return current progress.
function ChamberUi:get_progress()
  return self._ui.elements.progressbar["decon_bar"].value
end

--- Set new progress.
function ChamberUi:set_progress(progress)
  self._ui.elements.progressbar["decon_bar"].value = progress
end

--- Init UI
---@param params ChamberUiParams Chamber UI creation parameters.
---@private
function ChamberUi:init_ui(params)
  self._ui.new.rectangle{
    name = "upper_area",
    graphic_order = 0,
    x = 1, y = 1,
    width = self._ui.width, height = 3,
    color = colors.white
  }

  self._ui.new.rectangle{
    name = "lower_area",
    graphic_order = 0,
    x = 1, y = 4,
    width = self._ui.width, height = self._ui.height - 3,
    color = colors.yellow
  }

  if params.name then
    self._ui.new.text{
      name = "room_name",
      text = self._ui.text{
        text = params.name,
        x = 1, y = 1,
        centered = true,
        transparent = true,
        fg = colors.black,
        width = self._ui.width, height = 3
      }
    }
  end

  self._ui.new.button{
    name = "inner_button",
    x = 3, y = 5,
    width = (self._ui.width / 2) - 3, height = self._ui.height - 5,
    text = self._ui.text{
      text = "OPEN",
      centered = true,
      transparent = true,
      fg = colors.white
    },
    background_color = colors.green,
    on_click = params.inner_request_open
  }

  self._ui.new.button{
    name = "outer_button",
    x = (self._ui.width / 2) + 2, y = 5,
    width = (self._ui.width / 2) - 3, height = self._ui.height - 5,
    text = self._ui.text{
      text = "OPEN",
      centered = true,
      transparent = true,
      fg = colors.white
    },
    background_color = colors.green,
    on_click = params.outer_request_open
  }

  self._ui.new.progressbar{
    name = "decon_bar",
    visible = false,
    direction = "left-right",
    value = 0.0,
    x = 3, y = 5,
    width = self._ui.width - 4, height = self._ui.height - 5,
    bg = colors.black,
    fg = colors.blue
  }

  self._ui.new.text{
    name = "decon",
    visible = false,
    graphic_order = 2,
    text = self._ui.text{
      text = "DECONTAMINATION",
      x = 3, y = 5,
      centered = true,
      transparent = true,
      fg = colors.white,
      width = self._ui.width - 4, height = self._ui.height - 5
    }
  }

  self:update_ui()
end

--- Update UI based on the state.
---@private
function ChamberUi:update_ui()
  local active_button_props = {
    fg = colors.white,
    bg = colors.green,
    active = true
  }

  local inactive_button_props = {
    fg = colors.lightGray,
    bg = colors.gray,
    active = false
  }

  local BUTTON_PROPS = {
    [States.OPEN] = inactive_button_props,
    [States.BUSY] = inactive_button_props,
    [States.CLOSED] = active_button_props,
    [States.DECON] = inactive_button_props
  }

  local props = BUTTON_PROPS[self._state]

  local inner_button = self._ui.elements.button["inner_button"]
  inner_button.visible = self._state ~= States.DECON
  inner_button.text.fg = props.fg
  inner_button.background_color = props.bg
  inner_button.reactive = props.active

  local outer_button = self._ui.elements.button["outer_button"]
  outer_button.visible = self._state ~= States.DECON
  outer_button.text.fg = props.fg
  outer_button.background_color = props.bg
  outer_button.reactive = props.active

  local decon_bar = self._ui.elements.progressbar["decon_bar"]
  decon_bar.visible = self._state == States.DECON

  local decon = self._ui.elements.text["decon"]
  decon.visible = self._state == States.DECON
end

return ChamberUi