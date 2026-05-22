
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
local edata     = require('data_event')

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
    
                -- p(data)
                -- put the data into the data base
                edata.jsontoevent( data )
                --p("Adding Event:", data)
    
                -- We may want to email submissions back to a contact
                local msg =[[<html>
                <h2>]]..data.title..[[</h2>
                <p>A new Event has been added to OOTS.</p> 
                {(projects/arusso_mockup/userassets/html/new-event.resty, { d=d })} 
                ]]
    
                --msg = msg..[[</html>]]
                --local outdata = template.render( msg, { d=data } )
                --p(outdata)
    
                --simplesend( usersess.email, usersess.email, "New Event Added", outdata)
            end
        end
    
        -- Load back into the admin event list page
    
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
