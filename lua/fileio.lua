

local fs = require('fs')

local open = io.open

local fileio = {}

-- This belongs in a "file handling" lua script (will be used alot for redis population)
fileio.read_file = function (path)
    local file = open(path, "rb") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

fileio.read_path = function (path)
    return fs.readdirSync(path)
end

return fileio
