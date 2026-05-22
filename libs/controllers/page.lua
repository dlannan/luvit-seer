local renderTemplate = require('render-template')
local loadContent = require('load-content')

local template = require "resty.template"
local html = require "resty.template.html"

local redis = require( "redis-tools" )

return function (req, res, go)
    --local data = loadContent("pages", req.params.name)
    local path = (req.params and req.params.path) or req.path
    --print(">>>>>>> PATH >>>>> ", path)

    -- Connect to redis
    redis.connect()
    if redis.call("exists", path) == 0 then
        redis.close()
        return go()
    end

    local html = redis.call("get", path)
    --p("Read Path:", path)
    if html == nil then html = "<html></html>" end

    local htmldata = redis.hgetall(path..".datasource")
    if htmldata == nil then htmldata = {} end
    -- TODO: Override the data source until we get multiuser data management happening.

    --p(_G.LOCALEDITING)
    if _G.LOCALEDITING.editing == true then
        local admin = _G.LOCALADMIN
        _G.LOCALEDITING.userid = admin.user.uid
    end
    htmldata = _G.LOCALEDITING

    redis.close()

    if not html then return go() end
    res.code = 200
    res.headers["Content-Type"] = "text/html"
    res.body = template.render( html, htmldata )

    return
end
