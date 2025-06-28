--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@class Array<T> : OxClass, { [number]: T }
lib.array = lib.class('Array')

-- Cache frequently used functions for performance
local table_unpack = table.unpack
local table_remove = table.remove
local table_clone = table.clone
local table_concat = table.concat
local table_type = table.type
local table_sort = table.sort
local table_insert = table.insert
local math_random = math.random
local math_floor = math.floor
local math_min = math.min
local math_max = math.max

---@alias ArrayLike<T> Array | { [number]: T }

-- ORIGINAL FUNCTIONS (keeping existing implementation)

---@private
function lib.array:constructor(...)
    local arr = { ... }

    for i = 1, #arr do
        self[i] = arr[i]
    end
end

---@private
function lib.array:__newindex(index, value)
    if type(index) ~= 'number' then error(("Cannot insert non-number index '%s' into an array."):format(index)) end

    rawset(self, index, value)
end

---Creates a new array from an iteratable value.
---@param iter table | function | string
---@return Array
function lib.array:from(iter)
    local iterType = type(iter)

    if iterType == 'table' then
        return lib.array:new(table_unpack(iter))
    end

    if iterType == 'string' then
        return lib.array:new(string.strsplit('', iter))
    end

    if iterType == 'function' then
        local arr = lib.array:new()
        local length = 0

        for value in iter do
            length += 1
            arr[length] = value
        end

        return arr
    end

    error(('Array.from argument was not a valid iterable value (received %s)'):format(iterType))
end

---Returns the element at the given index, with negative numbers counting backwards from the end of the array.
---@param index number
---@return unknown
function lib.array:at(index)
    if index < 0 then
        index = #self + index + 1
    end

    return self[index]
end

---Create a new array containing the elements of two or more arrays.
---@param ... ArrayLike
function lib.array:merge(...)
    local newArr = table_clone(self)
    local length = #self
    local arrays = { ... }

    for i = 1, #arrays do
        local arr = arrays[i]

        for j = 1, #arr do
            length += 1
            newArr[length] = arr[j]
        end
    end

    return lib.array:new(table_unpack(newArr))
end

---Tests if all elements in an array succeed in passing the provided test function.
---@param testFn fun(element: unknown): boolean
function lib.array:every(testFn)
    for i = 1, #self do
        if not testFn(self[i]) then
            return false
        end
    end

    return true
end

---Sets all elements within a range to the given value and returns the modified array.
---@param value any
---@param start? number
---@param endIndex? number
function lib.array:fill(value, start, endIndex)
    local length = #self
    start = start or 1
    endIndex = endIndex or length

    if start < 1 then start = 1 end
    if endIndex > length then endIndex = length end

    for i = start, endIndex do
        self[i] = value
    end

    return self
end

---Creates a new array containing the elements from an array that pass the test of the provided function.
---@param testFn fun(element: unknown): boolean
function lib.array:filter(testFn)
    local newArr = {}
    local length = 0

    for i = 1, #self do
        local element = self[i]

        if testFn(element) then
            length += 1
            newArr[length] = element
        end
    end

    return lib.array:new(table_unpack(newArr))
end

---Returns the first or last element of an array that passes the provided test function.
---@param testFn fun(element: unknown): boolean
---@param last? boolean
function lib.array:find(testFn, last)
    local a = last and #self or 1
    local b = last and 1 or #self
    local c = last and -1 or 1

    for i = a, b, c do
        local element = self[i]

        if testFn(element) then
            return element
        end
    end
end

---Returns the first or last index of the first element of an array that passes the provided test function.
---@param testFn fun(element: unknown): boolean
---@param last? boolean
function lib.array:findIndex(testFn, last)
    local a = last and #self or 1
    local b = last and 1 or #self
    local c = last and -1 or 1

    for i = a, b, c do
        local element = self[i]

        if testFn(element) then
            return i
        end
    end
end

---Returns the first or last index of the first element of an array that matches the provided value.
---@param value unknown
---@param last? boolean
function lib.array:indexOf(value, last)
    local a = last and #self or 1
    local b = last and 1 or #self
    local c = last and -1 or 1

    for i = a, b, c do
        local element = self[i]

        if element == value then
            return i
        end
    end
end

