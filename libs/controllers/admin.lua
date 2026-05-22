local template = require "resty.template"
local fs = require('fs')
local pathJoin = require('luvi').path.join
local pathing = require('path')
local redis = require('redis-tools')
local session = require('html_session')
local modules = require('modules')

local path_assets = "/userassets/html/"
local project_path = _G.PROJECT

function get_restypage(name, html, key)

    local htmlcollection = _G.USERASSETS['html']
    local namelookup = name..".html"
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
    
    -- p(".............>", req, res)
    --Check the session - no page if the admin is not valid
    failure, usersess, cookie = _G.SESSIONS.checkrequest(req)
    --p(failure, usersess, cookie)
    if failure ~= _G.SESSIONS.SESSION_OK then 
        if _G.SESSIONS.SESSION_EXIT then
            res.code = 200
            res.headers["Content-Type"] = "text/html"
            local renderFilename = project_path..path_assets.._G.SESSIONS.SESSION_EXIT
            res.body = template.render( renderFilename, {} )
            res.path = _G.SESSIONS.SESSION_EXIT
            return
        end
        return go() 
    end
    
	if not req.params then return go() end
    
    local pagesource = req.params.name
    -- If a path has been added, add it to the name
	if req.params.path then 
        pagesource = pathJoin(req.params.path, req.params.name)
    end
    pagesource = pagesource..".html"

    local bodyhtml = ""
    local datasource = _G.LOCALEDITING or {}

    -- Get the page - not the blog!!
    local pagedata = ""
    if string.find(pagesource, "blog") then
        pagedata = _G.HTMLBLOGS.getblog(pagesource)
    else
        pagedata = _G.HTMLPAGES.getpage(pagesource)
    end

    -- Dont check on read - only on save!!!
    _G.LOCALEDITING.editing = true
    _G.editing = _G.LOCALEDITING.editing

    if pagedata == nil then        
        bodyhtml = get_restypage( req.params.name, req.path, datasource )
        if bodyhtml == nil then return go() end
        --p("Using RESTY.....")
    else
        -- Check pagedata has module-add!!!
        pagedata = modules.checkaddmodule(pagedata)
        bodyhtml = template.render(pagedata, datasource)
        -- p("Read Path:", path)
        --p("Using HTML SOURCE....")
    end
    
    if bodyhtml == nil then bodyhtml = "<html></html>" end
    
    res.code = 200
	res.headers["Content-Type"] = "text/html"
	res.body = bodyhtml
end

