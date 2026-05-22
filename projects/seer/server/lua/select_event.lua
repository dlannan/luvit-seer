
local json      = require('json')
local edata     = require('data_event')

return function (req, res, go)

    -- Only care about posts
    if req.method ~= "POST" then return go() end
    --p(req)
    if req.body == nil then return go() end

    -- This parser will check the html is valid
    local data = json.parse(req.body)  
    --p( req.body )

    -- Submit form html to be stored in the redis.
    _G.EVENT_EDIT = edata.readevent(data.uid)

    -- Nothing to really return
    res.code = 200
    res.headers["Content-Type"] = "text/html"
    res.body = "Ok"
    return
end
