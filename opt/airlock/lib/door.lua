local Ui = require "airlock.lib.ui.door"

local DoorDevice = require "mb.peripheral.door"
local RsReader = require "mb.peripheral.rs_reader"

--- Door controller.
---@class Door
---@field private _config SideConfig Configuration.
---@field private _door DoorDevice Door controller.
---@field private _lock RsReader? Door lock.
---@field private _log Logger Logger.
---@field private _ui DoorUi UI.
---@field private _unlocked_for number Remaining time the door is unlocked. [s]
local Door = {}
Door.__index = Door

--- Side config.
---@class SideConfig
---@field door DoorConfig Door configuration.
---@field lock LockConfig Lock configuration.
---@field panel PanelConfig Panel configuration.

--- Door config.
---@class DoorConfig
---@field device string Door controller name.
---@field device_side string Door controller side.
---@field keep_open_duration number How long will be the door kept open. [s]
---@field transition_duration number How long does it take to open/close the door. [s]

--- Lock config.
--- In device is defined, all of them must be defined.
---@class LockConfig
---@field device string? Optional. Lock controller name.
---@field device_side string? Optional. Lock controller side.
---@field level number? Optional. Lock level displayed on panel.
---@field unlock_duration number? Optional. How long should door be unlocked. [s]

--- Door creation parameters.
---@class DoorCreationParams
---@field config SideConfig Side configuration.
---@field log Logger Logger.
---@field request_open function Callback used to request door opening.
---@field ui table GuiH

--- Constructor
---@param params DoorCreationParams Door creation parameters.
function Door.new(params)
  local self = setmetatable({}, Door)

  self._config = params.config
  self._log = params.log
  self._log:trace("Door controller creation.")

  self._door = DoorDevice.new{
    name = self._config.door.device,
    side = self._config.door.device_side
  }

  self._lock = self._config.lock.device and RsReader.new{
    name = self._config.lock.device,
    side = self._config.lock.device_side
  }

  if not self._lock then
    self._log:info("No lock.")
  end

  self._ui = Ui.new{
    panel = self._config.panel,
    lock_level = self._config.lock.level,
    request_open = params.request_open,
    ui = params.ui
  }

  self._log:trace("Door controller created.")

  return self
end

--- Initialization of HW devices to default state.
function Door:initialize()
  self._log:debug("Door initialization sequence.")
  self._door:open()
  os.sleep(self._config.door.transition_duration)
  self._door:close()
  os.sleep(self._config.door.transition_duration)
  self._log:trace("Door initialization sequence complete.")
end

--- Start main loop.
---@param params ExecutionParameters
function Door:execute(params)
  self._log:debug("Execution started.")
  self._ui:execute(params)
  self._log:debug("Execution ended.")
end

--- Schedule async task.
---@param params AsyncParameters
function Door:async(params)
  self._log:trace("Task scheduled.")
  self._ui:async(params)
end

--- Update
---@param delta_t number Time difference between ticks. [s]
function Door:update(delta_t)
  self._log:trace("Door update.")

  if self._lock then
    if self._lock:is_on() then
      if self._unlocked_for <= 0 then
        self._log:debug("Locking.")
        self._unlocked_for = self._config.lock.unlock_duration
        self._ui:set_locked(false)
      end
    elseif self._unlocked_for > 0 then
      self._log:trace("Lock timer decremented.")
      self._unlocked_for = self._unlocked_for - delta_t
    elseif not self._ui:get_locked() then
      self._log:debug("Unlocking.")
      self._ui:set_locked(true)
    end
  end
  self._log:trace("Door updated.")
end

--- Run open procedure. Blocking call until procedure is done.
function Door:open()
  self._log:info("Door open procedure running.")

  self._log:debug("Opening door.")
  self._door:open()
  os.sleep(self._config.door.transition_duration)

  self._log:debug("Door open.")
  os.sleep(self._config.door.keep_open_duration)

  self._log:debug("Closing door.")
  self._door:close()
  os.sleep(self._config.door.transition_duration)

  self._log:info("Door closed.")
end

--- Return whether suspended.
function Door:is_suspended()
  return self._ui:is_suspended()
end

--- Suspend controller.
function Door:suspend()
  self._log:debug("Door control suspended.")
  self._ui:suspend()
end

--- Unsuspend controller.
function Door:resume()
  self._log:debug("Door control unsuspended.")
  self._ui:resume()
end

return Door