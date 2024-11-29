local Ui = require "airlock.lib.ui.chamber"

local RsDevice = require "mb.peripheral.rs_device"

--- Chamber controller.
---@class Chamber
---@field private _config ChamberConfig Configuration.
---@field private _decon RsDevice Decontamination controller.
---@field private _log Logger Logger.
---@field private _ui ChamberUi UI.
local Chamber = {}
Chamber.__index = Chamber

--- Chabmer config.
---@class ChamberConfig
---@field decontamination DecontaminationConfig Decontamination configuration.
---@field panel ChamberPanelConfig Panel configuration.

--- Decontamination config.
---@class DecontaminationConfig
---@field device string Decontamination controller name.
---@field device_side string Decontamination controller side.
---@field duration number Duration of decontamination process. [s]
---@field direction string Direction requiring decontamination. Valid values are "none", "in-out", "out-in" and "both".

--- Chamber creation parameters.
---@class ChamberCreationParams
---@field config ChamberConfig Chamber configuration.
---@field inner_request_open function Callback used to request inner door opening.
---@field outer_request_open function Callback used to request outer door opening.
---@field log Logger Logger.
---@field ui table GuiH

--- Constructor
---@param params ChamberCreationParams Door creation parameters.
function Chamber.new(params)
  local self = setmetatable({}, Chamber)

  self._config = params.config
  self._log = params.log
  self._log:trace("Chamber controller creation.")

  self._decon = RsDevice.new{
    name = self._config.decontamination.device,
    side = self._config.decontamination.device_side
  }

  self._ui = Ui.new{
    panel = self._config.lock,
    inner_request_open = params.inner_request_open,
    outer_request_open = params.outer_request_open,
    ui = params.ui
  }

  self._log:trace("Chamber controller created.")

  return self
end

--- Initialization of HW devices to default state.
function Chamber:initialize()
  self._log:debug("Chamber initialization sequence.")
  self._decon:set_on()
  os.sleep(self._config.decontamination.duration)
  self._door:set_off()
  self._log:trace("Chamber initialization sequence complete.")
end

--- Start main loop.
---@param params ExecutionParameters
function Chamber:execute(params)
  self._log:debug("Execution started.")
  self._ui:execute(params)
  self._log:debug("Execution ended.")
end

--- Schedule async task.
---@param params AsyncParameters
function Chamber:async(params)
  self._log:trace("Task scheduled.")
  self._ui:async(params)
end

--- Run decontamination procedure. Blocking call until procedure is done.
function Chamber:decontaminate()
  self._log:info("Chamber decontamination.")

  self._log:debug("Starting shower.")
  self._decon:set_on()

  -- update progress while waiting
  local begin = os.clock()
  while os.clock() - begin < self._config.decontamination.duration do
    local diff = os.clock() - begin
    local progress = diff / self._config.decontamination.duration * 100.0
    self._log:trace(("Progress %f."):format(progress))
    self._ui:set_progress(progress)
    -- limit to 4 Hz
    os.sleep(0.25)
  end

  self._log:debug("Stopping shower.")
  self._door:set_off()
  self._ui:set_progress(Ui.NOT_IN_PROGRESS)

  self._log:info("Chamber decontamination done.")
end

--- Return whether suspended.
function Chamber:is_suspended()
  return self._ui:is_suspended()
end

--- Suspend controller.
function Chamber:suspend()
  self._log:debug("Door control suspended.")
  self._ui:suspend()
end

--- Unsuspend controller.
function Chamber:resume()
  self._log:debug("Door control unsuspended.")
  self._ui:resume()
end

return Chamber