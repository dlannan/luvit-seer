local template = require "resty.template"
local fs = require('fs')
local pathJoin = require('luvi').path.join
local pathing = require('path')
local redis = require('redis-tools')

local uv = require('uv')
local stats = require('flodstats')

local path_assets = "/userassets/html/"
local project_path = _G.PROJECT

local function get_restypage(name, html, key)

    local htmlcollection = _G.USERASSETS['html']
    local namelookup = name
    local htmlFilename = htmlcollection[namelookup]
    
    local renderFilename = project_path..path_assets..name..".html"
    if htmlFilename ~= nil then
        renderFilename = htmlFilename.projpath
    end
    --p(">>>>>>>>>>>>>", name, htmlFilename, renderFilename)
    if not fs.existsSync(renderFilename) then return nil end 

	return template.render(renderFilename, key)
end

template.print = function(s)
	return s
end

local loadContent = require('load-content')

return function (req, res, go)
    
    local failure=nil
    stats.emit(req)
    
    -- Dont check on read - only on save!!!
    _G.LOCALEDITING.editing = false
    _G.editing = _G.LOCALEDITING.editing
    
    -- p(".............>", sock, req, res, go)
	if not req.params then return go() end
    local sock = uv.tcp_getpeername(req.socket)
    
    local pagesource = req.params.name
    --p(pagesource) 
    if pagesource == "" then pagesource = "index" end
    -- If a path has been added, add it to the name
    if req.params.path then 
        pagesource = pathJoin(req.params.path, pagesource)
    end
    local ext = pathing.extname( pagesource )
    --p("Extension:", ext)
    if ext == "" then
        pagesource = pagesource..".html"
    end
    
    local bodyhtml = ""
    local datasource = _G.LOCALEDITING or {}

    -- Connect to redis
    local pagedata = ""
    if string.find(pagesource, "blog") then
        pagedata = _G.HTMLBLOGS.getblog(pagesource)
    else
        pagedata = _G.HTMLPAGES.getpage(pagesource)
    end
    
    if pagedata == nil then
        bodyhtml = get_restypage( pagesource, req.path, datasource )
        if bodyhtml == nil then go() end
    else
        bodyhtml = template.render(pagedata, datasource)
    end
    
    -- Check the session. If it needs login. Add to the body.body 
    if _G.SESSIONS.loginrequired == true then
        
    end
    
    if bodyhtml == nil then bodyhtml = "<html></html>" end
	
    res.code = 200
	res.headers["Content-Type"] = "text/html"
	res.body = bodyhtml
end

