local htmlps = require('htmlparser')

local next = next

-- print the tree
local function htmlprint(n)
    if n == nil or n.level == nil then return end
    local space = string.rep("  ", n.level)
    local s = space .. n.name
    for k,v in pairs(n.attributes) do
        s = s .. " " .. k .. "=[[" .. v .. "]]"
    end
    print(s)
    for i,v in ipairs(n.nodes) do
        p(v)
    end
end

-- Default function to add a template (resty) to the html
function defaultdata(id, d, r)
    if d == nil then return "" end
    local tbl = htmlps.parse(d)
    local datastring = ""

    if id == nil then id = "0" end
    datastring = datastring..'id='..'[['..id..']]'
    return datastring
end

-- Nearly all modules are wrapped in containers - a simple function helper for this.
function containerwrap(intext, d )

    local txt = [[<div class="container">
      <div class="image-grid">]]

    local containersize = "container"
    if d:find("container fullwidth") ~= nil then
        containersize = "container fullwidth"
    end

    if d:find("image%-carousel") ~= nil then
      txt = [[<div class="]]..containersize..[[">
        <div class="image-carousel">]]
    end

    if d:find("image%-grid") ~= nil  then
      txt = [[<div class="]]..containersize..[[">
        <div class="image-grid">]]
    end

    if d:find("image%-masonry") ~= nil  then
      txt = [[<div class="]]..containersize..[[">
        <div class="image-masonry">]]
    end
    
    txt = txt..intext
    txt = txt..[[</div>]]
    return txt, containersize
end

-- Banner module generator to use module html to rebuild module from template
function bannertext( id, d, r )
    if d == nil then return "" end
    local tbl = htmlps.parse(d)
    local datastring = ""

    if id == nil then id = "0" end
    datastring = datastring..'id='..'[['..id..']]'
    
    local txt = [[<div class="container text-center paintarea">
      <div class="editable painttext">]]

    local containersize = "container"
    local extraclasses = ""
    if d:find("container fullwidth") ~= nil then
        containersize = "container fullwidth"
    end    
    
    local elements = tbl("div.editable")
    for _,e in ipairs(elements) do
        local innerContent = e:getcontent()
        if innerContent ~= nil then txt = txt..innerContent end
    end
    txt = txt..[[</div>]]
    txt = txt..[[</div>]]
    
    txt = string.gsub(txt, "%%", "%%%%")
    datastring = datastring..', inputtext=[['..txt..']]'
    return datastring
end

function carouseldata( id, d, r )
    if d == nil then return "" end
    local tbl = htmlps.parse(d)
    local datastring = ""

    if id == nil then id = "0" end
    datastring = datastring..'id='..'[['..id..']]'

    local txt = ""
    local elements = tbl("img")
    for _,e in ipairs(elements) do
        local src = e.attributes['src']
        --txt = txt..[[<div class="image-container col-md-4">]]
        local onclick = srcNode[1].attributes['onclick'] or ""
        if #onclick > 0 then onclick = 'onclick="'..onclick..'" ' end
        txt = txt..(string.format('<img src="%s" %s />', src, onclick))
        --txt = txt..[[</div>]]
    end
    txt = txt..[[</div>]]

    txt = containerwrap(txt, d, r)
    
    txt = string.gsub(txt, "%%", "%%%%")
    datastring = datastring..', inputmediaset=[['..txt..']]'
    return datastring
end

function feeddata( id, d, r )
    if d == nil then return "" end
    local tbl = htmlps.parse(d)
    local datastring = ""

    if id == nil then id = "0" end
    datastring = datastring..'id='..'[['..id..']]'

    local txt = [[<div class="container">]]
    local elements = tbl("feed%-instagram")
    for _,e in ipairs(elements) do
        if e.parent ~= nil then
            local src = e.attributes['data%-src']
            txt = txt..[[<div class="col-md-4 col-sm-6">]]
            txt = txt..(string.format('<div class="feed-instagram" data-src="%s"></div>', src))
            txt = txt..[[</div>]]
        end
    end
    txt = txt..[[</div>]]

    txt = string.gsub(txt, "%%", "%%%%")
    datastring = datastring..', mediafeeds=[['..txt..']]'
    return datastring  
end