---Executes the provided function for each element in an array.
---@param cb fun(element: unknown)
function lib.array:forEach(cb)
    for i = 1, #self do
        cb(self[i])
    end
end

---Determines if a given element exists inside an array.
---@param element unknown The value to find in the array.
---@param fromIndex? number The position in the array to begin searching from.
function lib.array:includes(element, fromIndex)
    for i = (fromIndex or 1), #self do
        if self[i] == element then return true end
    end

    return false
end

---Concatenates all array elements into a string, seperated by commas or the specified seperator.
---@param seperator? string
function lib.array:join(seperator)
    return table_concat(self, seperator or ',')
end

---Create a new array containing the results from calling the provided function on every element in an array.
---@param cb fun(element: unknown, index: number, array: self): unknown
function lib.array:map(cb)
    local arr = {}

    for i = 1, #self do
        arr[i] = cb(self[i], i, self)
    end

    return lib.array:new(table_unpack(arr))
end

---Removes the last element from an array and returns the removed element.
function lib.array:pop()
    return table_remove(self)
end

---Adds the given elements to the end of an array and returns the new array length.
---@param ... any
function lib.array:push(...)
    local elements = { ... }
    local length = #self

    for i = 1, #elements do
        length += 1
        self[length] = elements[i]
    end

    return length
end

---The "reducer" function is applied to every element within an array, with the previous element's result serving as the accumulator.
---If an initial value is provided, it's used as the accumulator for index 1; otherwise, index 1 itself serves as the initial value, and iteration begins from index 2.
---@generic T
---@param reducer fun(accumulator: T, currentValue: T, index?: number): T
---@param initialValue? T
---@param reverse? boolean Iterate over the array from right-to-left.
---@return T
function lib.array:reduce(reducer, initialValue, reverse)
    local length = #self
    local initialIndex = initialValue and 1 or 2
    local accumulator = initialValue or self[1]

    if reverse then
        for i = initialIndex, length do
            local index = length - i + initialIndex
            accumulator = reducer(accumulator, self[index], index)
        end
    else
        for i = initialIndex, length do
            accumulator = reducer(accumulator, self[i], i)
        end
    end

    return accumulator
end

---Reverses the elements inside an array.
function lib.array:reverse()
    local i, j = 1, #self

    while i < j do
        self[i], self[j] = self[j], self[i]
        i += 1
        j -= 1
    end

    return self
end

---Removes the first element from an array and returns the removed element.
function lib.array:shift()
    return table_remove(self, 1)
end

---Creates a shallow copy of a portion of an array as a new array.
---@param start? number
---@param finish? number
function lib.array:slice(start, finish)
    local length = #self
    start = start or 1
    finish = finish or length

    if start < 0 then start = length + start + 1 end
    if finish < 0 then finish = length + finish + 1 end
    if start < 1 then start = 1 end
    if finish > length then finish = length end

    local arr = lib.array:new()
    local index = 0

    for i = start, finish do
        index += 1
        arr[index] = self[i]
    end

    return arr
end

---Creates a new array with reversed elements from the given array.
function lib.array:toReversed()
    local reversed = lib.array:new()

    for i = #self, 1, -1 do
        reversed:push(self[i])
    end

    return reversed
end

---Inserts the given elements to the start of an array and returns the new array length.
---@param ... any
function lib.array:unshift(...)
    local elements = { ... }
    local length = #self
    local eLength = #elements

    for i = length, 1, -1 do
        self[i + eLength] = self[i]
    end

    for i = 1, #elements do
        self[i] = elements[i]
    end

    return length + eLength
end

---Returns true if the given table is an instance of array or an array-like table.
---@param tbl ArrayLike
---@return boolean
function lib.array.isArray(tbl)
    local tableType = table_type(tbl)

    if not tableType then return false end

    if tableType == 'array' or tableType == 'empty' or lib.array.instanceOf(tbl, lib.array) then
        return true
    end

    return false
end

---Sorts the array in place and returns the array
---@param compareFn? fun(a: unknown, b: unknown): boolean
---@return Array
function lib.array:sort(compareFn)
    table_sort(self, compareFn)
    return self
end

---Creates a sorted copy of the array without modifying the original
---@param compareFn? fun(a: unknown, b: unknown): boolean
---@return Array
function lib.array:toSorted(compareFn)
    local copy = self:slice()
    table_sort(copy, compareFn)
    return copy
