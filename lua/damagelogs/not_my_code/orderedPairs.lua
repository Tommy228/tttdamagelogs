
--[[---------------------------------------------------------
   http://lua-users.org/wiki/SortedIteration
---------------------------------------------------------]]--

local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert(orderedIndex, key)
    end
    table.sort(orderedIndex)
    return orderedIndex
end

local function orderedNext(t, state)
    if state == nil then
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
        return key, t[key]
    end
    key = nil
    for i = 1, table.getn(t.__orderedIndex) do
        if t.__orderedIndex[i] == state then
            key = t.__orderedIndex[i+1]
        end
    end
    if key then
        return key, t[key]
    end
    t.__orderedIndex = nil
    return
end

function Damagelog.orderedPairs(t)
    return orderedNext, t, nil
end
