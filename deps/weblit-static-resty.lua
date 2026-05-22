--[[lit-meta
  name = "creationix/weblit-static"
  version = "2.0.0"
  dependencies = {
    "creationix/mime@2.0.0",
    "creationix/coro-fs@2.0.0",
  }
  description = "A weblit middleware for serving static files from disk or bundle."
  tags = {"weblit", "middleware", "static"}
  license = "MIT"
  author = { name = "Tim Caswell" }
  homepage = "https://github.com/creationix/weblit/blob/master/libs/weblit-auto-headers.lua"
]]

local getType       = require("mime").getType
local jsonStringify = require('json').stringify
local makeChroot    = require('coro-fs').chroot
local md5           = require("md5")

-- local template = require "resty.template"
-- local html = require "resty.template.html"

local aspect        = require("aspect.template").new({
    -- debug       = true,
    -- cache       = false,
})

local filters       = require("aspect.filters")
local funcs         = require("aspect.funcs")


filters.add("shortcodes", {
    input = "string", -- input value type
    output = "string", -- output value type
    args = {
        [1] = {name = "arg1", type = "string"}, 
    }
}, function (v, arg1) 
  return arg1
end)

filters.add("json_decode", {
    input = "string", -- input value type
    output = "json", -- output value type
    args = {
        [1] = {name = "arg1", type = "string"}, 
    }
}, function (v, arg1) 
  return arg1
end)

filters.add("md5", {
    input = "string", -- input value type
    output = "string", -- output value type
    args = {
        [1] = {name = "arg1", type = "string"}, 
    }
}, function (v, arg1) 
  return md5.sumhexa(arg1)
end)

funcs.add("addJs", {
    args = {
        [1] = {name = "arg1", type = "string"},
    }
}, function (__, args) 
  p(args)
  return string.gsub(args[1], "theme:////assets(.+)", "<script type=\"text/javascript\" src=\"%1\"></script>")
end)

funcs.add("addCss", {
    args = {
        [1] = {name = "arg1", type = "string"},
    }
}, function (__, arg1) 
  p(arg1)
  return string.match(arg1, "theme:////assets(.+)", "<link rel=\"stylesheet\" href=\"%1\">")
end)

funcs.add("url", {
    args = {
        [1] = {name = "arg1", type = "string"},
    }
}, function (__, arg1) 
  p(arg1)
  return arg1
end)

-- Lua Resty specific setup
-- Disable template caching
-- template.caching(false)
-- Disable print rendering - rendering to a string output
-- template.print = function(s)
-- 	return s
-- end

return function (rootPath, datasrc)

  local fs = makeChroot(rootPath)
  aspect.loader = require("aspect.loader.filesystem").new( "/mnt/f/dev/web/luvit-seer/"..rootPath )

  return function (req, res, go)
    if req.method ~= "GET" then return go() end
    local path = (req.params and req.params.path) or req.path
    path = path:match("^[^?#]*")
    if path:byte(1) == 47 then
      path = path:sub(2)
    end
    local stat = fs.stat(path)
    if not stat then return go() end

    local function renderFile()

      res.code = 200
      res.headers["Content-Type"] = getType(path)
      local output, err = aspect:render(path, datasrc)
      res.body = output.result
      return 
    end

    local function renderDirectory()
      if req.path:byte(-1) ~= 47 then
        res.code = 301
        res.headers.Location = req.path .. '/'
        return
      end
      local files = {}
      for entry in fs.scandir(path) do
        if entry.name == "index.html" and entry.type == "file" then
          path = (#path > 0 and path .. "/" or "") .. "index.html"
          return renderFile()
        end
        files[#files + 1] = entry
        entry.url = "http://" .. req.headers.host .. req.path .. entry.name
      end
      local body = jsonStringify(files) .. "\n"
      res.code = 200
      res.headers["Content-Type"] = "application/json"
      res.body = aspect:render(body, datasrc)
      return
    end

    if stat.type == "directory" then
      return renderDirectory()
    elseif stat.type == "file" then
      if req.path:byte(-1) == 47 then
        res.code = 301
        res.headers.Location = req.path:match("^(.*[^/])/+$")
        return
      end
      return renderFile()
    end
  end
end
