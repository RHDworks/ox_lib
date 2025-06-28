--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@class oxtable : tablelib
lib.table = table

-- Cache frequently used functions for performance
local pairs = pairs
local ipairs = ipairs
local next = next
local type = type
local getmetatable = getmetatable
local setmetatable = setmetatable
local rawset = rawset
local table_clone = table.clone
local math_random = math.random
local math_floor = math.floor

---@param tbl table
---@param value any
---@return boolean
---Checks if tbl contains the given values. Only intended for simple values and unnested tables.
local function contains(tbl, value)
    if type(value) ~= 'table' then
        for _, v in pairs(tbl) do
            if v == value then
                return true
            end
        end
        return false
    else
        local set = {}
        for _, v in pairs(tbl) do
            set[v] = true
        end
        for _, v in pairs(value) do
            if not set[v] then
                return false
            end
        end
        return true
    end
end

---@param t1 any
---@param t2 any
---@return boolean
---Compares if two values are equal, iterating over tables and matching both keys and values.
local function table_matches(t1, t2)
    local tabletype1 = table.type(t1)

    if not tabletype1 then return t1 == t2 end

    if tabletype1 ~= table.type(t2) or (tabletype1 == 'array' and #t1 ~= #t2) then
        return false
    end

    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 == nil or not table_matches(v1, v2) then
            return false
        end
    end

    for k in pairs(t2) do
        if t1[k] == nil then
            return false
        end
    end

    return true
end

---@generic T
---@param tbl T
---@return T
---Recursively clones a table to ensure no table references.
local function table_deepclone(tbl)
    tbl = table.clone(tbl)

    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            tbl[k] = table_deepclone(v)
        end
    end

    return tbl
end

---@param t1 table
---@param t2 table
---@param addDuplicateNumbers boolean? add duplicate number keys together if true, replace if false. Defaults to true.
---@return table
---Merges two tables together. Defaults to adding duplicate keys together if they are numbers, otherwise they are overriden.
local function table_merge(t1, t2, addDuplicateNumbers)
    addDuplicateNumbers = addDuplicateNumbers == nil or addDuplicateNumbers
    for k, v2 in pairs(t2) do
        local v1 = t1[k]
        local type1 = type(v1)
        local type2 = type(v2)

        if type1 == 'table' and type2 == 'table' then
            table_merge(v1, v2, addDuplicateNumbers)
        elseif addDuplicateNumbers and (type1 == 'number' and type2 == 'number') then
            t1[k] = v1 + v2
        else
            t1[k] = v2
        end
    end

    return t1
end

---@param tbl table
---@return table
---Shuffles the elements of a table randomly using the Fisher-Yates algorithm.
local function shuffle(tbl)
    local len = #tbl
    for i = len, 2, -1 do
        local j = math_random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

local frozenNewIndex = function(self) error(('cannot set values on a frozen table (%s)'):format(self), 2) end
local _rawset = rawset

---@param tbl table
---@param index any
---@param value any
---@return table
function rawset(tbl, index, value)
    if table.isfrozen(tbl) then
        frozenNewIndex(tbl)
    end

    return _rawset(tbl, index, value)
end

---Makes a table read-only, preventing further modification. Unfrozen tables stored within `tbl` are still mutable.
---@generic T : table
---@param tbl T
---@return T
function table.freeze(tbl)
    local copy = table.clone(tbl)
    local metatbl = getmetatable(tbl)

    table.wipe(tbl)
    setmetatable(tbl, {
        __index = metatbl and setmetatable(copy, metatbl) or copy,
        __metatable = 'readonly',
        __newindex = frozenNewIndex,
        __len = function() return #copy end,
        ---@diagnostic disable-next-line: redundant-return-value
        __pairs = function() return next, copy end,
    })

    return tbl
end

---Return true if `tbl` is set as read-only.
---@param tbl table
---@return boolean
function table.isfrozen(tbl)
    return getmetatable(tbl) == 'readonly'
end

---Returns the number of elements in a table (both array and hash parts)
---@param tbl table
---@return integer
function table.size(tbl)
    if not tbl then return 0 end
    
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    
    return count
end

---Returns an array of all keys in the table
---@param tbl table
---@return table
function table.keys(tbl)
    if not tbl then return {} end
    
    local keys = {}
    local index = 0
    
    for k in pairs(tbl) do
        index = index + 1
        keys[index] = k
    end
    
    return keys
end

---Returns an array of all values in the table
---@param tbl table
---@return table
function table.values(tbl)
    if not tbl then return {} end
    
    local values = {}
    local index = 0
    
    for _, v in pairs(tbl) do
        index = index + 1
        values[index] = v
    end
    
    return values
end

---Returns an array of key-value pairs as {key, value} tables
---@param tbl table
---@return table
function table.entries(tbl)
    if not tbl then return {} end
    
    local entries = {}
    local index = 0
    
    for k, v in pairs(tbl) do
        index = index + 1
        entries[index] = {k, v}
    end
    
    return entries
end

---Creates a table from an array of key-value pairs
---@param entries table Array of {key, value} pairs
---@return table
function table.fromEntries(entries)
    if not entries then return {} end
    
    local result = {}
    
    for _, entry in ipairs(entries) do
        if type(entry) == 'table' and #entry >= 2 then
            result[entry[1]] = entry[2]
        end
    end
    
    return result
end

---Filters table entries based on predicate function
---@param tbl table
---@param predicate fun(value: any, key: any): boolean
---@return table
function table.filter(tbl, predicate)
    if not tbl or not predicate then return {} end
    
    local result = {}
    
    for k, v in pairs(tbl) do
        if predicate(v, k) then
            result[k] = v
        end
    end
    
    return result
end

---Maps table values using a transform function
---@param tbl table
---@param transform fun(value: any, key: any): any
---@return table
function table.map(tbl, transform)
    if not tbl or not transform then return {} end
    
    local result = {}
    
    for k, v in pairs(tbl) do
        result[k] = transform(v, k)
    end
    
    return result
end

---Reduces table to a single value using accumulator function
---@param tbl table
---@param reducer fun(accumulator: any, value: any, key: any): any
---@param initial any
---@return any
function table.reduce(tbl, reducer, initial)
    if not tbl or not reducer then return initial end
    
    local accumulator = initial
    
    for k, v in pairs(tbl) do
        accumulator = reducer(accumulator, v, k)
    end
    
    return accumulator
end

---Executes function for each table entry
---@param tbl table
---@param fn fun(value: any, key: any)
function table.forEach(tbl, fn)
    if not tbl or not fn then return end
    
    for k, v in pairs(tbl) do
        fn(v, k)
    end
end

---Checks if any table entry passes the test function
---@param tbl table
---@param predicate fun(value: any, key: any): boolean
---@return boolean
function table.some(tbl, predicate)
    if not tbl or not predicate then return false end
    
    for k, v in pairs(tbl) do
        if predicate(v, k) then
            return true
        end
    end
    
    return false
end

---Checks if all table entries pass the test function
---@param tbl table
---@param predicate fun(value: any, key: any): boolean
---@return boolean
function table.every(tbl, predicate)
    if not tbl or not predicate then return true end
    
    for k, v in pairs(tbl) do
        if not predicate(v, k) then
            return false
        end
    end
    
    return true
end

---Finds the first entry that passes the test function
---@param tbl table
---@param predicate fun(value: any, key: any): boolean
---@return any, any -- value, key
function table.find(tbl, predicate)
    if not tbl or not predicate then return nil, nil end
    
    for k, v in pairs(tbl) do
        if predicate(v, k) then
            return v, k
        end
    end
    
    return nil, nil
end

---Groups table entries by the result of a grouping function
---@param tbl table
---@param groupFn fun(value: any, key: any): any
---@return table
function table.groupBy(tbl, groupFn)
    if not tbl or not groupFn then return {} end
    
    local groups = {}
    
    for k, v in pairs(tbl) do
        local group = groupFn(v, k)
        if not groups[group] then
            groups[group] = {}
        end
        groups[group][k] = v
    end
    
    return groups
end

---Sorts array part of table and returns sorted copy
---@param tbl table
---@param compareFn? fun(a: any, b: any): boolean
---@return table
function table.sorted(tbl, compareFn)
    if not tbl then return {} end
    
    local result = table_clone(tbl)
    table.sort(result, compareFn)
    return result
end

---Reverses array part of table in place
---@param tbl table
---@return table
function table.reverse(tbl)
    if not tbl then return tbl end
    
    local len = #tbl
    for i = 1, math_floor(len / 2) do
        tbl[i], tbl[len - i + 1] = tbl[len - i + 1], tbl[i]
    end
    
    return tbl
end

---Returns a reversed copy of the array part
---@param tbl table
---@return table
function table.reversed(tbl)
    if not tbl then return {} end
    
    local result = {}
    local len = #tbl
    
    for i = 1, len do
        result[i] = tbl[len - i + 1]
    end
    
    return result
end

---Returns a slice of the array part
---@param tbl table
---@param start integer
---@param finish? integer
---@return table
function table.slice(tbl, start, finish)
    if not tbl then return {} end
    
    local len = #tbl
    start = start or 1
    finish = finish or len
    
    if start < 0 then start = len + start + 1 end
    if finish < 0 then finish = len + finish + 1 end
    if start < 1 then start = 1 end
    if finish > len then finish = len end
    
    local result = {}
    local index = 0
    
    for i = start, finish do
        index = index + 1
        result[index] = tbl[i]
    end
    
    return result
end

---Concatenates multiple tables (array parts only)
---@param ... table
---@return table
function table.concat_arrays(...)
    local result = {}
    local index = 0
    local arrays = {...}
    
    for i = 1, #arrays do
        local arr = arrays[i]
        if arr then
            for j = 1, #arr do
                index = index + 1
                result[index] = arr[j]
            end
        end
    end
    
    return result
end

---Flattens nested arrays to specified depth
---@param tbl table
---@param depth? integer Default: 1
---@return table
function table.flatten(tbl, depth)
    if not tbl then return {} end
    depth = depth or 1
    
    local result = {}
    local index = 0
    
    local function flatten_recursive(arr, current_depth)
        for i = 1, #arr do
            local value = arr[i]
            if type(value) == 'table' and current_depth > 0 then
                flatten_recursive(value, current_depth - 1)
            else
                index = index + 1
                result[index] = value
            end
        end
    end
    
    flatten_recursive(tbl, depth)
    return result
end

---Returns unique values from array part
---@param tbl table
---@param keyFn? fun(value: any): any Function to generate comparison key
---@return table
function table.unique(tbl, keyFn)
    if not tbl then return {} end
    
    local seen = {}
    local result = {}
    local index = 0
    
    for i = 1, #tbl do
        local value = tbl[i]
        local key = keyFn and keyFn(value) or value
        
        if not seen[key] then
            seen[key] = true
            index = index + 1
            result[index] = value
        end
    end
    
    return result
end

---Intersects two tables (returns common elements)
---@param tbl1 table
---@param tbl2 table
---@return table
function table.intersect(tbl1, tbl2)
    if not tbl1 or not tbl2 then return {} end
    
    local set2 = {}
    for _, v in ipairs(tbl2) do
        set2[v] = true
    end
    
    local result = {}
    local index = 0
    
    for _, v in ipairs(tbl1) do
        if set2[v] then
            index = index + 1
            result[index] = v
        end
    end
    
    return result
end

---Returns difference between two tables (elements in tbl1 but not in tbl2)
---@param tbl1 table
---@param tbl2 table
---@return table
function table.difference(tbl1, tbl2)
    if not tbl1 then return {} end
    if not tbl2 then return table_clone(tbl1) end
    
    local set2 = {}
    for _, v in ipairs(tbl2) do
        set2[v] = true
    end
    
    local result = {}
    local index = 0
    
    for _, v in ipairs(tbl1) do
        if not set2[v] then
            index = index + 1
            result[index] = v
        end
    end
    
    return result
end

---Returns union of two tables (all unique elements)
---@param tbl1 table
---@param tbl2 table
---@return table
function table.union(tbl1, tbl2)
    local combined = table.concat_arrays(tbl1 or {}, tbl2 or {})
    return table.unique(combined)
end

---Picks specified keys from table
---@param tbl table
---@param keys table|string Array of keys or single key
---@return table
function table.pick(tbl, keys)
    if not tbl then return {} end
    
    local result = {}
    
    if type(keys) == 'string' then
        if tbl[keys] ~= nil then
            result[keys] = tbl[keys]
        end
    elseif type(keys) == 'table' then
        for _, key in ipairs(keys) do
            if tbl[key] ~= nil then
                result[key] = tbl[key]
            end
        end
    end
    
    return result
end

---Omits specified keys from table
---@param tbl table
---@param keys table|string Array of keys or single key
---@return table
function table.omit(tbl, keys)
    if not tbl then return {} end
    
    local omit_set = {}
    
    if type(keys) == 'string' then
        omit_set[keys] = true
    elseif type(keys) == 'table' then
        for _, key in ipairs(keys) do
            omit_set[key] = true
        end
    end
    
    local result = {}
    for k, v in pairs(tbl) do
        if not omit_set[k] then
            result[k] = v
        end
    end
    
    return result
end

---Checks if table is empty
---@param tbl table
---@return boolean
function table.isEmpty(tbl)
    if not tbl then return true end
    return next(tbl) == nil
end

---Inverts table (keys become values, values become keys)
---@param tbl table
---@return table
function table.invert(tbl)
    if not tbl then return {} end
    
    local result = {}
    for k, v in pairs(tbl) do
        result[v] = k
    end
    
    return result
end

---Deep merges two tables (recursive merge for nested tables)
---@param target table
---@param source table
---@return table
function table.deepMerge(target, source)
    if not target then target = {} end
    if not source then return target end
    
    for k, v in pairs(source) do
        if type(v) == 'table' and type(target[k]) == 'table' then
            target[k] = table.deepMerge(target[k], v)
        else
            target[k] = v
        end
    end
    
    return target
end

---Assigns original functions to table namespace
table.contains = contains
table.matches = table_matches
table.deepclone = table_deepclone
table.merge = table_merge
table.shuffle = shuffle

return lib.table
