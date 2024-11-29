local args = {...}

shell.run("/opt/airlock/bin/airlock " .. table.concat(args, " "))