end

---Flattens nested arrays to specified depth
---@param depth? integer Default: 1
---@return Array
function lib.array:flat(depth)
    depth = depth or 1
    local result = lib.array:new()
    
    local function flatten_recursive(arr, current_depth)
        for i = 1, #arr do
            local value = arr[i]
            if lib.array.isArray(value) and current_depth > 0 then
                flatten_recursive(value, current_depth - 1)
            else
                result:push(value)
            end
        end
    end
    
    flatten_recursive(self, depth)
    return result
end

---Maps and then flattens the result
---@param cb fun(element: unknown, index: number, array: Array): unknown
---@param depth? integer Default: 1
---@return Array
function lib.array:flatMap(cb, depth)
    return self:map(cb):flat(depth)
end

---Tests whether at least one element passes the provided test function
---@param testFn fun(element: unknown, index: number, array: Array): boolean
---@return boolean
function lib.array:some(testFn)
    for i = 1, #self do
        if testFn(self[i], i, self) then
            return true
        end
    end
    return false
end

---Removes elements from array and optionally inserts new elements
---@param start integer Start index (1-based)
---@param deleteCount? integer Number of elements to remove
---@param ... any Elements to insert
---@return Array Removed elements
function lib.array:splice(start, deleteCount, ...)
    local length = #self
    local insertItems = {...}
    local insertCount = #insertItems
    
    -- Handle negative start index
    if start < 0 then
        start = math_max(length + start + 1, 1)
    else
        start = math_min(start, length + 1)
    end
    
    -- Handle deleteCount
    deleteCount = deleteCount or (length - start + 1)
    deleteCount = math_max(0, math_min(deleteCount, length - start + 1))
    
    -- Store removed elements
    local removed = lib.array:new()
    for i = 1, deleteCount do
        removed[i] = self[start + i - 1]
    end
    
    -- Calculate size difference
    local sizeDiff = insertCount - deleteCount
    
    if sizeDiff > 0 then
        -- Shift elements right
        for i = length, start + deleteCount, -1 do
            self[i + sizeDiff] = self[i]
        end
    elseif sizeDiff < 0 then
        -- Shift elements left
        for i = start + insertCount, length + sizeDiff do
            self[i] = self[i - sizeDiff]
        end
        -- Clear trailing elements
        for i = length + sizeDiff + 1, length do
            self[i] = nil
        end
    end
    
    -- Insert new elements
    for i = 1, insertCount do
        self[start + i - 1] = insertItems[i]
    end
    
    return removed
end

---Creates a copy of array with elements in sorted order
---@param index any
---@param value any
---@return Array
function lib.array:with(index, value)
    local copy = self:slice()
    if index < 0 then
        index = #self + index + 1
    end
    copy[index] = value
    return copy
end

---Returns unique elements from the array
---@param keyFn? fun(element: unknown): unknown Function to generate comparison key
---@return Array
function lib.array:unique(keyFn)
    local seen = {}
    local result = lib.array:new()
    
    for i = 1, #self do
        local element = self[i]
        local key = keyFn and keyFn(element) or element
        
        if not seen[key] then
            seen[key] = true
            result:push(element)
        end
    end
    
    return result
end

---Groups array elements by the result of a grouping function
---@param groupFn fun(element: unknown, index: number): unknown
---@return table<unknown, Array>
function lib.array:groupBy(groupFn)
    local groups = {}
    
    for i = 1, #self do
        local element = self[i]
        local key = groupFn(element, i)
        
        if not groups[key] then
            groups[key] = lib.array:new()
        end
        
        groups[key]:push(element)
    end
    
    return groups
end

---Partitions array into two arrays based on predicate
---@param predicate fun(element: unknown, index: number): boolean
---@return Array, Array -- [truthy, falsy]
function lib.array:partition(predicate)
    local truthy = lib.array:new()
    local falsy = lib.array:new()
    
    for i = 1, #self do
        local element = self[i]
        if predicate(element, i) then
            truthy:push(element)
        else
            falsy:push(element)
        end
    end
    
    return truthy, falsy
end

