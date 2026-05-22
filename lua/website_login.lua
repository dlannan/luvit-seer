
local getType = require("mime").getType
local makeChroot = require('coro-fs').chroot

local uv = require('uv')
local sha1 = require('sha1')
local argon2 = require('argon2')
local querystring = require('querystring')
local admin = require('administration')
local session = require('html_session')

--local fs = makeChroot(rootPath)
return function (req, res, go)

    local failure = nil
    -- Only care about posts
    if req.method ~= "POST" then failure = true end
    if req.params == nil then failure = true end

    -- Check if user is allowed to save (if they managed to enable the editor)
    local path = req.params or req.path

    -- User id part of the path - first part after /user
    --print("Userpage:", req.params.userpage)
    local json = querystring.parse(req.body)

    failure = session.checkrequest(req)
    
    local admin = _G.LOCALADMIN
    admin.page.pageid = req.params.userpage
    --p(admin)

    -- park the body data in temp memory
    -- If the user is valid, then this will be used
    _G.LOCALADMIN.user.savedata = req.body
    --print("Output body:", req.body)

    -- Return informaiton in body about login check
    res.headers["Content-Type"] = "text/html"
    if failure == session.SESSION_OK then
        res.code = 200
        res.body = "FHJLDLKJSSSSC32ene2eo4hjerwlkb323"
    else
        res.code = 201
        res.body = "Not So Good"
        --print("User Access Needs Auth:", admin.page.userid, req.params.userid)
        -- Clear sessions if the cookie is valid but failed a check
        if cookie ~= nil then 
            session.set( cookie, nil )
        end
    end
    return
end
