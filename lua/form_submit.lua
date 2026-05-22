
local getType = require("mime").getType
local makeChroot = require('coro-fs').chroot

local sha1 = require('sha1')
local json = require('json')

local fileio = require('fileio')
local redis = require('redis-tools')

local htmlps = require('htmlparser')
local template = require "resty.template"
local html = require "resty.template.html"

local session = require('html_session')

-- Lua Resty specific setup
template.caching(false)

require('mailer')

-- print the tree
local function htmlprint(n)
    if n == nil or n.level == nil then return end
    local space = string.rep("  ", n.level)
    local s = space .. n.name
    for k,v in pairs(n.attributes) do
        s = s .. " " .. k .. "=[[" .. v .. "]]"
    end
    print(s)
    for i,v in ipairs(n.nodes) do
        p(v)
    end
end


return function (req, res, go)

    local failure=nil
    -- Only care about posts
    if req.method ~= "POST" then return go() end

    --p(req, res)
    if req.body == nil then return go() end
    local path = (req.params and req.params.path) or req.path
    --print("Path: ", path)

    -- This parser will check the html is valid
    local data = json.parse(req.body)  
    -- user wants a copy sent to them.s
    if data.businessemail == 'true' then
        
        -- Get cookie
        cookie = session.getcookiefromheader(req)
        --p(cookie)
        
        local usersess = session.get(cookie)
        --p( usersess)
        if usersess ~= nil then
            
            -- Submit form html to be stored in the redis.
            if usersess.validated == true then
                -- Check for email and ui
                if usersess.email ~= nil and usersess.uid ~= 0 then

                    -- have a valid user, store the data for later fetch/build in redis.
                    coroutine.wrap( function() 
                        redis.connect()
                        redis.hmset(key_userdata.."."..usersess.email, data)
                        redis.close()
                    end)
                            
                    local msg =[[<html>
                    <h2>]]..data.businessname..[[</h2>
                    <p>The included page is the summary sheet of the Web Design Plan.</p> 
                    <p>Please reply to this email if the plan appears incorrect or if you would like to make a change.</p>
                    {(templates/wizards/clientquestionnaire.resty, { d=d })} 
                    ]]

                    msg = msg..[[</html>]]
                    local outdata = template.render( msg, { d=data } )
                    --p(outdata)

                    simplesend( "dlannan@kakutai.com", usersess.email, "Web Design Plan", outdata)
                end
            end
        end
    end
    
    -- Nothing to really return
    res.code = 200
    res.headers["Content-Type"] = "text/html"
    res.body = path
    return
end
