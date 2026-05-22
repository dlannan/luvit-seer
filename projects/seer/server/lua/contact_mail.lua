
local getType = require("mime").getType
local makeChroot = require('coro-fs').chroot

local sha1 = require('sha1')
local json = require('json')

local fileio = require('fileio')
local redis = require('redis-tools')

local https = require('https')
local htmlps = require('htmlparser')
local template = require "resty.template"
local html = require "resty.template.html"

local session = require('html_session')

-- This will go in admin in the redis db.
local mailuser = "dlannan@kakutai.com"

-- Lua Resty specific setup
template.caching(false)

require('mailer')

function checkgoogleresponse(data, remoteip)

    local postparams = string.format("secret=6LcjuRYUAAAAADBI_9wbE_-AKPTXVB8_Hse0Xars&response=%s&remoteip=%s", data['g-recaptcha-response'], remoteip)
    
    local options = {
        host = "www.google.com",
        port = 443, 
        path = "/recaptcha/api/siteverify?"..postparams
    }

    local googreq = https.request(options, function (res)
        res:on('data', function (chunk)
            local respdata = json.parse(chunk)
  
            if respdata then
                if( respdata['success'] == true) then
                    local msg =[[<html><h2>]]..data.subject..[[ Automated Email.</h2>
                    <p>]]..data.message..[[</p>
                            <p> From: ]]..data.name..[[</p></html>]]
                    --p(outdata)

                    simplesend( data.email, mailuser, data.subject, msg )
                else
                    p("Google Respone Error: Google failed to validate")
                end
            end
        end)
        res:on('error', function( err )
             p("Google Respone Error:", err)
        end)
    end)
    googreq:done()
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
    local ip = req.socket:getsockname().ip
    
    -- Before going further make sure this is validated from google
    checkgoogleresponse(data, ip)

    -- Nothing to really return
    res.code = 200
    res.headers["Content-Type"] = "text/html"
    res.body = path
    return
end
