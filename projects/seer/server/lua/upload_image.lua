local fs = require('fs')
local pathJoin = require('luvi').path.join

local session = require('html_session')
local evt_images = require('data_images')
local querystring = require('querystring')

local path_userassets = _G.PROJECT.."/userassets"
local template  = require "resty.template"

local valid_filters   = {}

valid_filters['png']  = "images"
valid_filters['jpeg'] = "images"
valid_filters['jpg']  = "images"


return function (req, res, go)

    local failure = nil
    -- Only care about posts
    if req.method ~= "POST" then return go() end
    if req.params == nil then return go() end
    --p(req)

    --Check the session - no page if the admin is not valid
    failure, usersess, cookie = _G.SESSIONS.checkrequest(req)
    if failure ~= _G.SESSIONS.SESSION_OK then return go() end

    local json = querystring.parse(req.body)

    local ext = json.filename:match(".(%.[^.]*)$") or ""
    if ext == "" then return go() end

    ext = string.lower(string.sub(ext, 2, -1))
    --p("Extensions:", ext)

    category = valid_filters[ext]
    if category ~= nil then
        -- local fullpath = path_userassets
        p("Asset File name:", json.filename)
        -- fs.writeFileSync(assetfilename, req.body)
        evt_images.addimage( json.filename, json.imgdata )
    end

    res.body = template.render("projects/arusso_mockup/userassets/html/event-images.html")
    res.code = 200
end
