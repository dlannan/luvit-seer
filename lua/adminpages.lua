
-- Admin module is a helper system for preparing and adding modules into the
--  redis database.
-- Templates can also be generated using this module.
local redis = require("redis-tools")

local apages = {
    pages = {}     -- List of all pages that have been converted to editable
}

-- Fetch a page for editing, add it to local cache
apages.getpage = function(userid, pageid)

    -- Always do valid user check.
    local admin = _G.LOCALADMIN
    if admin.user.uid ~= userid then return nil end

    -- Internal page cache (quicker, and we can pre-process if needed)
    local fullkey = "/users/"..userid.."/"..pageid
    local lpage = apages.pages[fullkey]
    if lpage ~= nil then return lpage end

    -- look in redis for the user page
    redis.connect()
    local page = redis.getkey(fullkey)
    redis.close()

    apages.pages[fullkey] = page
    return page
end

-- Write a page to redis, add it to local cache
apages.writepage = function(userid, pageid, page)

    -- Always do valid user check.
    local admin = _G.LOCALADMIN
    if admin.user.uid ~= userid then return nil end

    -- Internal page cache (quicker, and we can pre-process if needed)
    local fullkey = "/users/"..userid.."/"..pageid
    local lpage = apages.pages[fullkey]
    if lpage ~= nil then apages.pages[fullkey]=page end

    redis.connect()
    redis.setkey(fullkey, page)
    redis.close()
end

-- Insert a block of text into a page at a specific location that is module relative
apages.pageinsert = function( userid, pageid, where, mid, block)

    local page = apages.getpage(userid, pageid)
    if page == nil then return end

    local f = 1
    local l = 1
    if where == nil then
        -- Find the place for insertion of the block.
        -- The where should be in format: module.fullscreenmedia.0
        local search = [[<main class="page__main">]]
        f, l = string.find(page, search)
    else
        -- Find the place for insertion of the block.
        -- The where should be in format: module.fullscreenmedia.0
        local search = string.format("%s+.*})}")
        f, l = string.find(page, search)
    end
    -- The last index is where insert will occur.
    page = string.sub(page, 1, l) .. block .. string.sub(page, l+1, -1)

    -- Write the page back to cache and redis.
    apages.writepage( userid, pageid, page )
end

return apages
