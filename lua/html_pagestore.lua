local redis      = require('redis-tools')

-- These utilities help in working with the html files
--  stored in redis and how they are time saved/stored.

local DEFAULT_PAGE   = "content.default.theme.Default.page"

local htmlstore = {
    
    excludelist = {}
}

-- Storage works like this:
---    The initial page comes from either an already created page, or from
---    a default provided page. This page gets an initial storage set in 
---    the "project/allpages" directory in redis. 
---
---    Pages are stored by their last saved time UTC (to the server). The layout 
---    is that all time saved entries in the store are saved under the name of
--     the page. Thus, project/allpages/demo/index.html would have child pages
---      project/allpages/demo/index.html/0029382345  and others.
---
---    Using this method we can store all changes made to a html page. When 
---    selecting a page to edit, the admin will always get the latest revision
---    unless they specifically choose one from the dropdown time list (to be
---    implemented later)
---
---    This same method will be applied to blogs as well.

-- All pages stored here
local pages_base_path = _G.PROJECT.."/allpages/"

-- These keys keep lists of the times that have been saved - thus able to regenerate the key needed to retrieve the html data.
local pages_basetime_path = _G.PROJECT.."/allpagestime/"


htmlstore.addpagetime = function( htmlpage, newtime )
    local currentlist = redis.hgetall( pages_basetime_path..htmlpage ) or {}
    currentlist[#currentlist + 1] = newtime
    redis.hmset( pages_basetime_path..htmlpage, currentlist )
end

htmlstore.getlastpagetime = function( htmlpage )
    local currentlist = redis.hgetall( pages_basetime_path..htmlpage ) or {}
    local result = currentlist[#currentlist]
    return result
end

htmlstore.addpagedata = function( htmlpage )
    
    -- Create a page dataset we can use for publishing and editing
    local thispage = redis.hgetall( pages_base_path .. htmlpage )
    if #thispage == 0 then
        redis.hmset( pages_base_path..htmlpage, { 
                page=htmlpage,
                userpage=htmlpage,
                name=htmlpage, 
                template="Default",
                tags="page",
                publish="",
                metatitle="",
                metadesc="",
                urlhandle="",
                pageimage=""
        } )
    else
        thispage.page=page
        redis.hmset( pages_base_path .. htmlpage, thispage )
    end
end

htmlstore.excludepage = function(excludefile)
    
    htmlstore.excludelist[excludefile] = true
end

htmlstore.getpagedata = function(htmlpage)
    --p("Getting Page Data for: ", pages_base_path .. htmlpage)
    local thispage = redis.hgetall( pages_base_path .. htmlpage )
    return thispage
end

htmlstore.setpagedata = function(htmlpage, pagedata)
    redis.hmset( pages_base_path .. htmlpage, pagedata )
end

htmlstore.newpage = function(htmlpage, htmldata)

    local newpagedata = rdis.call("get", DEFAULT_PAGE)
    
    -- Have the data now need to create a unique page name/path.
    local allpages = redis.hgetall( pages_base_path )
    
    if allpages then
        local name = "default.html"
        
        if allpages[name] ~= nil then
            for i=1, 99 do
                name = string.format("default%02d.html", i)
                if allpages[name] == nil then
                    break     
                end
            end
        end
        
        htmlstore.addpage(name, newpagedata)
        return name
    end
    return "invalid.html"
end

htmlstore.addpage = function(htmlpage, htmldata)

    local allpages = redis.hgetall( pages_base_path ) or {}
    allpages[htmlpage] = htmlpage

    redis.hmset( pages_base_path, allpages ) 
    
    htmlstore.addpagedata(htmlpage)
    
    -- Do not check for previous ones, just add this to the time list.
    local timestamp = os.time()
    redis.connect()
    redis.call("set", pages_base_path..htmlpage.."/"..timestamp, htmldata)
    redis.close()
    htmlstore.addpagetime( htmlpage, timestamp )
end

htmlstore.getpage = function(htmlpage)
    
    local timestamp = htmlstore.getlastpagetime(htmlpage)
    if timestamp == nil then return nil end
    redis.connect()
    -- Do not check for previous ones, just add this to the time list.
    local htmldata = redis.call("get", pages_base_path..htmlpage.."/"..timestamp)
    redis.close()
    return htmldata or "<html></html>"
end

htmlstore.getallpages = function()
    
    local allpages = redis.hgetall( pages_base_path ) or {}
    return allpages
end

return htmlstore