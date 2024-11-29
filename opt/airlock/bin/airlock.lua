package.path = "/opt/?.lua;" .. package.path

local Airlock = require "airlock.lib.airlock"
local Logger = require "mb.log.handle_logger"

local airlock = Airlock.new{ log = Logger.new(io.stdout, Logger.LEVEL.INFO) }

airlock:run()
