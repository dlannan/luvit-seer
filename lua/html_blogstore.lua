local redis      = require('redis-tools')

-- These utilities help in working with the html files
--  stored in redis and how they are time saved/stored.

local DEFAULT_BLOG   = "content.default.theme.Default.blog"

local htmlstore = {}

-- Storage works like this:
---    The initial blog comes from either an already created blog, or from
---    a default provided blog. This blog gets an initial storage set in 
---    the "project/allblogs" directory in redis. 
---
---    blogs are stored by their last saved time UTC (to the server). The layout 
---    is that all time saved entries in the store are saved under the name of
--     the blog. Thus, project/allblogs/demo/index.html would have child blogs
---      project/allblogs/demo/index.html/0029382345  and others.
---
---    Using this method we can store all changes made to a html blog. When 
---    selecting a blog to edit, the admin will always get the latest revision
---    unless they specifically choose one from the dropdown time list (to be
---    implemented later)
---
---    This same method will be applied to blogs as well.

-- All blogs stored here
local blogs_base_path = _G.PROJECT.."/allblogs/"

-- These keys keep lists of the times that have been saved - thus able to regenerate the key needed to retrieve the html data.
local blogs_basetime_path = _G.PROJECT.."/allblogs/"


htmlstore.addblogtime = function( htmlblog, newtime )
    local currentlist = redis.hgetall( blogs_basetime_path..htmlblog ) or {}
    currentlist[#currentlist + 1] = newtime
    redis.hmset( blogs_basetime_path..htmlblog, currentlist )
end

htmlstore.getlastblogtime = function( htmlblog )
    local currentlist = redis.hgetall( blogs_basetime_path..htmlblog ) or {}
    return currentlist[#currentlist]
end

htmlstore.addblogdata = function( htmlblog )
    
    -- Create a blog dataset we can use for publishing and editing
    local thisblog = redis.hgetall( blogs_base_path .. htmlblog )
    if #thisblog == 0 then
        redis.hmset( blogs_base_path..htmlblog, { 
                blog=htmlblog,
                userblog=htmlblog,
                name=htmlblog, 
                template="Default",
                tags="blog",
                publish="",
                metatitle="",
                metadesc="",
                urlhandle="",
                blogimage=""
        } )
    else
        thisblog.blog=blog
        redis.hmset( blogs_base_path .. htmlblog, thisblog )
    end
end

htmlstore.getblogdata = function(htmlblog)
    local thisblog = redis.hgetall( blogs_base_path .. htmlblog )
    return thisblog
end

htmlstore.setblogdata = function(htmlblog, blogdata)
    redis.hmset( blogs_base_path .. htmlblog, blogdata )
end

htmlstore.newblog = function(htmlpage, htmldata)

    local newblogdata = rdis.call("get", DEFAULT_BLOG)
    
    -- Have the data now need to create a unique page name/path.
    local allblogs = redis.hgetall( blogs_base_path )
    
    if allblogs then
        local name = "blog.html"
        
        if allblogs[name] ~= nil then
            for i=1, 99 do
                name = string.format("blog%02d.html", i)
                if allblogs[name] == nil then
                    break     
                end
            end
        end
        
        htmlstore.addblog(name, newblogdata)
        return name
    end
    return "invalid.html"
end

htmlstore.addblog = function(htmlblog, htmldata)
    
    local allblogs = redis.hgetall( blogs_base_path ) or {}
    allblogs[htmlblog] = htmlblog
    redis.hmset( blogs_base_path, allblogs ) 
    
    htmlstore.addblogdata(htmlblog)
    
    -- Do not check for previous ones, just add this to the time list.
    local timestamp = os.time()
    redis.connect()
    redis.call("set", blogs_base_path..htmlblog.."/"..timestamp, htmldata)
    redis.close()
    htmlstore.addblogtime( htmlblog, timestamp )
end

htmlstore.getblog = function(htmlblog)
    
    local timestamp = htmlstore.getlastblogtime(htmlblog)
    if timestamp == nil then return nil end
    redis.connect()
    -- Do not check for previous ones, just add this to the time list.
    local htmldata = redis.call("get", blogs_base_path..htmlblog.."/"..timestamp)
    redis.close()
    return htmldata or "<html></html>"
end

htmlstore.getallblogs = function()

    local allblogs = redis.hgetall( blogs_base_path ) or {}
    return allblogs
end

return htmlstore