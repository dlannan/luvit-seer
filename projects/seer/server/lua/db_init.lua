
local fileio = require('fileio')
local argon2 = require('argon2')
local timer = require('timer')

local gencontent = {}
local argon2_pwd = argon2.makepwd

local template = require "resty.template"
local fs = require('fs')
local redis = require('redis-tools')

local path_assets = "/userassets/html/"
local project_path = _G.PROJECT

local events = _G.EVENTS
local search = _G.SEARCH

_G.VENUES = {}
_G.VENUES['Shedley Theatre'] = { 
    name="Shedley Theatre, Elizabeth", 
    url="/venue-shedleytheatre.html", 
    image="/userassets/images/ShedleyTheatre.jpg",
    seating="/userassets/images/ShedleyTheatre.jpg"
}
--_G.VENUES['Star Theatres'] = { 
--    name="Star Theatres, Hilton", 
--    url="/venue-startheatreshilton.html", 
--    image="/userassets/images/StarTheatres.jpg" 
--}
_G.VENUES['Marion Cultural Center'] = { 
    name="Marion Cultural Center", 
    url="/venue-marionculturalcentre.html", 
    image="/userassets/images/MarionCulturalCentre.jpg",
    seating="/userassets/images/MarionCulturalCentre.jpg"
}
_G.VENUES['The Arts Centre'] = { 
    name="The Arts Centre, Pt. Noarlunga", 
    url="/venue-theartscentreptnoarlunga.html", 
    image="/userassets/images/TheArtsCentre.jpg",
    seating="/userassets/images/TheArtsCentre.jpg"
}
_G.VENUES['Golden Grove Arts Centre'] = { 
    name="Golden Grove Arts Centre", 
    url="/venue-goldengroveartscentre.html", 
    image="/userassets/images/GoldenGroveArtsCentre.jpg",
    seating="/userassets/images/GoldenGroveArtsCentre.jpg"
}
_G.VENUES['Murray Bridge Town Hall'] = { 
    name="Murray Bridge Town Hall", 
    url="/venue-murraybridgetownhall.html", 
    image="/userassets/images/MurrayBridgeTownHall.jpg",
    seating="/userassets/images/MurrayBridgeTownHall.jpg"
}
-- _G.VENUES['Woodville Town Hall'] = { 
--    name="Woodville Town Hall", 
--    url="/venue-woodvilletownhall.html", 
--    image="/userassets/images/WoodvilleTownHall.jpg" 
--}
_G.VENUES['Prospect Town Hall'] = { 
    name="Prospect Town Hall", 
    url="/venue-prospecttownhall.html", 
    image="/userassets/images/ProspectTownHall.jpg",
    seating="/userassets/images/ProspectTownHall.jpg" 
}
_G.VENUES['The Parks Theatre'] = { 
    name="The Parks Theatre", 
    url="/venue-theparkstheatre.html", 
    image = "/userassets/images/TheParksTheatre.jpg",
    seating={
        ["Theatre 1"] = "/userassets/images/TheParksTheatre_seating.jpg",
        ["Theatre 2"] = "/userassets/images/TheParksTheatre_seating2.jpg"        
    } 
}

local oots_admin_email = "oots.administration.email"
--local inital_email = "arusso@playford.sa.gov.au"
local inital_email = "dlannan_temp@gagagames.com"

gencontent.init = function()

    coroutine.wrap( function() 

    -- Add some default admin user information
    local admin = _G.LOCALADMIN
    
    local pw1, err =  argon2_pwd('kakutaiWDP1')   
    local pw2, err =  argon2_pwd('kakutaiWDP2')   
    local pw3, err =  argon2_pwd('kakutaiWDP3')   
    local pw4, err =  argon2_pwd('kakutaiWDP4')   
    local pw5, err =  argon2_pwd('kakutaiWDP5')   
    local pw6, err =  argon2_pwd('kakutaiWDP6')   
    local pw7, err =  argon2_pwd('kakutaiWDP20')   
        
--        p( pw1, "dlannan@gagagames.com" )
--        p( pw2, "zlannan@teamxirix.com" )
--        p( pw7, "arusso@playford.sa.gov.au" )
        
    admin.adduser( pw1, "dlannan@gagagames.com" )
    admin.adduser( pw2, "zlannan@teamxirix.com" )
    admin.adduser( pw7, "arusso@playford.sa.gov.au" )

    events.init()
    
    _G.SESSIONS.SESSION_EXIT = "login.html"
            
    local email = redis.getkey(oots_admin_email)      
    if email == nil then redis.setkey(oots_admin_email, inital_email) end
    _G.OOTS_EMAIL = redis.getkey(oots_admin_email)   

    end)()    
end

return gencontent
