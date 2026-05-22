
local getType = require("mime").getType
local makeChroot = require('coro-fs').chroot

local sha1 = require('sha1')
local querystring = require('querystring')

local template = require "resty.template"
local html = require "resty.template.html"

-- Lua Resty specific setup
template.caching(false)
-- Disable print rendering - rendering to a string output
template.print = function(s)
	return s
end

--local fs = makeChroot(rootPath)
return function (req, res, go)

    -- Only care about posts
    if req.method ~= "POST" then return go() end

    local path = (req.params and req.params.path) or req.path
    path = path:match("^[^?#]*")
    if path:byte(1) == 47 then
      path = path:sub(2)
    end

    local htmlpage = _G.HTMLPAGES.newpage()
    local datasource = _G.LOCALEDITING

    -- print("Output body:", path)

    res.code = 200
    res.headers["Content-Type"] = "text/html"
    res.body = "/admin/"..htmlpage
    return
end
