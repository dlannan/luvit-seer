
local md5           = require("md5")
local filters       = require("aspect.filters")


filters.add("shortcodes", {
    input = "string", -- input value type
    output = "string", -- output value type
    args = {
        [1] = {name = "arg1", type = "string"}, 
    }
}, function (arg1) 
  return arg1
end)

filters.add("json_decode", {
    input = "string", -- input value type
    output = "json", -- output value type
    args = {
        [1] = {name = "arg1", type = "string"}, 
    }
}, function (arg1) 
  return arg1
end)

filters.add("md5", {
    input = "string", -- input value type
    output = "string", -- output value type
    args = {
        [1] = {name = "arg1", type = "string"}, 
    }
}, function (arg1) 
  return md5.sumhexa(arg1)
end)

filters.add("int", {
    input = "any", -- input value type
    output = "number", -- output value type
    args = {
        [1] = {name = "arg1", type = "any"}, 
    }
}, function (arg1) 
  return tonumber(arg1)
end)