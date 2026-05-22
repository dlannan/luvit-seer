
local getType = require("mime").getType
local makeChroot = require('coro-fs').chroot

local sha1 = require('sha1')
local querystring = require('querystring')

local fileio = require('fileio')
local redis = require('redis-tools')
local cmodules = require('modules')

local template = require "resty.template"
local html = require "resty.template.html"

-- Lua Resty specific setup
-- Disable template caching
template.caching(false)
-- Disable print rendering - rendering to a string output
template.print = function(s)
	return s
end

return function (req, res, go)

    local failure=nil
    -- Only care about posts
    if req.method ~= "POST" then failure=true end

    local path = (req.params and req.params.path) or req.path
    --print("Path: ", path)

    local modulename = req.body;
    local htmldata = cmodules.getmodule(nil, modulename, nil)

    local datasource = _G.LOCALEDITING
    local body = template.render( htmldata, datasource )

    -- Return informaiton in body about login check
    res.headers["Content-Type"] = "text/html"
    res.code = 200
    res.body = body

    return
end
