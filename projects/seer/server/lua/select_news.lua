
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
local ndata     = require('data_news')

-- Lua Resty specific setup
template.caching(false)

return function (req, res, go)

    -- Only care about posts
    if req.method ~= "POST" then return go() end
    --p(req)
    
    --p(req, res)
    if req.body == nil then return go() end
    local path = (req.params and req.params.path) or req.path
    --print("Path: ", path)

    -- This parser will check the html is valid
    local data = json.parse(req.body)  
    --p( req.body )

    -- Submit form html to be stored in the redis.
    _G.NEWS_EDIT = ndata.readnews(data.uid)

    -- Load back into the admin event list page

    -- Nothing to really return
    res.code = 200
    res.headers["Content-Type"] = "text/html"
    res.body = "Ok"
    return
end
