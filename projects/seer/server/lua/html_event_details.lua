
local redis     = require('redis-tools')
local fs        = require('fs')
local htmlps    = require('htmlparser')
local template  = require "resty.template"
local html      = require "resty.template.html"

local json      = require('json')
local edata     = require('data_event')

local path_assets = "/userassets/html/"
local project_path = _G.PROJECT

-- Lua Resty specific setup
template.caching(false)

return function (req, res, go)

    -- Only care about posts
    if req.method ~= "GET" then return go() end
    --p(req)

    -- This parser will check the html is valid
    local datauid = req.query.datauid 
    --p( req.query, datauid )

    -- Submit form html to be stored in the redis.
    _G.EVENT_EDIT = edata.readevent(tonumber(datauid))
    
    local renderFilename = project_path..path_assets.."event.html"
    if not fs.existsSync(renderFilename) then p('NoFile.'); return nil end 
    
    local bodyhtml = template.render( renderFilename )

    -- Nothing to really return
    res.code = 200
    res.headers["Content-Type"] = "text/html"
    res.body = bodyhtml
    return
end
