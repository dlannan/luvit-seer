
local fileio = require('fileio')
local argon2 = require('argon2')

local gencontent = {}
local argon2_pwd = argon2.makepwd

gencontent.init = function(asetup)

    -- Populate the redis system with something useful (this will need to happen in admin when editing)
    coroutine.wrap(function ()
        -- Just put some data into redis first
        rdis = require("redis-tools")
        rdis.connect()
            
        -- Some default feeed data 
        rdis.call("set", "feeds.thisfeed.likecount", 0)
            
        rdis.call("set", "content.default.theme.Default", fileio.read_file("templates/theme/default.html"))
        rdis.call("set", "content.default.theme.Default.page", fileio.read_file("templates/theme/default_page.html"))
        rdis.call("set", "content.default.theme.Default.blank", fileio.read_file("templates/theme/default_blank.html"))
        rdis.call("set", "content.default.theme.Default.blog", fileio.read_file("templates/theme/default_blog.html"))
        --rdis.call("set", "content.default.theme.Simple", fileio.read_file("templates/theme/simple.html"))
        --rdis.call("set", "content.default.theme.userlogin", fileio.read_file("templates/userlogin.html"))
        
        asetup.processHtml(rdis)    
        rdis.close()
            
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
--        p( pw3, "nhommot.kuch@gmail.com" )
--        p( pw4, "ian@3pdesign.com.au" )
--        p( pw5, "smiley@smiley-it.net" )
--        p( pw6, "glannan@internode.on.net" )
            
        admin.adduser( pw1, "dlannan@gagagames.com" )
        admin.adduser( pw2, "zlannan@teamxirix.com" )
        --admin.adduser( pw3, "nhommot.kuch@gmail.com" )
        --admin.adduser( pw4, "ian@3pdesign.com.au" )
        --admin.adduser( pw5, "smiley@smiley-it.net" )
        --admin.adduser( pw6, "glannan@internode.on.net" )
        admin.adduser( pw7, "arusso@playford.sa.gov.au" )
        
        
    end)()
end

return gencontent
