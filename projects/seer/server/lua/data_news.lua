
local redis     = require('redis-tools')
local image_data = require('data_images')

local news_list = "data.collection.newslist"
local news_list_uid = "data.collection.newslist.uid"
local news_data = "data.collection.news."
local news_dates = "data.collection.news.alldates"
local news_images = "data.collection.news.allimages"

local news = _G.NEWS

-- There can be only one session for any running instance of flod.
if news == nil then
    news = {}
    _G.NEWS = news
end

news.getuid = function()

    redis.connect()
    local id = redis.getkey( news_list_uid )
    if id == nil then id = 0 end
    id = id + 1
    redis.setkey( news_list_uid, id )
    redis.close()
    return id
end

news.set = function(index, data)
    
    redis.connect()
    -- Ignore any previous keys - they get blown away!!
    redis.hmset( news_data..index, data )
    
    -- Add to the list
    local newlist = redis.hgetall( news_list )
    newlist[index] = news_data..index
    redis.hmset( news_list, newlist )
    redis.close()
end

news.delete = function( index )

    redis.connect()
    -- Ignore any previous keys - they get blown away!!
    redis.delete( news_data..index )
    
    -- Add to the list
    local newlist = redis.hgetall( news_list )
    newlist[index] = nil
    redis.hmset( news_list, newlist )
    redis.close()
end

-- Get a specific carousel
news.get = function(index)
    
    local res = nil
    redis.connect()
    local dlist = redis.hgetall( news_data..index )
    if dlist ~= nil then
        res = dlist
    end
    redis.close()
    return res
end

news.getall = function()
    -- Load carousels from the database - this resets the current CAROUSEL object
    --   so this script can be called at any time. 
    local all = {}
    redis.connect()
    local newlist = redis.hgetall( news_list )
    redis.close()
    for idx, name in pairs( newlist ) do
        local dlist = news.get(idx)
        if dlist ~= nil then all[idx] = dlist end
    end
    -- Dont return empty tables - makes a mess of things.
    if next(all) == nil then alll = nil end
    return all
end 

news.readnews = function(idx)
    
    redis.connect()
    local evt = redis.hgetall( news_data..idx )
    redis.close()
    if evt == nil then return nil end
    --p(idx, evt)
    
    redis.connect()
    local newsobj = {}
    if evt.published == nil then evt.published = false end
    
    for k,v in pairs( evt ) do
        newsobj[k] = v
    end
    
    redis.close()
    return newsobj
end

-- This gets all news as an news object that can be used in the html 
news.readallnews = function()

    local res = {}
    local all = news.getall()
    redis.connect()
    
    for idx, evt in pairs(all) do
        if next(evt) ~= nil then
            local newsobj = {}
            if evt.published == nil then evt.published = false end

            for k,v in pairs( evt ) do
                newsobj[k] = v
            end
            res[idx] = newsobj
        end
    end
    redis.close()
    
    return res
end

-- Writes news data to the redis - converts from Form data to redis
news.writenews = function(index, data)
    
    if data.published == nil then data.published = false end
    local newnews = {}
    for k,v in pairs( data ) do
        newnews[k] = v
    end

    news.set( index, newnews )
end

news.jsontonews = function( json )
    
    --p(json)
    local tnews = {}
    -- set the main values
    if json.uid == nil then 
        tnews.uid = news.getuid()
    else
        tnews.uid = json.uid
    end
    tnews.title = json.title 
    tnews.tags = json.tags 
    tnews.description = json.description
    tnews.urlweb = json.urlweb 
    -- all news start unpublished
    tnews.published = false 
    tnews.image = json.image
    tnews.date = json.date
    tnews.when = json.when
    -- p("++++++++++++++>", json)
    -- p("-------------->", news)
    news.writenews( tnews.uid, tnews )    
end

-- Only publish or unpublish and news!
news.jsonpublish = function( json )
    
    --p(json)
    uid = json.uid -- Must have a uid to be able to do this!!!
    if uid == nil then return end
    
    local tnews = news.readnews( uid )
    tnews.published = json.published
    news.writenews( uid, tnews )
end

news.init = function()

    local newssample = { 
        title = "News Item 01",
        tags = "festival fringe adelaide fun",
        description = "Some Descriptin",
        urlweb = "http://",
        published = false,
        date = "20/02/2017",
        when = "10:00 AM",

        image = ""
    }

    newssample.uid = news.getuid()
    news.writenews( newssample.uid, newssample )
end

news.empty = function()
    local tnews = {}
    -- set the main values
    tnews.uid = news.getuid()
    tnews.title = ""
    tnews.tags = "" 
    tnews.description = ""
    tnews.urlweb = "" 
    tnews.date = ""
    tnews.when = ""
    -- all news start unpublished
    tnews.published = false
    tnews.image = ""
    return tnews
end

news.getfirstnews = function()
    local allnews = news.readallnews()
    return next(allnews)
end


return news
