

-- Asset management pool
--  redis database.
-- Templates can also be generated using this module.
local ffi = require('ffi')
local fileio = require('fileio')
local fs = require('fs')
local imglib = require('imglib.cimg')
local pathJoin = require('luvi').path.join
local path = require('path')

local pp = require('pretty-print')

local valid_filters   = {}

valid_filters['.png']  = "images"
valid_filters['.jpeg'] = "images"
valid_filters['.jpg']  = "images"

valid_filters['.svg']  = "icons"

valid_filters['.mov']  = "videos"
valid_filters['.mp4']  = "videos"

valid_filters['.css']  = "css"

valid_filters['.html'] = "html"
valid_filters['.htm']  = "html"

local asetup  = {}
local path_userassets  = _G.PROJECT.."/userassets"
local path_images      = path_userassets.."/images"
local path_imagecache  = path_userassets.."/imagecache"

asetup.getFilename = function( outfname, ext, size )
    outfname = pathJoin(path_imagecache, outfname)
    outputfilename = outfname.."_S"..size..ext
    return outputfilename
end

asetup.getOriginalName = function ( fname )
    local s, e = string.find(fname, _G.PROJECT)
    if s ~= -1 then 
        local oname = string.sub(fname, e+1, -1)
        return oname
    end
    return fname
end

asetup.getFileRelative = function ( fname, filter )
    local s, e = string.find(fname, path_userassets.."/"..filter.."/" )
    if s and e then 
        local rname = string.sub(fname, e+1, -1)
        return rname
    end
    return fname
end

asetup.getSourceFile = function( srcfilename )
    local srcimg = imglib.loadImage(srcfilename)
    return srcimg
end    

asetup.imageCacheCreate = function(lookup, outputfilename, size)

    if lookup == nil then return end
    
    local width     = lookup.width
    local height    = lookup.height
    local aspect    = width / height
    local newwidth  = size
    local newheight = newwidth / aspect
    
    if aspect > 1.0 then 
        aspect = height / width
        newheight = size
        newwidth = newheight / aspect
    end

    local ext = string.lower(path.extname(outputfilename))
    local nojpeg = 1
    if ext == ".png" then nojpeg = 0 end
    -- p(lookup, outputfilename, nojpeg)
    
    local imgscaled = imglib.scaleImage(lookup, newwidth, newheight)
    imglib.saveImage( outputfilename, imgscaled, nojpeg )
    imglib.dropImage(imgscaled)

end

asetup.recurseFolders = function( folder )

    if folder == nil then return end 
    local stat = fs.statSync(folder)
    if stat == nil then 
        pp.color(pp.failure)
        pp("Invalid project folder: ", folder)
        return
    end

    local allimgs = fileio.read_path(folder)
    for k,v in pairs(allimgs) do

        local fname = pathJoin(folder, v)
        local stat = fs.statSync(fname)
        if stat.type == 'directory' then
            
            if v ~= "imagecache" then
                asetup.recurseFolders(fname)
            end
        else 
            
            local ext = string.lower(path.extname(fname))
            local filter = valid_filters[ext]
            --p(v, fname, filter)
            
            if filter ~= nil then
                collection = _G.USERASSETS[filter]
                local oname = asetup.getOriginalName(fname)
                
                cache = _G.USERASSETS["imagecache"]

                if filter == "images" and (cache[v] == nil or (collection[v] ~= fname)) then
                    local outfname = path.basename(fname, "")
                    outfname = string.gsub(outfname, "%..+$","")

                    local lookup = nil 

                    local savedfileL = asetup.getFilename(outfname, ext, 512)
                    local savedfileM = asetup.getFilename(outfname, ext, 768)
                    local savedfileH = asetup.getFilename(outfname, ext, 1024)
                    -- local savedfileVH = asetup.getFilename(outfname, ext, 2048)

                    if fs.existsSync(savedfileL) == false then
                        lookup = lookup or asetup.getSourceFile(fname)
                        asetup.imageCacheCreate(lookup, savedfileL, 512)
                    end
                    if fs.existsSync(savedfileM) == false then                        
                        lookup = lookup or asetup.getSourceFile(fname)
                        asetup.imageCacheCreate(lookup, savedfileM, 768)
                    end
                    if fs.existsSync(savedfileH) == false then
                        lookup = lookup or asetup.getSourceFile(fname)
                        asetup.imageCacheCreate(lookup, savedfileH, 1024)
                    end
                    -- if fs.existsSync(savedfileVH) == false then
                    --     lookup = lookup or asetup.getSourceFile(fname)
                    --     asetup.imageCacheCreate(lookup, savedfileVH, 2048) 
                    -- end

                    cache[v] = { }
                    cache[v].path   = oname
                    cache[v].L      = savedfileL
                    cache[v].M      = savedfileM
                    cache[v].H      = savedfileH
                    -- cache[v].V      = savedfileVH

                    if lookup ~= nil then 
                        imglib.dropImage(lookup)
                        lookup.pixels = nil 
                    end
                end

                local relpath = asetup.getFileRelative(fname, filter)
                -- p(folder, v, fname, oname)
                if filter == "html" then
                    -- Dont use project paths in weblinks!! They are inserted at the end.
                    _G.WEBLINKS[v] = oname 
                end
                
                collection[relpath] = { filename = fname, origpath = oname, projpath = fname }
                --p(relpath)
            end
        end
    end
end

asetup.updateImages = function()
    
    -- build image cache if not built!!!
    asetup.recurseFolders( path_images )     
end
        
-- Add all the modules with all the basic setups
asetup.init = function ()

    _G.USERASSETS["imagecache"]  = {}
    _G.USERASSETS["images"]      = {}
    _G.USERASSETS["videos"]      = {}
    _G.USERASSETS["icons"]       = {}
    _G.USERASSETS["css"]         = {}
    _G.USERASSETS["html"]        = {}

    asetup.recurseFolders(path_userassets)
end

-- Assets are only loaded from file if the data isnt in redis
asetup.processHtml = function() 
    
    local allhtml = _G.USERASSETS["html"]
    for k,v in pairs(allhtml) do

        if string.find(k, "blog") == nil then
            local rdata = _G.HTMLPAGES.getpage(k)
            if rdata == nil then
                _G.HTMLPAGES.addpage(k, fileio.read_file(v.filename))
            end
        else
            local rdata = _G.HTMLBLOGS.getblog(k)
            if rdata == nil then
                _G.HTMLBLOGS.addblog(k, fileio.read_file(v.filename))
            end
        end
    end
end

return asetup
