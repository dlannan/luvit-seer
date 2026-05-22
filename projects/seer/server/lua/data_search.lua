local template = require "resty.template"
local fs = require('fs')
local pathJoin = require('luvi').path.join
local pathing = require('path')
local redis = require('redis-tools')

local uv = require('uv')

local path_assets = "/userassets/html/"
local project_path = _G.PROJECT
local edata = require('data_event')

-- Lua Resty specific setup
template.caching(false)

require('utils_table')

-- Searching group/namespace
local searching = {
    
    htmldata = {},
    eventtags = {},
    eventdata = {}
}

searching.collatehtml = function()
    
    -- Clear the data 
    searching.htmldata = {}
    
    -- All the html data is collated into page indexed text
    local htmlcollection = _G.USERASSETS['html']
    for key, page in pairs(htmlcollection) do

        coroutine.wrap( function() 
        
        local namelookup = key
        local htmlFilename = page
    
        local renderFilename = project_path..path_assets..namelookup
        if htmlFilename ~= nil then
            renderFilename = htmlFilename.projpath
        end
        
        --p(">>>>>>>>>>>>>", namelookup, htmlFilename, renderFilename)
        if fs.existsSync(renderFilename) then
            searching.htmldata[renderFilename] = template.render(renderFilename)
        end
        end)()
    end
end

-- The events should be collated regularly (everytime an event changes)
searching.collateevents = function()
        
    -- Clear the data 
    searching.eventtags = {}
    searching.eventdata = {}
    
    -- All the event description data is put into the searchdata table too.
    coroutine.wrap( function()
        local eventcollection = _G.EVENTS.readallevents()
        --p("Collate Events: ", eventcollection)

        for key, event in pairs(eventcollection) do

            if event.published == 'true' then
            searching.eventtags[event.uid] = event.tags
            searching.eventdata[event.uid] = string.format("%s %s", event.title, event.description )
            end
            --p(searching.eventdata[event.uid])
        end
    end)()
    -- THIS MAY TAKE A WHILE WITH LOTS OF DATA
    --  TODO: Add a lock to search if the setup isnt ready.
end

searching.collateall = function()
    
    -- Problem running collate html - Coroutine breaks. Need to examine later.
    --searching.collatehtml()
    searching.collateevents()
end


searching.findtext = function (text)
        
    local results = nil
    local wordlist = {}
    for s in string.gmatch(text,'%S+') do table.insert(wordlist, s) end
    
    local weight = {}
    local currword = 1
    
    -- Because the event space is small - do this everytime.
    --searching.collateevents()
    
    -- Iterate each word, if all words match, they get stronger rating - then
    --   output is ordered by weighting.
    for k, word in ipairs(wordlist) do 

        local searchword = string.lower(word)
        -- firstly try the tags - this is our key search filter.
        for k, v in pairs(searching.eventtags) do
            local searchtxt = string.lower(v)
            for w in string.gmatch(searchtxt, searchword) do
                if weight[k] == nil then weight[k] = { count=0, word=0, page=k, mode='tag' } end
                weight[k].count = weight[k].count + 1
                weight[k].word = bit.bor(weight[k].word, currword)
            end
        end
        currword = bit.lshift(currword, 1)
        -- Build tags results - these should be first anyway.
        
        -- Now try the events - second most important search
        for k, v in pairs(searching.eventdata) do
            local searchtxt = string.lower(v)
            for w in string.gmatch(searchtxt, searchword) do
                if weight[k] == nil then weight[k] = { count=0, word=0, page=k, mode='event' } end
                weight[k].count = weight[k].count + 1
                weight[k].word = bit.bor(weight[k].word, currword)
            end
        end
        
        
        -- Now try the html page itself - this may ne completely unneeded - consider removal.
        for k, v in pairs(searching.htmldata) do
            local searchtxt = string.lower(v)
            for w in string.gmatch(searchtxt, searchword) do
                if weight[k] == nil then weight[k] = { count=0, word=0, page=k, mode='html' } end
                weight[k].count = weight[k].count + 1
                weight[k].word = bit.bor(weight[k].word, currword)
            end
        end
        
    end
       
    -- only return top ten results - examine later if this needs to be extended.
    local finalresults = nil
    local rcount = 10
    
    for k, v in rpairs(weight) do
        if v then
            if finalresults == nil then finalresults = {} end
            local index = math.floor((1.0 / v.count) * 1000)
            table.insert(finalresults, index, v)
        end
        rcount = rcount - 1
        if rcount == 0 then break end
    end
    return finalresults
end

-- Go through our htm folders, render them, and store their text data
--    under the path names for recall.
-- Initial searches will be via regexes
searching.init = function()
    
    searching.collateall()
end
    

searching.search = function (req, res, go)
    
    local failure=nil
    
    --p(".............>", sock, req, res, go)
	if not req.params then return go() end
    local sock = uv.tcp_getpeername(req.socket)

    -- Only care about posts
    if req.method ~= "GET" then return go() end
    --p(req, res)

    -- This parser will check the html is valid
    local data = req.query.search
    -- Smash data into text.
    local results = searching.findtext(data)
    
    res.code = 200
    res.headers["Content-Type"] = "text/html"
    res.body = template.render(project_path..'/userassets/html/search-results.html', {results=results})
    return
end


return searching
