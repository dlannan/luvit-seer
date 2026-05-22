function newT( t )
   local mt = {}
   -- set methods
   mt.__index = {
      -- set key order table inside __index for faster lookup
      _korder = {},
      -- traversal of hidden values
      hidden = function() return pairs( mt.__index ) end,
      -- traversal of table ordered: returning index, key
      ipairs = function( self ) return ipairs( self._korder ) end,
      -- traversal of table
      pairs = function( self ) return pairs( self ) end,
      -- traversal of table ordered: returning key,value
      opairs = function( self )
         local i = 0
         local function iter( self )
            i = i + 1
            local k = self._korder[i]
            if k then
               return k,self[k]
            end
         end
         return iter,self
      end,
      -- reverse traversal of table ordered: returning key,value
      rpairs = function( self )
         local i = table.getn(self._korder)
         local function iter( self )
            local k = self._korder[i]
            if k then
               return k,self[k]
            end
            i = i - 1
         end
         return iter,self
      end,
      -- to be able to delete entries we must write a delete function
      del = function( self,key )
         if self[key] then
            self[key] = nil
            for i,k in ipairs( self._korder ) do
               if k == key then
                  table.remove( self._korder, i )
                  return
               end
            end
         end
      end,
   }
   -- set new index handling
   mt.__newindex = function( self,k,v )
      if k ~= "del" and v then
         rawset( self,k,v )
         table.insert( self._korder, k )
      end      
   end
   return setmetatable( t or {},mt )
end

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function rpairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = #keys + 1
    return function()
        i = i - 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end