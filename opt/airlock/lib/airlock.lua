local Chamber = require "airlock.lib.chamber"
local Door = require "airlock.lib.door"

local Pns = require "pns.client"

local Table = require "mb.algorithm.table"
local PrefixedLogger = require "mb.log.prefixed_logger"
local VOID_LOGGER = require "mb.log.void_logger"

local GuiH = require "GuiH"

--- Execution parameters
---@class ExecutionParameters
---@field runtime function? Main runtime. If defined and its execution ends, whole execution ends.
---@field on_event function? On UI event callback.
---@field before_draw function? Callback called right before UI drawing.
---@field after_draw function? Callback called right after UI drawing.

--- Asynchronous task parameters
---@class AsyncParameters
---@field fn function Function that should run asynchronously.
---@field delay number? How long should be the task execution delayed.
---@field error_flag boolean? If set, error inside task causes exception.
---@field debug boolean? If set, error and state logging are enabled.

--- Airlock
---@class Airlock
---@field private _config Config Config.
---@field private _chamber Chamber Chamber controller.
---@field private _inner Door Inner door controller.
---@field private _outer Door Outer door controller.
---@field private _last_open number Side which was last open.
---@field private _log Logger Logger.
---@field private _terminate boolean If set airlock will terminate.
local Airlock = {
  --- Configuration file.
  CONFIG_FILE = "/etc/airlock.cfg",
  --- Default configuration file.
  DEFAULT_CONFIG_FILE = "/opt/airlock/default_config.cfg",
  --- Airlock sides.
  SIDES = {
    INNER = 0,
    OUTER = 1
  }
}
Airlock.__index = Airlock

--- Master config.
---@class Config
---@field pns PnsConfig PNS configuration.
---@field chamber ChamberConfig Chamber configuration.
---@field inner SideConfig Inner side configuration.
---@field outer SideConfig Outer side configuration.

--- PNS config.
---@class PnsConfig
---@field enabled boolean If set PNS will be used.
---@field prefix string? Prefix applied to all symbolic names.

--- Airlock creation parameters.
---@class AirlockCreationParams
---@field log Logger? Logger to use.

--- Constructor
---@param params AirlockCreationParams
function Airlock.new(params)
  local self = setmetatable({}, Airlock)

  self._log = PrefixedLogger.new(params.log or VOID_LOGGER, "[airlock]")
  self._log:trace("Creating new airlock.")

  local config = {}

  -- read default config
  local default_config_file = fs.open(Airlock.DEFAULT_CONFIG_FILE, "r")
  if default_config_file then
    config = textutils.unserialise(default_config_file.readAll())
  else
    self._log:warning("Default config file  \"" .. Airlock.DEFAULT_CONFIG_FILE .. "\" could not be read.")
  end

  local config_file = fs.open(Airlock.CONFIG_FILE, "r")
  if config_file then
    config = Table.merge(config, textutils.unserialise(config_file.readAll()))
  else
    self._log:warning("Config file \"" .. Airlock.CONFIG_FILE .. "\" could not be read.")
  end

  self._config = config

  if self._config.pns.enabled then
    self._log:debug("PNS enabled.")
    self:apply_pns()
  end

  self:init()

  self._log:trace("Airlock created.")

  return self
end

--- Apply PNS on names.
---@private
function Airlock:apply_pns()
  self._log:trace("Applying PNS.")

  self._log:debug("Starting RedNet.")
  peripheral.find("modem", rednet.open)

  self._log:trace("Creating PNS client.")
  local pns = Pns.new{}

  local function translate(config)
    self._log:trace(("Translating %s."):format(config.device))
    local symbolic_name = config.device
    if self._config.pns.prefix then
      symbolic_name = self._config.pns.prefix .. "." .. symbolic_name
    end

    config.device = pns:look_up(self._config.pns.prefix .. "." .. config.device)
    self._log:trace(("Got %s."):format(config.device))
  end

  translate(self._config.chamber.decontamination.device)
  translate(self._config.chamber.panel.device)
  translate(self._config.inner.door.device)
  translate(self._config.inner.lock.device)
  translate(self._config.inner.panel.device)
  translate(self._config.outer.door.device)
  translate(self._config.outer.lock.device)
  translate(self._config.outer.panel.device)

  if self._config.inner.lock.device == "" then
    self._config.inner.lock.device = nil
  end

  if self._config.outer.lock.device == "" then
    self._config.outer.lock.device = nil
  end

  self._log:trace("All PNS names translated.")
  self._log:debug("Stopping RedNet.")
  rednet.close()
