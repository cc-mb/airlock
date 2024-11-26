local TARGET_DIR = "/usr/bin"

local FILES = {
  "mb/airlock/"
}

for _, file in ipairs(FILES) do
  local local_file = "/" .. fs.combine(TARGET_DIR, file)
  fs.delete(local_file)
end
