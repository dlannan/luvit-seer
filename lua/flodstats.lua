local fs = require('fs')
local uv = require('uv')
local redis = require('redis-tools')
local Emitter = require('core').Emitter
local http = require('http')
local json      = require('json')

local target_log = "flod.log"    
if _G.PLATFORM.os == "linux" then
target_log = "/var/log/flod.log"
end

local flodstats = _G.STATS

-- There can be only one session for any running instance of flod.
if flodstats == nil then
    flodstats = {}
    flodstats.visitors = {}
    flodstats.unique   = {}
    _G.STATS = flodstats
end

-- Our tracking is based on two main elements 
--- 1. The IP source of the request
--- 2. The browser and req header info unique to the user (as much as possible)
-- All tracks are linear queues, following the progress of a user within the server.
-- TODO: Add tracking of all window (browser) events - cache it locally, then post it on exit.

flodstats.geofetch = function( host, url, sock, req )
    
    -- Early out if its localhost
    if sock.ip == "127.0.0.1" then
        geodata = {
            ip="127.0.0.1",
            city= "Adelaide",
            region= "South Australia",
            country= "AU",
            postal= "5000",
            latitude= 34.9285,
            longitude= 138.6007,
            timezone= "Australia/Adelaide"
        }
        flodstats.unique[sock.ip] = { geodata = geodata, count = 1, queue = { req } }
        return
    end
    
    local options = {
        host = host,
        port = 80,
        path = "/"..url
    }
    
    local georeq = http.request(options, function (res)
        res:on('data', function (chunk)
            local geodata = json.parse(chunk)
            flodstats.unique[sock.ip] = { geodata = geodata, count = 1, queue = { req } }
        end)
        res:on('error', function( err )
             p("error:", err)
        end)
    end)
    georeq:done()
end

local datetime = function()
    return  os.date("%c")
end

local collector = function( req )
    
    local sock = uv.tcp_getpeername(req.socket)
    
    if flodstats.visitors.day == nil then flodstats.visitors.day = {} end
    if flodstats.unique[sock.ip] == nil or flodstats.visitors.day[ os.date("%Y%m%d") ] == nil then
        local weekid = os.date("%Y%m")..( string.format("%02d", tonumber(os.date("%d")) % 7 ) )

        if flodstats.visitors.week == nil then flodstats.visitors.week = {} end
        -- Count visitors for the day/week
        if flodstats.visitors.day[ os.date("%Y%m%d") ] == nil then flodstats.visitors.day[ os.date("%Y%m%d") ] = 0 end
        flodstats.visitors.day[ os.date("%Y%m%d") ] = flodstats.visitors.day[ os.date("%Y%m%d") ] + 1

        if flodstats.visitors.week[ weekid ] == nil then flodstats.visitors.week[ weekid ] = 0 end
        flodstats.visitors.week[ weekid ] = flodstats.visitors.week[ weekid ] + 1
    end
    
    if flodstats.unique[sock.ip] ~= nil then 
        flodstats.unique[sock.ip].count = flodstats.unique[sock.ip].count + 1
        local newtable = flodstats.unique[sock.ip].queue
        table.insert(newtable, req)
        flodstats.unique[sock.ip].queue = newtable
    else
        -- Get the geo info (its ok but not always accurate)
        flodstats.geofetch("ipapi.co", sock.ip..'/json/', sock, req)
    end
end

flodstats.logger = function()
    return function (req, res, go)
      -- Skip this layer for clients who don't send User-Agent headers.
      local userAgent = req.headers["user-agent"]
      if not userAgent then return go() end
      -- Run all inner layers first.
      go()
      -- And then log after everything is done
      fs.appendFileSync(target_log, string.format("[%s] %s %s %s %s\r\n", datetime(), req.method,  req.path, userAgent, res.code))
    end
end

flodstats.emit = function( req )

    if flodstats.emitter then
        flodstats.emitter:emit('logging', req)
    end
end

flodstats.init = function()
    
    flodstats.emitter = Emitter:new()
    flodstats.emitter:on('logging', collector)
end

return flodstats
