
local getType = require("mime").getType
local makeChroot = require('coro-fs').chroot

local sha1 = require('sha1')
local querystring = require('querystring')

local fileio = require('fileio')
local redis = require('redis-tools')

-- Keyed by ip - save sockect info so we can 'do' something if things go bad
_G.newwebsites       = {}
_G.TOO_MANY_TRIES    = 10

-- This is local to the server 0 if it gets too big, then make another server!
_G.usercounter = 0

local template = require "resty.template"
local html = require "resty.template.html"

-- Lua Resty specific setup
-- Disable template caching
template.caching(false)
-- Disable print rendering - rendering to a string output
template.print = function(s)
	return s
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
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

    --print(req.params, req.path, req.body)
    -- Reord IP and port - so we can do tracking if needed (may be needed for banning and such)
    local ip = req.socket:getsockname().ip
    local port = req.socket:getsockname().port

    local function renderFile()
      -- Generate the body content here - make a start template with a specific hash.

      -- Put timer limits on the creation (seconds) so people dont spam this creation.
      local body = "404 Not Found"
      res.code = 404
      res.headers["Content-Type"] = "text/html"
      res.body = body
      return
    end

    -- Parse the body for valid data - if not.. NoFile..
    local json = querystring.parse(req.body)

    --p("New Website: ", ip, port, json)

    local count = 0
    for k,v in pairs(json) do count = count + 1 end

    -- Check for valid info to start website
    if json == nil then return renderFile() end
    if count < 1 then return renderFile() end

    -- Put timer limits on the creation (seconds) so people dont spam this creation.

    -- Generate the body content here - make a start template with a specific hash.
    -- Get the website type from redis (should be a template)
    --print("Create Web:", json.website_type, json.website_name)

    -- Connect to redis
    redis.connect()
    if redis.call("exists", "content.default.theme."..json.website_type) == 0 then
        print("Error fetching webpage.")
        return renderFile()
    end

    -- Always start at the langing page - if people save and buy site then this will be added to their site
    path = "demo/index.html"

    if _G.LOCALADMIN.user == nil then _G.LOCALADMIN.adduser( "nobody", "wgaf@wgaf.com" ) end

    _G.LOCALADMIN.adduserpage( "index", path )
    _G.LOCALADMIN.adduserpagepath( "index", path )

    _G.LOCALADMIN.adduserblogpost(  "default", path )
    _G.LOCALADMIN.adduserblogpostpath( "default", path )
    
    redis.connect()

    -- Pages get the local editing space to 'use' until they sign up.
    local datasource = _G.LOCALEDITING

    --for k,v in pairs(datasource) do print(k,v) end

    --redis.call("set", "/admin/getallpages", fileio.read_file("templates/allpages.html"))
    redis.hmset( "/admin/getallpages.datasource", datasource )

    --redis.call("set", "/admin/getallblogposts", fileio.read_file("templates/allblogposts.html"))
    redis.hmset( "/admin/getallblogposts.datasource", datasource )
    
    -- If editing is set to false only a normal page is rendered. --
    local htmlsrc = redis.call("get", "content.default.theme."..json.website_type)
    local body = template.render( htmlsrc, datasource )
    redis.call("set", path, body)
		p("Startup Path:", path)
    redis.close()

    -- print("Output body:", path)
    res.code = 200
    res.headers["Content-Type"] = "text/html"
    res.body = path
    return
end
