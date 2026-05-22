-- Modules for use in the system.
--  Conversion and generation tools to make modules.
-- Templates can also be generated using this module.
local redis = require("redis-tools")
local sha1 = require('sha1')
local querystring = require('querystring')
local JSON = require('json')
local htmlps = require('htmlparser')

require('modulefunctions')

local cmodules = {
    cmodules = 0,
    restyblocks = {},     -- List of all available modules to be instantiated (by module key name)
}


module_lookups = {}
module_lookups["module-add"] = "templates/wizards/module-add.html"
module_lookups["module-banner"] = "templates/modules/banner.html"
module_lookups["module-carouselwithtext"] = "templates/modules/carouselwithtext.html"
module_lookups["module-feed"] = "templates/modules/feed.html"
module_lookups["module-footer"] = "templates/modules/footer.html"
module_lookups["module-fullscreenmedia"] = "templates/modules/fullscreenmedia.html"
module_lookups["module-image"] = "templates/modules/image.html%"
module_lookups["module-imagemasonry"] = "templates/modules/imagemasonry.html"
module_lookups["module-mediagrid"] = "templates/modules/mediagrid.html"
module_lookups["module-sidefeature-left"] = "templates/modules/sidefeatureleft.html"
module_lookups["module-sidefeature-right"] = "templates/modules/sidefeatureright.html"
module_lookups["module-socialmediaaccounts"] = "templates/modules/socialmediaaccounts.html"
module_lookups["module-spotify"] = "templates/modules/spotify.html"

module_data = {}
module_data["module-add"] = function( id, d ) return "" end
module_data["module-banner"] = bannertext
module_data["module-carouselwithtext"] = mediasetdata
module_data["module-feed"] = feeddata
module_data["module-footer"] = bannertext
module_data["module-fullscreenmedia"] = mediasetdata
module_data["module-image"] = imagedata
module_data["module-imagemasonry"] = defaultdata
module_data["module-mediagrid"] = mediasetdata
module_data["module-sidefeature-left"] = mediasetleft
module_data["module-sidefeature-right"] = mediasetleft
module_data["module-socialmediaaccounts"] = defaultdata
module_data["module-spotify"] = defaultdata

-- Take the webpage and turn it back into the themed default.
--  The default should be fairly empty, and we inject modules with data
--  as the htmlbody is parsed.
function convertToTemplate( htmlbody )
    -- All modules start with: <div class="module-
    -- Using this as the base search field we use the default layout, plus the modules inserted with parameters.

    -- Connect to redis
    redis.connect()
    if redis.call("exists", "content.default.theme.Default.blank") == 0 then
        return nil
    end
    local blank = redis.call("get", "content.default.theme.Default.blank")

    local htmlrep = ""
    local json = JSON.parse(htmlbody)
    for k, v in ipairs(json.ordered) do
        if v.data ~= nil and module_lookups[v.modulename] ~= nil then
            local moduleline = cmodules.getmodule(v.id, v.modulename, v.data)
            htmlrep = htmlrep..moduleline.."\r\n"
        end
    end
    --p(blank)
    local newhtml = string.gsub(blank, "<<<MODULES>>>", htmlrep)
    --p(newhtml)
    return newhtml
end

cmodules.addtemplate = function( mid, block )

    -- TODO: Check the block for any inconsistencies
    cmodules.restyblocks[mid] = block
end

-- Get a module template and render to html, return the html string
--  If datasource is provided then add the datasource
cmodules.getmodule = function( id, modname, datasource )
    local moduleline = ""
    if datasource == nil then
        moduleline = _G.RESTYS[modname]
    else
        local datafunc = module_data[modname] or defaultdata
        local resty =  _G.RESTYS[modname] or ""
        local moddata = ",{" ..(datafunc( id, datasource, resty )).."}"
        -- This must go back into the resty data for this page
        moduleline = string.format("{(%s%s)}", module_lookups[modname], moddata)
    end
    return moduleline
end


cmodules.checkaddmodule = function ( pagedata )
    cmodules.toggle = 0
    
    local newdata = string.gsub( pagedata, "{%(templates/modules/.-.html,.-}%)}", function(n)
            
        local outdata = n
        local modname = string.match( n, "{%(templates/modules/(.-).html" ) 
        if modname ~= "footer" then
            --p("Module Found: ", modname)

            if cmodules.toggle == 1 then
                cmodules.toggle = 0
                outdata = [[{(templates/wizards/module-add.html)}]]..n
            end
                
            if modname == "module-add" then 
                cmodules.toggle = 0
            else
                cmodules.toggle = 1
            end
        end
        return outdata
    end )
    return newdata
end


return cmodules