function mediasetdata( id, d, r )
    if d == nil then return "" end
    local tbl = htmlps.parse(d)
    local datastring = ""

    if id == nil then id = "0" end
    datastring = datastring..'id='..'[['..id..']]'

    local txt = ""
    local extraclasses = ""
    if d:find("image%-grid") ~= nil  then
        extraclasses = " col-md-4"
    end
    if r:find("fullscreenmedia.html") ~= nil then 
        extraclasses = " col-md-12"
    end

    local elements = tbl(".image-container")
    for _,e in ipairs(elements) do
        local iscloned = nil
        for i, cname in pairs(e.classes) do
            if cname == "slick-cloned" then iscloned = true end
        end 
        
        if iscloned == nil then
            --htmlprint(e)
            local etbl = htmlps.parse(e:getcontent())
            local srcNode = etbl("img")
            local usertextNode = etbl(".image-text")

            txt = txt..[[<div class="image-container]]..extraclasses..[[">]]
            if srcNode[1] ~= nil then
                local src = srcNode[1].attributes['src'] or ""
                local onclick = srcNode[1].attributes['onclick'] or ""
                if #onclick > 0 then onclick = 'onclick="'..onclick..'" ' end
                txt = txt..(string.format('<img src="%s" %s />', src, onclick))
            end
            if usertextNode[1] ~= nil then
                local thestyle = usertextNode[1].attributes['style'] or ""

                local usertext = usertextNode[1]:getcontent()
                txt = txt..[[<div class="image-text-wrapper">]]
                txt = txt..[[<div class="image-text editable painttext paint-area paint-area--text" style="]]..thestyle..[[" >]]
                txt = txt..usertext
                txt = txt..[[</div> </div>]]
            end
            txt = txt..[[</div>]]
        end
    end
    txt = txt..[[</div>]]

    txt = containerwrap(txt, d)

    txt = string.gsub(txt, "%%", "%%%%")
    datastring = datastring..', inputmediaset=[['..txt..']]'
    return datastring
end

function mediasetleft( id, d, r )
    if d == nil then return "" end
    local tbl = htmlps.parse(d)
    local datastring = ""

    if id == nil then id = "0" end
    datastring = datastring..'id='..'[['..id..']]'

    local txt = ""

    local elements = tbl(".image-container")
    for _,e in ipairs(elements) do
        --htmlprint(e)
        local etbl = htmlps.parse(e:getcontent())
        local srcNode = etbl("img")
        local usertextNode = etbl(".image-text")
        
        txt = txt..[[<div class="image-container col-md-12">]]
        if srcNode[1] ~= nil then
            local src = srcNode[1].attributes['src']
            local onclick = srcNode[1].attributes['onclick'] or ""
            if #onclick > 0 then onclick = 'onclick="'..onclick..'" ' end
            txt = txt..(string.format('<img src="%s" %s />', src, onclick))
        end
        txt = txt..[[</div>]]
    end
    txt = txt..[[</div>]] 
    
    usertxt = ""
    local elements = tbl("div.editable")
    for _,e in ipairs(elements) do
        local innerContent = e:getcontent()
        if innerContent ~= nil then usertxt = usertxt..innerContent end
    end
    
    txt, containersize = containerwrap(txt, d)
    txt = string.gsub(txt, "%%", "%%%%")
    datastring = datastring..', inputmediaset=[['..txt..']]'
    datastring = datastring..', inputtext=[['..usertxt..']]'
    datastring = datastring..', inputcontainer=[['..containersize..']]'
    return datastring
end

function imagedata( id, d, r )
    if d == nil then return "" end
    local tbl = htmlps.parse(d)
    local datastring = ""

    if id == nil then id = "0" end
    datastring = datastring..'id='..'[['..id..']]'

    local txt = [[<div class="container">
      <div class="image-grid">]]

    local containersize = "container"
    if d:find("container fullwidth") ~= nil then
        containersize = "container fullwidth"
    end
    
    local elements = tbl(".image-container")
    for _,e in ipairs(elements) do
        local iscloned = nil
        for i, cname in pairs(e.classes) do
            if cname == "slick-cloned" then iscloned = true end
        end 
        
        if iscloned == nil then
            --htmlprint(e)
            local etbl = htmlps.parse(e:getcontent())
            local srcNode = etbl("img")
            local usertextNode = etbl(".image-text")

            txt = txt..[[<div class="image-container">]]
            if srcNode[1] ~= nil then
                local src = srcNode[1].attributes['src']
                local onclick = srcNode[1].attributes['onclick'] or ""
                if #onclick > 0 then onclick = 'onclick="'..onclick..'" ' end
                txt = txt..(string.format('<img src="%s" %s />', src, onclick))
            end
            if usertextNode[1] ~= nil then
                local thestyle = usertextNode[1].attributes['style'] or ""
                local usertext = usertextNode[1]:getcontent()
                txt = txt..[[<div class="image-text-wrapper">]]
                txt = txt..[[<div class="image-text editable painttext paint-area paint-area--text" style="]]..thestyle..[[" >]]
                txt = txt..usertext
                txt = txt..[[</div> </div>]]
            end
            txt = txt..[[</div>]]
        end
    end
    txt = txt..[[</div>]]
    txt = txt..[[</div>]]

    txt = string.gsub(txt, "%%", "%%%%")
    datastring = datastring..', inputmediaset=[['..txt..']]'
    return datastring

end
