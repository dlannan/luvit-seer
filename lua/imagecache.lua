--[[lit-meta
  name = "kakutai/imagecache"
  version = "1.0.0"
  dependencies = {
    "creationix/mime@2.0.0",
    "creationix/coro-fs@2.0.0",
  }
  description = "A weblit middleware for serving image cached files from disk or bundle."
  tags = {"weblit", "middleware", "imagecache"}
  license = "MIT"
  author = { name = "David Lannan" }
  homepage = ""
]]

local getType = require("mime").getType
local jsonStringify = require('json').stringify
local makeChroot = require('coro-fs').chroot
local pathJoin = require('luvi').path.join
local pathing = require('path')

local pathroot = _G.PROJECT.."/userassets/images"

return function (rootPath)

  local fs = makeChroot(rootPath)

  return function (req, res, go)
    if req.method ~= "GET" then return go() end
    local path = (req.params and req.params.path) or req.path
    path = path:match("^[^?#]*")
    if path:byte(1) == 47 then
      path = path:sub(2)
    end

    local imgsize = 'L'
    local imgpath = path

    local imgbasename = pathing.basename(imgpath)
    -- Get the path by removing the filename from it.
    local ps, pe = string.find(imgpath, imgbasename, 1, true)
    if ps == nil then return go() end
    local imgbasepath = ""
    if ps > 1 then imgbasepath = string.sub(imgpath, 1, ps-2) end

    -- if the file path startswith L__, M__, H__, V__ then a specific image was requested
    local s,e = string.find(imgbasename, '[LMHV]__')
    -- Have a match
    if s == 1 then
        imgsize = string.sub(imgbasename, 1, 1)
        imgbasename = string.sub(imgbasename, 4, -1)
    end
        
    local fullpath = pathJoin(pathroot, pathJoin(imgbasepath, imgbasename))
    local stat = fs.stat(fullpath)
    if not stat then return go() end

    local function renderFile()
        -- All image userasset files are loaded through the cache
        local cache = _G.USERASSETS["imagecache"]
        if cache[imgbasename] ~= nil then
            local cachefile = cache[imgbasename][imgsize]  

            local filedata = fs.readFile(cachefile)
            local body = assert(filedata)
            res.code = 200

            local ext = string.lower(pathing.extname(req.params.path))
            local deftype = "image/jpeg"
            if ext == ".png" then deftype = "image/png" end
            res.headers["Content-Type"] = deftype
            res.body = body
            return
        else
            return go()
        end
    end

--    local function renderDirectory()
--      if req.path:byte(-1) ~= 47 then
--        res.code = 301
--        res.headers.Location = req.path .. '/'
--        return
--      end
--      local files = {}
--      for entry in fs.scandir(path) do
--        if entry.name == "index.html" and entry.type == "file" then
--          path = (#path > 0 and path .. "/" or "") .. "index.html"
--          return renderFile()
--        end
--        files[#files + 1] = entry
--        entry.url = "http://" .. req.headers.host .. req.path .. entry.name
--      end
--      local body = jsonStringify(files) .. "\n"
--      res.code = 200
--      res.headers["Content-Type"] = "application/json"
--      res.body = body
--      return
--    end

--    if stat.type == "directory" then
--      return renderDirectory()
    if stat.type == "file" then
      return renderFile()
    end
  end
end
