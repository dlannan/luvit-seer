
local makeChroot    = require('coro-fs').chroot
local b64           = require('base64')

local funcs         = require("aspect.funcs")

funcs.add("addJs", {
    args = {
        [1] = {name = "arg1", type = "string"},
    }
}, function (__, args) 
    local arg1 = args.arg1
    local res = string.gsub(arg1, "^%w+://assets(.+)", "<script type=\"text/javascript\" src=\"%1\"></script>")
    return res
end)

funcs.add("addInlineJs", {
    args = {
        [1] = {name = "arg1", type = "string"},
    }
}, function (__, args) 
    local arg1 = args.arg1
    return "<script type=\"text/javascript\">"..arg1.."</script>"
end)

funcs.add("addCss", {
    args = {
        [1] = {name = "arg1", type = "string"},
    }
}, function (__, args) 
    local arg1 = args.arg1
    local res = string.gsub(arg1, "^%w+://assets(.+)", '<link rel=\"stylesheet\" href=\"%1\">')
    return res
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
    local data = nil
    local stat = fs.stat(arg1)
    if(stat) then data = fs.readFile(arg1) end
  return b64.enc(data or "")
end)

funcs.add("print", {
    args = {
        [1] = {name = "arg1", type = "any"},
    }
}, function (__, args) 
    local arg1 = args.arg1
    p(arg1)
end)

funcs.add("starts_with", {
    args = {
        [1] = {name = "arg1", type = "string"},
        [2] = {name = "arg2", type = "string"},
    }
}, function (__, args) 
    local arg1 = args.arg1
    local arg2 = args.arg2
    return arg1:find("^"..arg2) ~= nil
end)
