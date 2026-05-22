
local redis     = require('redis-tools')

local carousel_list = "data.collection.carousellist"
local carousel_list_uid = "data.collection.carousellist.uid"
local carousel_data = "data.collection.carousel."

local carousel = _G.CAROUSEL

-- There can be only one session for any running instance of flod.
if carousel == nil then
    carousel = {}
    _G.CAROUSEL = carousel
end

carousel.getuid = function()

    local id = redis.getkey( carousel_list_uid )
    if id == nil then id = 0 end
    id = id + 1
    redis.setkey( carousel_list_uid, id )
    redis.close()
    return id
end

-- Set is the same as modify, and add
carousel.set = function(index, data)
    
    -- Ignore any previous keys - they get blown away!!
    redis.hmset( carousel_data..index, data )
    -- Add to the list
    local newlist = redis.hgetall( carousel_list )
    newlist[index] = true
    redis.hmset( carousel_list, newlist )
    redis.close()
end

-- Get a specific carousel
carousel.get = function(index)
    
    local res = nil
    
    local dlist = redis.hgetall( carousel_data..index )
    if dlist ~= nil then
        res = dlist
    end
    
    redis.close()
    return res
end

carousel.getall = function()
    -- Load carousels from the database - this resets the current CAROUSEL object
    --   so this script can be called at any time. 
    local all = {}
    
    local newlist = redis.hgetall( carousel_list )
    if newlist then
        for idx, name in pairs( newlist ) do
            local dlist = redis.hgetall( carousel_data..idx )   
            if dlist ~= nil then all[idx] = dlist end
        end
    end
    return all
end 

carousel.clearall = function()

    local newlist = redis.hgetall( carousel_list )
    for idx, name in pairs( newlist ) do
        redis.delete( carousel_data..idx )   
    end
    redis.delete( carousel_list )
    redis.close()
end

carousel.empty = function()

    carousel_data = {
        image = "",
        title = "No Title",
        description = "Empty Description",
        link = ""
    }

    return carousel_data
end 


carousel.jsontocarousel = function( json )
    
    -- remove all carousels, because we submit them all at once!
    carousel.clearall()
    -- THe json is a "list" of carousels.. so iterate them 
    for key, car in pairs(json) do
        --p(json)
        local cdata = {}
        -- set the main values
        if tonumber(car.uid) == 0 then 
            cdata.uid = carousel.getuid()
        else
            cdata.uid = tostring(car.uid)
        end
        cdata.title = car.title 
        cdata.description = car.description
        cdata.urlweb = car.link 
        cdata.published = false
        cdata.image = car.image
        carousel.set( cdata.uid, cdata )
        --p("New Carousel: ", key, cdata.uid, car.title, car.description)
    end
end
return carousel