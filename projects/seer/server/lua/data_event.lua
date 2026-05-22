
local redis     = require('redis-tools')
local image_data = require('data_images')

local event_list = "data.collection.eventlist"
local event_list_uid = "data.collection.eventlist.uid"
local event_data = "data.collection.events."
local event_dates = "data.collection.events.alldates"
local event_images = "data.collection.events.allimages"

local events = _G.EVENTS

-- There can be only one session for any running instance of flod.
if events == nil then
    events = {}
    _G.EVENTS = events
end

events.getuid = function()

    local id = redis.getkey( event_list_uid )
    if id == nil then id = 0 end
    id = id + 1
    redis.setkey( event_list_uid, id )
    return id
end

events.set = function(index, data)
    
    -- Ignore any previous keys - they get blown away!!
    redis.hmset( event_data..index, data )
    
    -- Add to the list
    local newlist = redis.hgetall( event_list )
    newlist[index] = event_data..index
    redis.hmset( event_list, newlist )
end

events.delete = function( index )

    -- Ignore any previous keys - they get blown away!!
    redis.delete( event_data..index )
    
    -- Add to the list
    local newlist = redis.hgetall( event_list )
    newlist[index] = nil
    redis.hmset( event_list, newlist )
end

-- Get a specific carousel
events.get = function(index)
    
    local res = nil
    local dlist = redis.hgetall( event_data..index )
    if dlist ~= nil then
        res = dlist
    end
    return res
end

events.getall = function()
    -- Load carousels from the database - this resets the current CAROUSEL object
    --   so this script can be called at any time. 
    local all = {}
    local newlist = redis.hgetall( event_list )
    for idx, name in pairs( newlist ) do
        local dlist = events.get(idx)
        if dlist ~= nil then all[idx] = dlist end
    end
    -- Dont return empty tables - makes a mess of things.
    if next(all) == nil then all = nil end
    return all
end 

events.readevent = function(idx)
    
    local evt = redis.hgetall( event_data..idx )
    if evt == nil then return nil end
    --p(idx, evt)
    
    local eventobj = {}
    if evt.published == nil then evt.published = false end
    
    for k,v in pairs( evt ) do
        if k ~= 'dates' and k~= 'images' then
            eventobj[k] = v
        end
    end
    
    local dates = {}
    -- Dates is just a list of indexes - convert to int
    for num in evt.dates:gmatch("%d+") do
        local dateidx = tonumber(num)
        local evtdatekey = event_dates.."."..evt.uid.."."..dateidx
        local datedata = redis.hgetall( evtdatekey )
        if datedata ~= nil then
            table.insert( dates, datedata )
        end
    end 
    eventobj.dates = dates

    eventobj.images = evt.images
    return eventobj
end

-- This gets all events as an event object that can be used in the html 
events.readallevents = function()

    local res = {}
    local all = events.getall()
    if(all == nil) then return res end

    for idx, evt in pairs(all) do
        if next(evt) ~= nil then
            local eventobj = {}
            if evt.published == nil then evt.published = false end

            for k,v in pairs( evt ) do
                if k ~= 'dates' and k~= 'images' then
                    eventobj[k] = v
                end
            end

            local thedates = {}
            -- Dates is just a list of indexes - convert to int
            for num in evt.dates:gmatch("%d+") do
                local dateidx = tonumber(num)
                local evtdatekey = event_dates.."."..evt.uid.."."..dateidx
                local datedata = redis.hgetall( evtdatekey )
                if datedata ~= nil then
                    table.insert( thedates, datedata )
                end
                --p( evtdatekey, datedata )
            end 
            eventobj.dates = thedates
            eventobj.images = evt.images
            res[idx] = eventobj
        end
    end
    
    return res
end

