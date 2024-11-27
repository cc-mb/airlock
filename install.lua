local REPO = "https://raw.githubusercontent.com/cc-mb/airlock/refs/heads"
local BRANCH = "master"

local TARGET_DIR = "/usr/bin"
local FILES = {
  "mb/airlock/ui/chamber.lua",
  "mb/airlock/ui/door.lua",
  "mb/airlock/.settings",
  "mb/airlock/init.lua"
}

for _, file in ipairs(FILES) do
  local local_file = "/" .. fs.combine(TARGET_DIR, file)
  local remote_file = REPO .. "/" .. fs.combine(BRANCH, file)
  shell.run("wget " .. remote_file .. " " .. local_file)
end
