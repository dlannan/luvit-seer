local json  = require("json")

return function( dataset )
    return function( req, res, go)
        local data = json.decode(req.body)
        local icon = string.gsub(data.icon, "^.+base64,(.+)", "%1")
        dataset.projects[data.projectid].scenes[data.sceneid].icon = icon
        res.code = 200 
        res.body = data.id 
        res.headers["Content-Type"] = "text/html"
    end
end