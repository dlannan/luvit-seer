

-- Admin module is a helper system for preparing and adding modules into the
--  redis database.
-- Templates can also be generated using this module.
local amodules = require("adminmodules")
local fileio = require("fileio")
local pathJoin = require('luvi').path.join
local path = require('path')
local fs = require('fs')

local msetup  = {}

local path_modules = "lua/modules"

msetup.loadfiletype = function( htmlfilename, ext, store )
    local restyfilename = pathJoin(path_modules,htmlfilename)..ext
    if fs.existsSync(restyfilename) ~= nil then
        --print(restyfilename)
        local filedata = fileio.read_file(restyfilename)
        if filedata ~= nil then
            local f,l = string.find(filedata, htmlfilename)
            if f and l then
                amodules.addtemplate("module-"..htmlfilename, filedata)
                store["module-"..htmlfilename] = filedata
            end
        end
    end
end

-- Add all the modules with all the basic setups
msetup.init = function ()

    -- Iterate the modules folder for all the modules that can be used.
    local allfiles = fileio.read_path(path_modules)
    if allfiles ~= nil then
        for k,v in pairs(allfiles) do

            local ext = path.extname(v)
            local htmlfilename = path.basename(v,"html")
            htmlfilename = string.sub(htmlfilename, 1, -2)

            if fs.existsSync(htmlfilename) ~= nil and ext == ".html" then
                local filedata = fileio.read_file(pathJoin(path_modules, v))
                -- Dodgy store for temporary use!!!
                _G.MODULES["module-"..htmlfilename] = pathJoin(path_modules, v)
            end

            -- if the file is a lua file, then check its contents and add to modules
            if ext == ".html" then
                  --print("LuaFileName:", luafilename)
                msetup.loadfiletype(htmlfilename, ".resty", _G.RESTYS)
                msetup.loadfiletype(htmlfilename, ".js", _G.JSS)
            end
        end
    end
end


return msetup
