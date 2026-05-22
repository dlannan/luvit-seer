local pathJoin = require('luvi').path.join
local makeChroot = require('coro-fs').chroot


return function(rootPath)

    local fs = makeChroot(_G.PROJECT)

    return function (req, res, go)

        rootPath = pathJoin(_G.PROJECT, "css")
        --p(".............>", req, res, go)
        local cssfilename = pathJoin("css", req.params.path)
        local cssdata = fs.readFile(cssfilename)
        if cssdata == nil then return go() end

        res.code = 200
        res.headers["Content-Type"] = "text/css"
        res.body = cssdata
        return
    end
end