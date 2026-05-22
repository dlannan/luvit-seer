
local getType = require("mime").getType
local makeChroot = require('coro-fs').chroot

local uv = require('uv')
local sha1 = require('sha1')
local argon2 = require('argon2')
local querystring = require('querystring')

local fileio = require('fileio')
local redis = require('redis-tools')
local admin = require('administration')
local session = require('html_session')

local template = require "resty.template"
local html = require "resty.template.html"

local argon2_pwd = argon2.makepwd

-- Lua Resty specific setup
-- Disable template caching
template.caching(false)
-- Disable print rendering - rendering to a string output
template.print = function(s)
	return s
end

return function (req, res, go)

    local failure   = nil
    local usersess  = nil
    local cookie    = nil
    
    -- Only care about posts
    if req.method ~= "POST" then failure=true end

    local path = (req.params and req.params.path) or req.path

    local json = querystring.parse(req.body)
    if json["useremail"] == nil then failure=true end
    if json["userpassword"] == nil then failure=true end

    --p(json, req.body)
    local sock = uv.tcp_getpeername(req.socket)
    
    failure, usersess, cookie = session.checkrequest(req)
    --p(failure, usersess, cookie)
    --p(failure, usersess, cookie)
    if failure == nil or failure == session.FAILED_NO_COOKIE then

        -- TODO: Put this into a session check
        -- This checks user vs socket and credentials.
        if session.checkuser( json["userpassword"], json["useremail"], sock ) == true then
            -- The user has validated correctly and check the cookie!
            -- A new cookie needs to be returned!
            if cookie == nil then 
                local argpwd = argon2_pwd( json["userpassword"] )
                cookie = sha1(json["useremail"].."|"..argpwd)
            end
            failure = session.SESSION_OK
        else
            failure = session.FAILED_USER_CHECK
            if cookie ~= nil then
                session.set( cookie, nil )
            end
        end
    end

    -- Return informaiton in body about login check
    res.headers["Content-Type"] = "text/html"
    if failure == session.SESSION_OK then
        res.code = 200
        res.body = cookie
    else
        res.code = 201
        res.body = "Not So Good"
    end
    return
end
