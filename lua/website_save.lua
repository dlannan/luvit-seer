
local getType = require("mime").getType
local makeChroot = require('coro-fs').chroot

local uv = require('uv')
local sha1 = require('sha1')
local querystring = require('querystring')
local JSON = require('json')
local redis = require('redis-tools')
local session = require('html_session')

local cmodules = require('modules')

--local fs = makeChroot(rootPath)
return function (req, res, go)

    local failure   = nil
    local usersess  = nil
    local cookie    = nil

    -- Only care about posts
    if req.method ~= "POST" then failure = true end
    --if req.params == nil then failure = true end
    --if req.params.userid == nil then failure = true end

    -- Check if user is allowed to save (if they managed to enable the editor)
	if not req.params then return go() end
    --p(req)

    failure, usersess, cookie = session.checkrequest(req)
    -- p("Saving..", failure, usersess)
    if failure == session.SESSION_OK and usersess ~= nil then

        usersess.savedata = req.body
        session.set(cookie, usersess)

        -- The data comes in 'packaged' into modules that need to be placed into the page.
        local pagesource = req.params.userpage
        local htmldata = convertToTemplate(usersess.savedata)
        
        if (pagesource == nil) or (htmldata == nil) then
            failure = session.FAILED_FETCH_DATA
        else
            if string.find(pagesource, "blog") then
                _G.HTMLBLOGS.addblog(pagesource, htmldata)
            else
                _G.HTMLPAGES.addpage(pagesource, htmldata)
            end
            failure = session.SESSION_OK
        end
        --p("Saved: ", failure, keypath)
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
