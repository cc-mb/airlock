local Monitor = require "mb.peripheral.monitor"

--- UI for the chamber.
---@class ChamberUi
---@field private _in_progress boolean Flag marking the decontamination process as being in progress.
---@field private _suspended boolean Flag marking UI as suspended.
---@field private _ui table GuiH instance.
local ChamberUi = {
  NOT_IN_PROGRESS = -1
}
ChamberUi.__index = ChamberUi

--- Panel config.
---@class ChamberPanelConfig
---@field device string Panel monitor.
---@field name string? Optional. Room name shown inside chamber.

--- Chamber UI creation parameters.
---@class ChamberUiParams
---@field panel ChamberPanelConfig Panel config.
---@field left_request_open function Callback used to request left door opening.
---@field right_request_open function Callback used to request right door opening.
---@field ui table GuiH.
local ChamberUiParams = {}

--- Constructor
---@param params ChamberUiParams Chamber UI creation parameters.
function ChamberUi.new(params)
  local self = setmetatable({}, ChamberUi)

  self._in_progress = false
  self._suspended = false
  local monitor = Monitor.new{ name = params.panel.device}
  monitor.setTextScale(0.5)
  self._ui = params.ui.new(monitor)

  self:init_ui(params)
  
  return self
end

--- Return whether suspended.
function ChamberUi:is_suspended()
  return self._suspended
end

--- Suspend the UI.
function ChamberUi:suspend()
  self._suspended = true
  self:update_ui()
end

--- Unsuspend the UI.
function ChamberUi:resume()
  self._suspended = false
  self:update_ui()
end

--- Return current progress.
function ChamberUi:get_progress()
  if self._in_progress then
    return self._ui.elements.progressbar["decon_bar"].value
  else
    return ChamberUi.NOT_IN_PROGRESS
  end
end

--- Set new progress.
function ChamberUi:set_progress(progress)
  if progress == ChamberUi.NOT_IN_PROGRESS then
    self._in_progress = false
  else
    self._in_progress = true
    self._ui.elements.progressbar["decon_bar"].value = progress
  end

  self:update_ui()
end

--- Start main loop.
---@param params ExecutionParameters
function ChamberUi:execute(params)
  self._ui.execute(params.runtime, params.on_event, params.before_draw, params.after_draw)
end

--- Schedule async task.
---@param params AsyncParameters
function ChamberUi:async(params)
  self._ui.async(params.fn, params.delay, params.error_flag, params.debug)
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

  if params.panel.name then
    self._ui.new.text{
      name = "room_name",
      text = self._ui.text{
        text = params.panel.name,
        x = 1, y = 1,
        centered = true,
        transparent = true,
        fg = colors.black,
        width = self._ui.width, height = 3
      }
    }
  end

  self._ui.new.button{
    name = "left_button",
    x = 3, y = 5,
    width = (self._ui.width / 2) - 3, height = self._ui.height - 5,
    text = self._ui.text{
      text = "OPEN",
      centered = true,
      transparent = true,
      fg = colors.white
    },
    background_color = colors.green,
    on_click = params.left_request_open
  }

  self._ui.new.button{
    name = "right_button",
    x = (self._ui.width / 2) + 2, y = 5,
    width = (self._ui.width / 2) - 3, height = self._ui.height - 5,
    text = self._ui.text{
      text = "OPEN",
      centered = true,
      transparent = true,
      fg = colors.white
    },
    background_color = colors.green,
    on_click = params.right_request_open
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
  local button_props = {}
  if self._suspended then
    button_props = {
      fg = colors.lightGray,
      bg = colors.gray
    }
  else
    button_props = {
      fg = colors.white,
      bg = colors.green
    }
  end

  local left_button = self._ui.elements.button["left_button"]
  left_button.visible = not self._in_progress
  left_button.text.fg = button_props.fg
  left_button.background_color = button_props.bg
  left_button.reactive = not self._suspended

  local right_button = self._ui.elements.button["right_button"]
  right_button.visible = not self._in_progress
  right_button.text.fg = button_props.fg
  right_button.background_color = button_props.bg
  right_button.reactive = not self._suspended

  local decon_bar = self._ui.elements.progressbar["decon_bar"]
  decon_bar.visible = self._in_progress

  local decon = self._ui.elements.text["decon"]
  decon.visible = self._in_progress
end

return ChamberUi