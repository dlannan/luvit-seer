
local getType = require("mime").getType
local makeChroot = require('coro-fs').chroot

local sha1 = require('sha1')
local querystring = require('querystring')
local JSON = require('json')
local redis = require('redis-tools')

local cmodules = require('modules')
local session = require('html_session')

--local fs = makeChroot(rootPath)
return function (req, res, go)

    local failure = nil
    -- Only care about posts
    if req.method ~= "GET" then return go() end
    --if req.params == nil then failure = true end
    --if req.params.userid == nil then failure = true end
    --p(req, res)

    -- User id part of the path - first part after /user
    --print("UserId:", req.params.userid)
    --print("Userpage:", req.params.userpage)

    failure = session.checkrequest(req)
    --p("settings: ", failure)
    
    -- Dont let people get settings unless they have auth.
    if failure ~= session.SESSION_OK then
        return go()
    end

    -- Return informaiton in body about login check
    res.headers["Content-Type"] = "text/html"
    if failure == session.SESSION_OK then
      res.code = 200
      res.body = "Goodie Lets Continue"
    else
      res.code = 201
      res.body = "No Save For You"
    end
    return
end
