local fs = require('fs')
local pathJoin = require('luvi').path.join
local path = require('path')

local redisConnect = require('redis-client')
local redis = require( "redis-tools" )

local asetup = require("setupassets")
local session = require('html_session')

local path_userassets = _G.PROJECT.."/userassets"

local valid_filters   = {}

valid_filters['png']  = "images"
valid_filters['jpeg'] = "images"
valid_filters['jpg']  = "images"

valid_filters['svg']  = "icons"

valid_filters['mov']  = "videos"
valid_filters['mp4']  = "videos"


local template = require "resty.template"
local html = require "resty.template.html"

-- Lua Resty specific setup
-- Disable template caching
template.caching(false)
-- Disable print rendering - rendering to a string output
template.print = function(s)
	return s
end

return function (req, res, go)
    
    failure = session.checkrequest(req)
    if failure == true then go() end
    
    -- print("Filename:", req.params.filename)
    local ext = req.params.filename:match(".(%.[^.]*)$") or ""
    if ext == "" then go() end
        
    ext = string.sub(ext, 2, -1)
    print("Extensions:", ext)

    category = valid_filters[ext]
    if category ~= nil then
        local fullpath = path_userassets
        fullpath = pathJoin(fullpath, category)
        local assetfilename = pathJoin(fullpath, req.params.filename)
        print("Asset File name:", assetfilename)
        fs.writeFileSync(assetfilename, req.body)
        asetup.updateImages()
    end
    res.code = 200
    
    -- Update the local asset information and refresh the modal.
    asetup.init()
    
    local datasource = {}
    datasource['userid'] = uid
    datasource['editing'] = _G.LOCALEDITING.editing
    datasource['userassets'] = _G.USERASSETS
    res.body = template.render( "templates/wizards/wizard_assets_view.html", datasource )
end