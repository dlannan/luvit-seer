
local redis = require("redis-tools")
local sha1 = require("sha1")
local argon2 = require('argon2')
local timer = require('timer')
local utils = require('utils')
local admin = require('administration')
local uv = require('uv')

local argon2_pwd = argon2.makepwd

local key_allcookies = "system.allcookies"

local session = _G.SESSION

-- There can be only one session for any running instance of flod.
if session == nil then

session = {
    
    SESSION_OK              = 1,

    FAILED_NO_COOKIE        = 100,
    FAILED_IP_CHANGED       = 101,
    FAILED_INVALID_COOKIE   = 102,
    FAILED_INVALID_UID      = 103,
    FAILED_TIMEOUT          = 104,
    FAILED_USER_CHECK       = 105,
    FAILED_FETCH_DATA       = 106,

    -- all running current sessions
    active = {

    },

    started         = false,
    loginrequired   = false,
    -- update timer
    cookieTimer = nil
}

_G.SESSION = session
end

session.get = function(cookie)
    
    return session.active[cookie]
end

session.getcookiefromheader = function(req)
    -- Get cookie from header
    local cookie = nil
    for k,v in pairs(req.headers) do
        if v[1] == "Cookie" then
            cookie = v[2]
        end
    end  

    if cookie ~= nil then
        -- strip the front end off the cookie
        cookie = string.match(cookie, "userId=([%a%d]*);?")
    end
    return cookie
end

session.clearall = function()
    
    session.active = {}
end

session.set = function( cookie, user )

    if user ~= nil then
        user.cookie = cookie
        coroutine.wrap( function() 
            admin.redis.connect()
            admin.setuser( user )
            admin.redis.close()
        end)
    end
    session.active[cookie] = user
end

-- Cookie and userid are the same. Userid is cookie with argon2.
session.addcookie = function ( cookie )

    session.set(cookie, admin.getuser(cookie) )
end

session.checkuser = function ( pwd, email, sock )
    
    local argpwd = argon2_pwd( pwd )
    local allusers = admin.getallusers()
    
    local testid = sha1(email.."|"..argpwd)
    local passed = false
    
    -- If the password and email are right then assign uid and reset timeout
    if allusers[testid] ~= nil then
        local user = admin.getuser(testid)
        if user ~= nil then
            
            -- Update the session only - dont write back to db
            user.uid = sha1( user.email..'|'..user.password )
            user.cookie = user.uid
            user.usertype = "user"
            user.emailconfirmed = true
            user.validated = true
            user.ip = sock.ip

            -- Write back
            session.set( user.cookie, user )
            -- p("User properly validated!", user)
            passed = true
        end
    end
    
    return passed
end


session.updatecookies = function ()
    
    local tm = os.clock()
    local diff = tm - admin.lastupdate
    admin.lastupdate = tm
    
    local testid = nil
    local lastuser = nil
    
    -- to do anything we need a valid redis connection 
    -- Because we are in a callback, we need to wrap this.

    
    local badcookies = {}
    local allusers = session.active
    for k,v in pairs(allusers) do

        user = v
        -- countdown all the clocks if they are > 0.0
        if user ~= nil then
            if tonumber(user.timeout) > 0.0 then
                user.timeout = tonumber(user.timeout) - diff
                if tonumber(user.timeout) < 0.0 then
                    user.timeout = 0.0
                    badcookies[k] = v
                end
                -- write back to user data
                session.set(k, user)
            end
            lastuser = user
        end
    end

    -- if we have bad cookies - remove them from the cookie list
    for k,v in pairs(badcookies) do
        -- Remove stored sessions
        session.set(k, nil)
    end
end

session.checkrequest = function(req)
   
    local failure = nil
    local usersess = nil
   
    -- Get cookie
    local cookie = session.getcookiefromheader(req)
    
    -- Cookie has been set, so you may not need to login!
    if cookie ~= nil then 
    
        --p("UserLogin: ", json["useremail"], json["userpassword"], cookie)
    
        -- Check for current sessions - if ip or cookie has changed, invalidate!
        usersess = session.get(cookie)
        -- p(session.get(cookie), usersess)
        if usersess ~= nil then
            local sock = uv.tcp_getpeername(req.socket)
            failure = session.SESSION_OK
            
            -- Any of these tests fail, then recheck user
            if (usersess.cookie ~= cookie) then failure = session.FAILED_INVALID_COOKIE end
            if (usersess.uid ~= cookie) then failure = session.FAILED_INVALID_UID end
            if (usersess.ip ~= sock.ip) then failure = session.FAILED_IP_CHANGED end
            if (tonumber(usersess.timeout) <= 0.0) then failure = session.FAILED_TIMEOUT end
            -- p("Valid session but failed: ", "Cookie:", (usersess.cookie ~= cookie), "UserId:", (usersess.uid ~= cookie) , "IP:", (usersess.ip ~= sock.ip), "Timeout:", ( tonumber(usersess.timeout) <= 0.0))
        else 
            failure = session.FAILED_NO_COOKIE
        end
    end
    return failure, usersess, cookie
end

session.init = function( config )
 
    -- At start clear any cookies!!
    session.clearall()
    session.cookieTimer = timer.setInterval(admin.cookie_checkrate, session.updatecookies)
    if config then
       session.loginrequired = config.loginrequired
    end
end

return session