-- Writes event data to the redis - converts from Form data to redis
events.writeevent = function(index, data)
    
    if data.published == nil then data.published = false end
    local newevent = {}
    for k,v in pairs( data ) do
        if k ~= 'dates' and k~= 'images' then
            newevent[k] = v
        end
    end

    local evtdate = data.dates
    local dateidxs = ""
    --p(evtdate)
    if evtdate ~= nil then 
        local thedates = {}
        for k, d in pairs( evtdate ) do
            table.insert( thedates, d )
            dateidxs = dateidxs.." "..k
            local evtdatekey = event_dates.."."..data.uid.."."..k
            redis.hmset( evtdatekey, d )
            --p( evtdatekey, d )
        end
    end
    --p("dates:", dateidxs)
    newevent.dates = dateidxs 
    
    local evtimages = data.images
    local imageidxs = ""    
    
    if evtimages ~= nil then
        imageidxs = evtimages
    end
    newevent.images = imageidxs
    
    events.set( index, newevent )
end

events.jsontoevent = function( json )
    
    --p(json)
    local event = {}
    -- set the main values
    if json.uid == nil then 
        event.uid = events.getuid()
    else
        event.uid = json.uid
    end
    event.title = json.title 
    event.tags = json.tags 
    event.genre = json.genre
    event.description = json.description
    event.urlweb = json.urlweb 
    event.urltickets = json.urltickets 
    event.nophone = json.nophone 
    event.nofax = json.nofax
    event.email = json.email 
    event.urlcontact = json.urlcontact
    -- all events start unpublished
    event.published = false
    event.dates = {}
    event.images = nil
    
    -- Get the dates
    for k,v in pairs( json ) do
        if string.match(k, "dates_date_%d+") ~= nil then
            local idx = tonumber(string.match(k, "dates_date_(%d+)"))
            if event.dates[idx] == nil then event.dates[idx] = {} end 
            event.dates[idx]['date'] = v
        end
        if string.match(k, "dates_where_%d+") ~= nil then
            local idx = tonumber(string.match(k, "dates_where_(%d+)"))
            if event.dates[idx] == nil then event.dates[idx] = {} end 
            event.dates[idx]['where'] = v
        end
        if string.match(k, "dates_when_%d+") ~= nil then
            local idx = tonumber(string.match(k, "dates_when_(%d+)"))
            if event.dates[idx] == nil then event.dates[idx] = {} end 
            event.dates[idx]['when'] = v
        end
    end

    -- p("++++++++++++++>", json)
    -- p("-------------->", event)
    events.writeevent( event.uid, event )    
    
    -- Images are a little trickier...
    for k,v in pairs( json.images ) do
        evt = events.readevent(event.uid)
        -- p('----> ', evt.images)
        image_data.addeventimage( evt, v.dataname, v.src )
    end
end

-- Only publish or unpublish and event!
events.jsonpublish = function( json )
    
    --p(json)
    uid = json.uid -- Must have a uid to be able to do this!!!
    if uid == nil then return end
    
    local event = events.readevent( uid )
    event.published = json.published
    events.writeevent( uid, event )
end

events.init = function()

    local eventsample = { 
        title = "SA Festival",
        genre = "ALL",
        tags = "festival fringe adelaide fun",
        description = "Some Descriptin",
        urlweb = "http://",
        urltickets = "http://",
        nophone = "",
        nofax = "",
        email = "",
        urlcontact = "http://",
        published = false,
        
        dates = {
            [1] = { date="30/01/2017", where="Marion Cultural Center", when="5:40 PM" },
            [2] = { date="04/03/2017", where="Prospect Town Hall", when="8:03 PM" },
            [3] = { date="13/01/2017", where="Shedley Theatre", when="7:00 AM" },
            [4] = { date="23/01/2017", where="The Parks Theatre", when="2:00 PM" }
        },
        images = ""
    }

    eventsample.uid = events.getuid()
    events.writeevent( eventsample.uid, eventsample )
end

events.empty = function()
    local event = {}
    -- set the main values
    event.uid = events.getuid()
    event.title = ""
    event.tags = "" 
    event.description = ""
    event.urlweb = "" 
    event.urltickets = "" 
    event.nophone = "" 
    event.nofax = ""
    event.email = "" 
    event.urlcontact = ""
    -- all events start unpublished
    event.published = false
    event.dates = {}
    event.images = ""
    return event
end

events.getfirstevent = function()
    local allevents = events.readallevents()
    return next(allevents)
end

return events
    