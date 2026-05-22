local template = require "resty.template"
-- Make a javascript string from lines of text
local JS_STRING = function( data )
    local newstr = ""
    for line in data:gmatch("[^\r\n]+") do
        -- escape code the ' characters in the 
        line = line:gsub("(')", "")
        newstr = newstr.."'"..line.."' +"
    end
    newstr = newstr.."' '"
    return newstr    
end

return JS_STRING