---Chunks array into smaller arrays of specified size
---@param size integer
---@return Array<Array>
function lib.array:chunk(size)
    if size <= 0 then error("Chunk size must be positive") end
    
    local chunks = lib.array:new()
    local current_chunk = lib.array:new()
    
    for i = 1, #self do
        current_chunk:push(self[i])
        
        if #current_chunk == size or i == #self then
            chunks:push(current_chunk)
            current_chunk = lib.array:new()
        end
    end
    
    return chunks
end

---Rotates array elements by specified amount
---@param amount integer Positive for right rotation, negative for left
---@return Array
function lib.array:rotate(amount)
    local length = #self
    if length <= 1 or amount == 0 then return self:slice() end
    
    amount = amount % length
    if amount == 0 then return self:slice() end
    
    local result = lib.array:new()
    
    for i = 1, length do
        local newIndex = ((i - 1 - amount) % length) + 1
        result[i] = self[newIndex]
    end
    
    return result
end

---Shuffles array elements randomly
---@return Array
function lib.array:shuffle()
    local copy = self:slice()
    local length = #copy
    
    for i = length, 2, -1 do
        local j = math_random(i)
        copy[i], copy[j] = copy[j], copy[i]
    end
    
    return copy
end

---Returns random element(s) from array
---@param count? integer Number of elements to sample (default: 1)
---@param replace? boolean Allow replacement (default: false)
---@return Array|unknown
function lib.array:sample(count, replace)
    local length = #self
    if length == 0 then return count and lib.array:new() or nil end
    
    if not count then
        return self[math_random(length)]
    end
    
    if count <= 0 then return lib.array:new() end
    
    local result = lib.array:new()
    
    if replace then
        for _ = 1, count do
            result:push(self[math_random(length)])
        end
    else
        local available = self:slice()
        local sampleCount = math_min(count, length)
        
        for _ = 1, sampleCount do
            local index = math_random(#available)
            result:push(available[index])
            table_remove(available, index)
        end
    end
    
    return result
end

---Zips this array with other arrays
---@param ... Array
---@return Array<Array>
function lib.array:zip(...)
    local arrays = {self, ...}
    local result = lib.array:new()
    local maxLength = 0
    
    -- Find maximum length
    for _, arr in ipairs(arrays) do
        maxLength = math_max(maxLength, #arr)
    end
    
    -- Create tuples
    for i = 1, maxLength do
        local tuple = lib.array:new()
        for _, arr in ipairs(arrays) do
            tuple:push(arr[i])
        end
        result:push(tuple)
    end
    
    return result
end

---Transposes a 2D array (swaps rows and columns)
---@return Array<Array>
function lib.array:transpose()
    if #self == 0 then return lib.array:new() end
    
    local result = lib.array:new()
    local maxCols = 0
    
    -- Find maximum number of columns
    for i = 1, #self do
        if lib.array.isArray(self[i]) then
            maxCols = math_max(maxCols, #self[i])
        end
    end
    
    -- Create transposed array
    for col = 1, maxCols do
        local newRow = lib.array:new()
        for row = 1, #self do
            if lib.array.isArray(self[row]) then
                newRow:push(self[row][col])
            else
                newRow:push(nil)
            end
        end
        result:push(newRow)
    end
    
    return result
end

---Finds intersection with other arrays
---@param ... Array
---@return Array
function lib.array:intersect(...)
    local others = {...}
    if #others == 0 then return self:slice() end
    
    local result = lib.array:new()
    
    for i = 1, #self do
        local element = self[i]
        local inAll = true
        
        for _, other in ipairs(others) do
            if not other:includes(element) then
                inAll = false
                break
            end
        end
        
        if inAll and not result:includes(element) then
            result:push(element)
        end
    end
    
    return result
end

---Finds difference with other arrays (elements in this array but not in others)
---@param ... Array
---@return Array
function lib.array:difference(...)
    local others = {...}
    local result = lib.array:new()
    
    for i = 1, #self do
        local element = self[i]
        local inOthers = false
        
        for _, other in ipairs(others) do
            if other:includes(element) then
                inOthers = true
                break
            end
        end
        
        if not inOthers then
            result:push(element)
        end
    end
    
    return result
end

---Finds union with other arrays (all unique elements)
---@param ... Array
---@return Array
function lib.array:union(...)
    local result = self:slice()
    local others = {...}
    
    for _, other in ipairs(others) do
        for j = 1, #other do
            if not result:includes(other[j]) then
                result:push(other[j])
            end
        end
    end
    
    return result
end

---Removes all specified values from array
---@param ... any Values to remove
---@return Array
function lib.array:without(...)
    local toRemove = {...}
    local result = lib.array:new()
    
    for i = 1, #self do
        local element = self[i]
        local shouldRemove = false
        
        for _, removeValue in ipairs(toRemove) do
            if element == removeValue then
                shouldRemove = true
                break
            end
        end
        
        if not shouldRemove then
            result:push(element)
        end
    end
    
    return result
end

---Returns first element (head)
---@return unknown
function lib.array:first()
    return self[1]
end

---Returns last element
---@return unknown
function lib.array:last()
    return self[#self]
end

---Returns array without first element (tail)
---@return Array
function lib.array:tail()
    return self:slice(2)
end

---Returns array without last element
---@return Array
function lib.array:initial()
    return self:slice(1, #self - 1)
end

---Takes first n elements
---@param n integer
---@return Array
function lib.array:take(n)
    return self:slice(1, n)
end

---Takes last n elements
---@param n integer
---@return Array
function lib.array:takeLast(n)
    local length = #self
    return self:slice(math_max(1, length - n + 1))
end

---Drops first n elements
---@param n integer
---@return Array
function lib.array:drop(n)
    return self:slice(n + 1)
end

---Drops last n elements
---@param n integer
---@return Array
function lib.array:dropLast(n)
    return self:slice(1, #self - n)
end

---Takes elements while predicate returns true
---@param predicate fun(element: unknown, index: number): boolean
---@return Array
function lib.array:takeWhile(predicate)
    local result = lib.array:new()
    
    for i = 1, #self do
        if predicate(self[i], i) then
            result:push(self[i])
        else
            break
        end
    end
    
    return result
end

---Drops elements while predicate returns true
---@param predicate fun(element: unknown, index: number): boolean
---@return Array
function lib.array:dropWhile(predicate)
    local start = 1
    
    for i = 1, #self do
        if not predicate(self[i], i) then
            start = i
            break
        end
        start = i + 1
    end
    
    return self:slice(start)
end

---Compacts array by removing falsy values (nil, false)
---@return Array
function lib.array:compact()
    return self:filter(function(element)
        return element ~= nil and element ~= false
    end)
end

---Returns minimum value in array
---@param keyFn? fun(element: unknown): number Function to extract comparison value
---@return unknown
function lib.array:min(keyFn)
    if #self == 0 then return nil end
    
    local minElement = self[1]
    local minValue = keyFn and keyFn(minElement) or minElement
    
    for i = 2, #self do
        local element = self[i]
        local value = keyFn and keyFn(element) or element
        if value < minValue then
            minValue = value
            minElement = element
        end
    end
    
    return minElement
end

---Returns maximum value in array
---@param keyFn? fun(element: unknown): number Function to extract comparison value
---@return unknown
function lib.array:max(keyFn)
    if #self == 0 then return nil end
    
    local maxElement = self[1]
    local maxValue = keyFn and keyFn(maxElement) or maxElement
    
    for i = 2, #self do
        local element = self[i]
        local value = keyFn and keyFn(element) or element
        if value > maxValue then
            maxValue = value
            maxElement = element
        end
    end
    
    return maxElement
end

---Calculates sum of array elements
---@param keyFn? fun(element: unknown): number Function to extract numeric value
---@return number
function lib.array:sum(keyFn)
    local total = 0
    
    for i = 1, #self do
        local value = keyFn and keyFn(self[i]) or self[i]
        if type(value) == 'number' then
            total = total + value
        end
    end
    
    return total
end

---Calculates average of array elements
---@param keyFn? fun(element: unknown): number Function to extract numeric value
---@return number?
function lib.array:average(keyFn)
    if #self == 0 then return nil end
    return self:sum(keyFn) / #self
end

---Checks if array is empty
---@return boolean
function lib.array:isEmpty()
    return #self == 0
end

---Creates a shallow copy of the array
---@return Array
function lib.array:clone()
    return self:slice()
end

---Converts array to regular table
---@return table
function lib.array:toTable()
    local result = {}
    for i = 1, #self do
        result[i] = self[i]
    end
    return result
end

return lib.array
