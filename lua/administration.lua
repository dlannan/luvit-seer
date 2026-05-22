
local redis = require("redis-tools")
local sha1 = require("sha1")
local argon2 = require('argon2')
local timer = require('timer')
local utils = require('utils')

local argon2_pwd = argon2.makepwd

local admin = {

    cookie_timeout = 600.0,         -- 600 seconds is 10 minutes
    cookie_checkrate = 5000.0,      -- Check every 10 milliseconds for cookie changes
    
    -- All of the valid admin users - currently only support one per site!!!
    user = { 
                password = nil,    -- Valid user passord (test for strength)
                email = nil,          -- Email of user (need to confirm)
                uid = 0,
                validated = false,
                emailconfirmed = false, -- Has the email been confirmed
                userip = "",            -- what IP this user is coming from (internet). This will be fixed.
                cookie = "",        -- A sha key of the cookie that identifies the calling browser (ip and this part confirms user identity)
                usertype = "banned",    -- All users start banned, then access is elevated.
                useredit = false,       -- Is the user allowed to edit (must match editing usertype)
                timeout = cookie_timeout             -- How long before unauth user is kicked
    },
    page = { pageid=0, userid=0 },
    lastupdate = os.clock(),
    redis = _G.REDIS
}

-- List of admin keys for use below
local key_allpages = "system.admin.editing.allpages"
local key_allblogposts = "system.admin.editing.allblogposts"
local key_allusers = "system.admin.allusers"
local key_admin_user = "system.admin.user"

-- We dont know the uid when the user is added - the uid can change when users
-- access the site. We confirm users with login and password.
-- We also track IP changes (and maybe port changes)
-- WARNING: All passwords must be provided as argon2 keys. No clear text
--          passwords should be saved or used within the admin system!!
admin.adduser = function ( argpwd, email )

    admin.redis.connect()
    newuser = { 
                password = argpwd,    -- Valid user passord (test for strength)
                email = email,          -- Email of user (need to confirm)
                uid = sha1(email.."|"..argpwd),
                validated = false,
                cookie = "",
                emailconfirmed = false, -- Has the email been confirmed
                userip = "",            -- what IP this user is coming from (internet). This will be fixed.
                usertype = "new",       -- All users start banned, then access is elevated.
                useredit = false,       -- Is the user allowed to edit (must match editing usertype)
                timeout = admin.cookie_timeout -- How long before unauth user is kicked
    }

    -- Add user locally - warning this should be encrypted
    local allusers = admin.redis.hgetall(key_allusers)
    allusers[newuser.uid] = newuser.uid

    --p("Adding new user........")
    --p(" User: ", newuser.uid , newuser.password, newuser.email)
    --p(allusers)
    
    admin.redis.hmset(key_allusers.."."..newuser.uid, newuser)
    -- Add user as the only valid user (can always access)
    -- Check for port and IP changes when editing! Kick users with changing ports and IPs
    admin.redis.hmset(key_allusers, allusers)
    admin.redis.close()
end


admin.getuser = function ( cookie )

    admin.redis.connect()
    local allusers = redis.hgetall(key_allusers)
    local argcheck = cookie
    local user = nil
    
    -- If the password and email are right then assign uid and reset timeout
    if allusers[argcheck] ~= nil then
        user = redis.hgetall(key_allusers.."."..argcheck)
    end
    admin.redis.close()
    return user
end

admin.getallusers = function ()
    
    admin.redis.connect()
    local allusers = admin.redis.hgetall(key_allusers)
    
    admin.redis.close()
    return allusers
end

-- Warning - this is a nasty function 
-- TODO: Revisit this and make safer (so people cant write things without specific access)
--          Should use within a redis context - Need to make a contextual system for redis.
admin.setuser = function ( user )

    local allusers = redis.hgetall(key_allusers)
    
    -- If the password and email are right then assign uid and reset timeout
    if allusers[user.uid] ~= nil then
        admin.redis.hmset(key_allusers.."."..user.uid, user)
        
    else
        p("Invalid User.")
    end
end



return admin
