local REPO = "https://raw.githubusercontent.com/cc-mb/airlock/refs/heads"
local BRANCH = "master"

local TARGET_DIR = "/usr/bin"
local FILES = {
  "mb/airlock/ui/door.lua",
  "mb/airlock/init.lua"
}

for _, file in ipairs(FILES) do
  local local_file = "/" .. fs.combine(TARGET_DIR, file)
  local remote_file = REPO .. "/" .. fs.combine(BRANCH, file)
  shell.run("wget " .. remote_file .. " " .. local_file)
end

settings.define("mb.airlock.decon", {
  description = "Controller for the decontamination mechanism. If not set the computer is used instead.",
  default = nil,
  type = "string"
})

settings.define("mb.airlock.decon_side", {
  description = "Controller side for the decontamination mechanism.",
  default = "back",
  type = "string"
})

settings.define("mb.airlock.door_inner", {
  description = "Controller for the door inside the protected area. If not set the computer is used instead.",
  default = nil,
  type = "string"
})

settings.define("mb.airlock.door_inner_side", {
    description = "Controller side for the door inside the protected area.",
    default = "back",
    type = "string"
})

settings.define("mb.airlock.door_outer", {
    description = "Controller for the door outside the protected area. If not set the computer is used instead.",
    default = nil,
    type = "string"
})

settings.define("mb.airlock.door_outer_side", {
    description = "Controller side for the door outside the protected area.",
    default = "back",
    type = "string"
})

settings.define("mb.airlock.monitor_chamber", {
    description = "Monitor inside the chamber.",
    default = "monitor",
    type = "string"
})

settings.define("mb.airlock.monitor_inner", {
    description = "Monitor inside the protected area.",
    default = "monitor",
    type = "string"
})

settings.define("mb.airlock.monitor_outer", {
    description = "Monitor outside the protected area.",
    default = "monitor",
    type = "string"
})

settings.define("mb.airlock.decon_interval", {
  description = "How long will the decontamination be turned on.",
  default = 10,
  type = "number"
})