end

--- Init devices software.
---@private
function Airlock:init()
  self._log:trace("Device initialization started.")

  self._chamber = Chamber.new{
    config = self._config.chamber,
    log = PrefixedLogger.new(self._log, "[chamber]"),
    inner_request_open = function () self:inner_request_open() end,
    outer_request_open = function () self:outer_request_open() end,
    ui = GuiH
  }

  self._inner = Door.new{
    config = self._config.inner,
    log = PrefixedLogger.new(self._log, "[inner]"),
    request_open = function () self:inner_request_open() end,
    ui = GuiH
  }

  self._outer = Door.new{
    config = self._config.outer,
    log = PrefixedLogger.new(self._log, "[outer]"),
    request_open = function () self:outer_request_open() end,
    ui = GuiH,
  }

  self._log:trace("Device initialization done.")
end

--- Init hardware.
---@private
function Airlock:initialize()
  self._log:debug("Airlock initialization.")
  self._inner:initialize()
  self._chamber:initialize()
  self._outer:initialize()
  self._log:trace("Airlock initialization done.")
end

--- Main loop.
---@private
function Airlock:main_loop()
  local last_clock = os.clock()

  self._log:trace(("Main loop started @ %f."):format(last_clock))

  self._terminate = false
  while not self._terminate do
    local clock = os.clock()
    self._log:trace(("Tick @ %f."):format(clock))
    self:update(clock - last_clock)
    last_clock = clock

    -- limit to 4 Hz
    os.sleep(0.25)
  end

  self._log:trace(("Main loop ended @ %f."):format(os.clock()))
end

--- Update.
---@private
---@param delta_t number Time difference since last update. [s]
function Airlock:update(delta_t)
  self._log:trace(("Airlock update with delta T %f."):format(delta_t))
  self._inner:update(delta_t)
  self._outer:update(delta_t)
  self._log:trace("Airlock updated.")
end

--- Run airlock main loop.
---@param ... ... Asynchronous tasks.
function Airlock:run(...)
  self._log:info("Starting airlock.")
  self:initialize()

  self._chamber:async{ fn = function() self._inner:execute{} end }
  self._chamber:async{ fn = function() self._outer:execute{} end }

  for _, task in pairs({...}) do
    self._chamber:async{ fn = function() task() end }
  end

  self._chamber:execute{ runtime = function() self:main_loop() end }

  self._log:info("Airlock stopped.")
end

--- Request opening of inner doors.
---@private
function Airlock:inner_request_open()
  self._log:debug("Inner open requested.")
  self._chamber:async{
    fn = function()
      self._log:trace("Suspend all.")
      self._chamber:suspend()
      self._inner:suspend()
      self._outer:suspend()

      if self._last_open ~= Airlock.SIDES.INNER and (self._config.chamber.decontamination.direction == "out-in" or self._config.chamber.decontamination.direction == "both") then
        self._log:trace(("Decontamination will take place as \"%s\" strategy is used."):format(self._config.chamber.decontamination.direction))
        self._chamber:decontaminate()
      end

      self._log:trace("Door procedure.")
      self._inner:open()
      self._last_open = Airlock.SIDES.INNER

      self._log:trace("Unsuspend all.")
      self._chamber:resume()
      self._inner:resume()
      self._outer:resume()
    end
  }
end

--- Request opening of outer doors.
---@private
function Airlock:outer_request_open()
  self._log:debug("Outer open requested.")
  self._chamber:async{
    fn = function()
      self._log:trace("Suspend all.")
      self._chamber:suspend()
      self._inner:suspend()
      self._outer:suspend()

      if self._last_open ~= Airlock.SIDES.OUTER and (self._config.chamber.decontamination.direction == "in-out" or self._config.chamber.decontamination.direction == "both") then
        self._log:trace(("Decontamination will take place as \"%s\" strategy is used."):format(self._config.chamber.decontamination.direction))
        self._chamber:decontaminate()
      end

      self._log:trace("Door procedure.")
      self._outer:open()
      self._last_open = Airlock.SIDES.OUTER

      self._log:trace("Unsuspend all.")
      self._chamber:resume()
      self._inner:resume()
      self._outer:resume()
    end
  }
end

return Airlock
