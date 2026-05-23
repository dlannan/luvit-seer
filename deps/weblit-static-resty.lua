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
local pathJoin      = require('luvi').path.join

-- local template = require "resty.template"
-- local html = require "resty.template.html"

local aspect        = require("aspect.template").new({
    -- debug       = true,
    -- cache       = false,
})

require("aspect.custom_filters")
require("aspect.custom_functions")

-- Lua Resty specific setup
-- Disable template caching
-- template.caching(false)
-- Disable print rendering - rendering to a string output
-- template.print = function(s)
-- 	return s
-- end

return function (rootPath, datasrc)

  local fs = makeChroot(rootPath)
  aspect.loader = require("aspect.loader.filesystem").new( pathJoin(_G.PROJECT_FOLDER, rootPath) )

  return function(req, res, go)
    if req.method ~= "GET" then return go() end
    local path = (req.params and req.params.path) or req.path
    path = path:match("^[^?#]*")
    if path:byte(1) == 47 then
      path = path:sub(2)
    end
    local stat = fs.stat(path)
    if not stat or stat.type == "directory" then 
      stat = fs.stat(path..".twig")
      if not stat then 
        stat = fs.stat(path..".html.twig")
        if not stat then return go() end
      end
    end

    local function renderFile()

      res.code = 200
      res.headers["Content-Type"] = getType(path)
      local output = ""
      if(string.match(path, ".+%.twig$")) then 
        output, err = aspect:render(path, datasrc)
      elseif(string.match(path, ".+%.html$")) then 
        output, err = aspect:render(path..".twig", datasrc)
      else
        output, err = aspect:render(path..".html.twig", datasrc)
        res.headers["Content-Type"] = getType("test.html")
      end
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

    -- if stat.type == "directory" then
    --   return renderDirectory()
    if stat.type == "file" then
      if req.path:byte(-1) == 47 then
        res.code = 301
        res.headers.Location = req.path:match("^(.*[^/])/+$")
        return
      end
      return renderFile()
    end
  end
end
