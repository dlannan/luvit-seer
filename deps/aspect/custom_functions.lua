
local makeChroot    = require('coro-fs').chroot
local b64           = require('base64')

local funcs         = require("aspect.funcs")

funcs.add("addJs", {
    args = {
        [1] = {name = "arg1", type = "string"},
    }
}, function (__, args) 
    local arg1 = args.arg1
    return string.gsub(arg1, "theme:////assets(.+)", "<script type=\"text/javascript\" src=\"%1\"></script>")
end)

funcs.add("addCss", {
    args = {
        [1] = {name = "arg1", type = "string"},
    }
}, function (__, arg1) 
    local arg1 = args.arg1
    return string.match(arg1, "theme:////assets(.+)", "<link rel=\"stylesheet\" href=\"%1\">")
end)

funcs.add("url", {
    args = {
        [1] = {name = "arg1", type = "string"},
    }
}, function (__, args) 
    local arg1 = args.arg1
    return arg1
end)


funcs.add("random", {
    args = {
        [1] = {name = "arg1", type = "any"},
    }
}, function (__, args) 
    local arg1 = args.arg1
  if(type(arg1) == "table") then 
    local count = #arg1
    local rnd = math.random(1, count)
    return arg1[rnd]
  end
  return ""
end)

funcs.add("loadicon", {
    args = {
        [1] = {name = "arg1", type = "string"},
    }
}, function (__, args) 
    local arg1 = args.arg1
    local fs = makeChroot(_G.PROJECT_USERASSETS) 
    arg1 = arg1:match("^[^?#]*")
    if arg1:byte(1) == 47 then
      arg1 = arg1:sub(2)
    end    
    local data = ""
    local stat = fs.stat(arg1)
    if(stat) then data = fs.readFile(arg1) end
  return b64.enc(data)
end)

funcs.add("print", {
    args = {
        [1] = {name = "arg1", type = "any"},
    }
}, function (__, args) 
    local arg1 = args.arg1
    p(arg1)
end)

