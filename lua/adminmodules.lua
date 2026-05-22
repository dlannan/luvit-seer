
-- Admin module is a helper system for preparing and adding modules into the
--  redis database.
-- Templates can also be generated using this module.
local redis = require("redis-tools")

local pages = require("adminpages")

local amodules = {
    restyblocks = {},     -- List of all available modules to be instantiated (by module key name)
}

amodules.addtemplate = function( mid, block )

    -- TODO: Check the block for any inconsistencies
    amodules.restyblocks[mid] = block
end

-- Adding a new module to a page:
--  -- Check for valid module
--  -- Add the module block to the redis db
--  -- update the page data with the module insert
--  Prevmid is the module id before this module to insert (if nil, its the first)
amodules.newmodule = function( userid, pageid, prevmid, mid )

  -- First things first. Always check the user is the admin and is allowed to do this.
  local admin = _G.LOCALADMIN
  if admin.user.uid ~= userid then return end

  local midblock = amodules.restyblocks[mid]
  if midblock == nil then return end

  -- Get the page the user wishes to add module to.
  pages.pageinsert(userid, pageid, prevmid, mid, midblock)
end


return amodules
