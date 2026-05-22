

local redisConnect = require('redis-client')
local fileio = require('fileio')

local redis = {

    call = nil
}

redis.connect = function ()
    if redis.call == nil then 
        redis.call = redisConnect { host = _G.LOCALHOST_IP, port = _G.LOCALHOST_REDIS_PORT }
    end
end

redis.close = function ()
    if redis.call ~= nil then
        redis.call()
    end
    redis.call = nil
end

redis.bgsave = function()

    redis.connect()
    redis.call('BGSAVE')
    redis.close()
end

redis.lastsave = function()
    local lasttime = nil
    redis.connect()
    lasttime = redis.call('LASTSAVE')
    redis.close()
    return lasttime
end

redis.delete = function (key)

    redis.connect()
    redis.call('DEL', key)
    redis.close()
end

redis.hmset = function (key, dict)
  if next(dict) == nil then return nil end
    local bulk = {}
    for k, v in pairs(dict) do
        table.insert(bulk, k)
        table.insert(bulk, v)
    end
    local res = nil

    redis.connect()
    res = redis.call('HMSET', key, unpack(bulk))
    redis.close()
    return res
end

-- gets all fields from a hash as a dictionary
redis.hgetall = function (key)
    local bulk = nil
    redis.connect()
    bulk = redis.call('HGETALL', key)
    redis.close()
    if bulk == nil then return nil end
    local result = {}
    local nextkey
    for i, v in ipairs(bulk) do
        if i % 2 == 1 then
            nextkey = tonumber(v) or v
        else
            result[nextkey] = v
        end
    end
    return result
end

-- gets multiple fields from a hash as a dictionary
redis.hmget = function (key, ...)
    if next(arg) == nil then return {} end
    local bulk = nil

    redis.connect()
    bulk = redis.call('HMGET', key, unpack(arg))
    redis.close()
    if bulk == nil then return nil end
    local result = {}
    for i, v in ipairs(bulk) do result[ arg[i] ] = v end
    return result
end

-- Will get rid of the above and have entirely redis based config
redis.getkey = function (keyname)
    local result = nil
    -- Just put some data into redis first
    redis.connect()
    result = redis.call("get", keyname)
    redis.close()
    return result
end

-- Will get rid of the above and have entirely redis based config
redis.setkey = function (keyname, data)
    local result = nil
    -- Just put some data into redis first
    redis.connect()
    result = redis.call("set", keyname, data)
    redis.close()
    return result
end


return redis
