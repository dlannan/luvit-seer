
local getType   = require("mime").getType
local makeChroot = require('coro-fs').chroot

local sha1      = require('sha1')
local json      = require('json')

local fileio    = require('fileio')
local redis     = require('redis-tools')

local htmlps    = require('htmlparser')
local template  = require "resty.template"
local html      = require "resty.template.html"

local session   = require('html_session')
local events    = require('data_event')
local news      = require('data_news')

-- Lua Resty specific setup
template.caching(false)

require('mailer')


return function (req, res, go)

    local failure=nil
    -- Only care about posts
    if req.method ~= "POST" then return go() end

    --Check the session - no page if the admin is not valid
    failure, usersess, cookie = _G.SESSIONS.checkrequest(req)
    if failure == _G.SESSIONS.SESSION_OK then

        --p(req)
        if req.body == nil then return go() end
        local path = (req.params and req.params.path) or req.path
        --print("Path: ", path)
    
        -- This parser will check the html is valid
        local data = json.parse(req.body)  
        --p( data )
        
        -- Check that the usersess is available
        if usersess ~= nil then
            
            -- Submit form html to be stored in the redis.
            if usersess.validated == true then
    
                if data.news == true then
                    news.jsonpublish( data )
                else
                    -- p(data)
                    events.jsonpublish( data )
                end
    
                -- We may want to email submissions back to a contact
                --msg = msg..[[</html>]]
                --local outdata = template.render( msg, { d=data } )
                --p(outdata)
    
                --simplesend( usersess.email, usersess.email, "New Event Added", outdata)
            end
        end
        
        -- Nothing to really return
        res.code = 200
        res.headers["Content-Type"] = "text/html"
        res.body = template.render( "/admin/admin-events.html" )
        return
    end
    -- Nothing to really return
    res.code = 201
    res.headers["Content-Type"] = "text/html"
    res.body = "Not So Good"
    return
end
