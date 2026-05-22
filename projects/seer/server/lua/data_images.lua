
local redis     = require('redis-tools')

local images_list = "data.collection.imageslist"
local images_data = "data.collection.images."

local images = _G.IMAGES

-- There can be only one session for any running instance of flod.
if images == nil then
    images = { }
    _G.IMAGES = images
end

-- Set is the same as modify, and add
images.set = function(index, data)
    
    redis.connect()
    -- Ignore any previous keys - they get blown away!!
    redis.hmset( images_data..index, data )
    -- Add to the list
    local newlist = redis.hgetall( images_list )
    newlist[index] = true
    redis.hmset( images_list, newlist )
    redis.close()
end

-- Get a specific carousel
images.get = function(index)
    
    local res = nil
    
    redis.connect()
    local dlist = redis.hgetall( images_data..index )
    if dlist ~= nil then
        res = dlist
    end
    
    redis.close()
    return res
end

images.getall = function()
    -- Load carousels from the database - this resets the current CAROUSEL object
    --   so this script can be called at any time. 
    local all = {}
    
    redis.connect()
    local newlist = redis.hgetall( images_list )
    for idx, name in pairs( newlist ) do
        local dlist = redis.hgetall( images_data..idx )   
        if dlist ~= nil then all[idx] = dlist end
    end
    return all
end 


images.empty = function()
    
    local event_images = {
        imagelist = " 1 3 8",
        -- List of images that are published (some can be unpublised if needed)
        published = ""
    }
    
    return event_images
end 

-- Image data is in base64 - can use right away
images.addeventimage = function( event, fname, imgdata )

    if event ~= nil then
        
        local imglist = event.images 
        local index = 0
        if imglist ~= nil then 
            -- Get the highest indexed image and add 1 - then store this in the image db
            for num in imglist:gmatch("%d+") do
                if tonumber(num) > index then index = tonumber(num) end
            end
        else
            event.images = ""
        end
        index = index + 1
        
        -- Add to end of event list
        event.images = event.images.." "..index
        
        -- write back to DB!!!
        _G.EVENTS.writeevent( event.uid, event )
        images.set( event.uid.."."..index, { idata=imgdata, name=fname } )
    end
end  

images.addimage = function( fname, imgdata )
    
    -- Get the current event - if not set, then dont do anything!!
    if _G.EVENT_EDIT == nil then p("Warn: No event selected."); return end
    
    -- Get the appropriate event
    local event = _G.EVENTS.readevent( _G.EVENT_EDIT.uid )
    images.addeventimage(event, fname, imgdata )
end

images.readeventimage = function( event, index )
    
    if event ~= nil then
        
        local imglist = event.images 
        if imglist ~= nil then
            -- Get the image that matches the index number!!
            local count = 1
            for num in imglist:gmatch("%d+") do
                if count == index then
                    imgdata = images.get(event.uid.."."..num )
                    return imgdata 
                end
                count = count + 1
            end
        end
    end 
    return nil
end
   
images.readimage = function( index )
    
    -- Get the current event - if not set, then dont do anything!!
    if _G.EVENT_EDIT == nil then p("Warn: No event seleted."); return nil end
    local event = _G.EVENTS.readevent( _G.EVENT_EDIT.uid )
    return readeventimage( event, index )
end 
    
images.readimages = function( eventid )

    local collection = {} 
    -- Get the current event - if not set, then dont do anything!!
    if _G.EVENT_EDIT == nil and eventid == nil then 
        p("Warn: No event seleted."); 
        return collection 
    end
    
    if eventid == nil then
        eventid = _G.EVENT_EDIT.uid
    end

    local event = _G.EVENTS.readevent( eventid )
    -- p(event, _G.EVENT_EDIT.uid)
    if event ~= nil then
        
        local imglist = event.images 
        if imglist ~= nil then
            -- Get the highest indexed image and add 1 - then store this in the image db
            for num in imglist:gmatch("%d+") do
                local imgdata = images.get( event.uid.."."..num )
                collection[num] = imgdata
            end
        end
    end 
    return collection
end

return images