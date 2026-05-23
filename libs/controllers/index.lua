local pathJoin = require('luvi').path.join
local makeChroot = require('coro-fs').chroot

local aspect        = require("aspect.template").new({
    -- debug       = true,
    -- cache       = false,
})

require("aspect.custom_filters")
require("aspect.custom_functions")

return function(rootPath, datasrc)

    local fs = makeChroot(rootPath)
    aspect.loader = require("aspect.loader.filesystem").new( pathJoin(_G.PROJECT_FOLDER, rootPath) )

    return function (req, res, go)
        if req.method ~= "GET" then return go() end
        local path = (req.params and req.params.path) or req.path
        if(path ~= "/") then return go() end
        
        local function renderFile()
            path = "dashboard"
            output, err = aspect:render(path..".html.twig", datasrc)
            res.headers["Content-Type"] = "text/html"
            res.body = output.result
        end
        return renderFile()
    end
end