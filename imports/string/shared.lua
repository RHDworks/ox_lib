--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@class oxstring : stringlib
lib.string = string

local string_char = string.char
local string_byte = string.byte
local string_rep = string.rep
local table_concat = table.concat
local math_random = math.random
local math_floor = math.floor

local function getLetter() return string_char(math_random(65, 90)) end
local function getLowerLetter() return string_char(math_random(97, 122)) end
local function getInt() return math_random(0, 9) end
local function getAlphanumeric() return math_random(0, 1) == 1 and getLetter() or getInt() end

local formatChar = {
    ['1'] = getInt,
    ['A'] = getLetter,
    ['a'] = getLowerLetter,
    ['.'] = getAlphanumeric,
}

---Creates a random string based on a given pattern.
---`1` will output a random number from 0-9.
---`A` will output a random letter from A-Z.
---`a` will output a random letter from a-z.
---`.` will output a random letter or number.
---`^` will output the following character literally.
---Any other character will output said character.
---@param pattern string
---@param length? integer Sets the length of the returned string, either padding it or omitting characters.
---@return string
function string.random(pattern, length)
    local len = length or #pattern:gsub('%^', '')
    local arr = table.create(len, 0)
    local size = 0
    local i = 0

    while size < len do
        i += 1
        ---@type string | integer
        local char = pattern:sub(i, i)

        if char == '' then
            arr[size + 1] = string.rep(' ', len - size)
            break
        elseif char == '^' then
            i += 1
            char = pattern:sub(i, i)
        else
            local fn = formatChar[char]
            char = fn and fn() or char
        end

        size += 1
        arr[size] = char
    end

    return table.concat(arr)
end

---Trims whitespace from both ends of string
---@param str string
---@param chars? string Characters to trim (default: whitespace)
---@return string
function string.trim(str, chars)
    if not str then return str end
    chars = chars and '[' .. chars .. ']' or '%s'
    return str:match('^' .. chars .. '*(.-)'.. chars .. '*$')
end

---Trims whitespace from the left end of string
---@param str string
---@param chars? string Characters to trim (default: whitespace)
---@return string
function string.ltrim(str, chars)
    if not str then return str end
    chars = chars and '[' .. chars .. ']' or '%s'
    return str:match('^' .. chars .. '*(.*)')
end

---Trims whitespace from the right end of string
---@param str string
---@param chars? string Characters to trim (default: whitespace)
---@return string
function string.rtrim(str, chars)
    if not str then return str end
    chars = chars and '[' .. chars .. ']' or '%s'
    return str:match('(.-)' .. chars .. '*$')
end

---Splits a string by delimiter
---@param str string
---@param delimiter string
---@param max_splits? integer Maximum number of splits
---@return string[]
function string.split(str, delimiter, max_splits)
    if not str then return {} end
    if not delimiter or delimiter == '' then
        local result = {}
        for i = 1, #str do
            result[i] = str:sub(i, i)
        end
        return result
    end
    
    local result = {}
    local splits = 0
    local start = 1
    
    while true do
        if max_splits and splits >= max_splits then
            result[#result + 1] = str:sub(start)
            break
        end
        
        local pos = str:find(delimiter, start, true)
        if not pos then
            result[#result + 1] = str:sub(start)
            break
        end
        
        result[#result + 1] = str:sub(start, pos - 1)
        start = pos + #delimiter
        splits += 1
    end
    
    return result
end

---Joins an array of strings with a delimiter
---@param arr string[]
---@param delimiter? string
---@return string
function string.join(arr, delimiter)
    if not arr then return '' end
    return table_concat(arr, delimiter or '')
end

---Checks if string starts with a given prefix
---@param str string
---@param prefix string
---@param case_sensitive? boolean Default: true
---@return boolean
function string.startswith(str, prefix, case_sensitive)
    if not str or not prefix then return false end
    if case_sensitive == false then
        str = str:lower()
        prefix = prefix:lower()
    end
    return str:sub(1, #prefix) == prefix
end

---Checks if string ends with a given suffix
---@param str string
---@param suffix string
---@param case_sensitive? boolean Default: true
---@return boolean
function string.endswith(str, suffix, case_sensitive)
    if not str or not suffix then return false end
    if case_sensitive == false then
        str = str:lower()
        suffix = suffix:lower()
    end
    return str:sub(-#suffix) == suffix
end

---Capitalizes the first letter of a string
---@param str string
---@return string
function string.capitalize(str)
    if not str or str == '' then return str end
    return str:sub(1, 1):upper() .. str:sub(2):lower()
end

---Capitalizes the first letter of each word
---@param str string
---@return string
function string.title(str)
    if not str then return str end

    ---@diagnostic disable-next-line: redundant-return-value
    return str:gsub('(%a)([%w_\']*)', function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

---Counts occurrences of substring in string
---@param str string
---@param pattern string
---@param plain? boolean If true, pattern is treated as plain text
---@return integer
function string.count(str, pattern, plain)
    if not str or not pattern or pattern == '' then return 0 end
    
    local count = 0
    local start = 1
    
    while true do
        local pos = str:find(pattern, start, plain)
        if not pos then break end
        count += 1
        start = pos + (plain and #pattern or 1)
    end
    
    return count
end

---Pads string to specified length
---@param str string
---@param length integer Target length
---@param char? string Padding character (default: space)
---@param side? 'left'|'right'|'both' Padding side (default: 'right')
---@return string
function string.pad(str, length, char, side)
    if not str then return str end
    char = char or ' '
    side = side or 'right'
    
    local current_len = #str
    if current_len >= length then return str end
    
    local padding_needed = length - current_len
    
    if side == 'left' then
        return string_rep(char, padding_needed) .. str
    elseif side == 'both' then
        local left_pad = math_floor(padding_needed / 2)
        local right_pad = padding_needed - left_pad
        return string_rep(char, left_pad) .. str .. string_rep(char, right_pad)
    else -- right
        return str .. string_rep(char, padding_needed)
    end
end

---Truncates string to specified length with optional suffix
---@param str string
---@param length integer Maximum length
---@param suffix? string Suffix to add when truncated (default: '...')
---@return string
function string.truncate(str, length, suffix)
    if not str then return str end
    suffix = suffix or '...'
    
    if #str <= length then return str end
    
    local truncate_at = length - #suffix
    if truncate_at <= 0 then
        return suffix:sub(1, length)
    end
    
    return str:sub(1, truncate_at) .. suffix
end

---Checks if string contains only alphabetic characters
---@param str string
---@return boolean
function string.isalpha(str)
    if not str or str == '' then return false end
    return str:match('^%a+$') ~= nil
end

---Checks if string contains only numeric characters
---@param str string
---@return boolean
function string.isdigit(str)
    if not str or str == '' then return false end
    return str:match('^%d+$') ~= nil
end

---Checks if string contains only alphanumeric characters
---@param str string
---@return boolean
function string.isalnum(str)
    if not str or str == '' then return false end
    return str:match('^%w+$') ~= nil
end

---Checks if string contains only whitespace characters
---@param str string
---@return boolean
function string.isspace(str)
    if not str or str == '' then return false end
    return str:match('^%s+$') ~= nil
end

---Checks if string is empty or contains only whitespace
---@param str string
---@return boolean
function string.isempty(str)
    return not str or str:match('^%s*$') ~= nil
end

---Converts string to camelCase
---@param str string
---@return string
function string.camelcase(str)
    if not str then return str end

    ---@diagnostic disable-next-line: redundant-return-value
    return str:gsub('[^%w]', ' '):gsub('%s+(%w)', function(char)
        return char:upper()
    end):gsub('^%w', function(char)
        return char:lower()
    end):gsub('%s', '')
end

---Converts string to snake_case
---@param str string
---@return string
function string.snakecase(str)
    if not str then return str end
    return str:gsub('(%u)', '_%1'):gsub('^_', ''):gsub('[^%w_]', '_'):gsub('_+', '_'):lower()
end

---Converts string to kebab-case
---@param str string
---@return string
function string.kebabcase(str)
    if not str then return str end
    return str:gsub('(%u)', '-%1'):gsub('^-', ''):gsub('[^%w-]', '-'):gsub('-+', '-'):lower()
end

---Escapes special characters for use in Lua patterns
---@param str string
---@return string
function string.escape(str)
    if not str then return str end
    
    ---@diagnostic disable-next-line: redundant-return-value
    return str:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
end

---Inserts a string at specified position
---@param str string
---@param pos integer Position to insert at (1-based)
---@param insert_str string String to insert
---@return string
function string.insert(str, pos, insert_str)
    if not str or not insert_str then return str end
    pos = math.max(1, math.min(pos, #str + 1))
    return str:sub(1, pos - 1) .. insert_str .. str:sub(pos)
end

---Removes characters from string at specified range
---@param str string
---@param start_pos integer Start position (1-based)
---@param end_pos? integer End position (default: start_pos)
---@return string
function string.remove(str, start_pos, end_pos)
    if not str then return str end
    end_pos = end_pos or start_pos
    start_pos = math.max(1, start_pos)
    end_pos = math.min(#str, end_pos)
    
    if start_pos > end_pos then return str end
    
    return str:sub(1, start_pos - 1) .. str:sub(end_pos + 1)
end

---Wraps text to specified width
---@param str string
---@param width integer Maximum line width
---@param break_long_words? boolean Whether to break long words (default: true)
---@return string
function string.wrap(str, width, break_long_words)
    if not str or width <= 0 then return str end
    break_long_words = break_long_words ~= false
    
    local lines = {}
    local words = str:split('%s+')
    local current_line = ''
    
    for _, word in ipairs(words) do
        if #word > width and break_long_words then
            -- Break long words
            if current_line ~= '' then
                lines[#lines + 1] = current_line
                current_line = ''
            end
            
            while #word > width do
                lines[#lines + 1] = word:sub(1, width)
                word = word:sub(width + 1)
            end
            
            if #word > 0 then
                current_line = word
            end
        elseif #current_line + #word + 1 <= width then
            current_line = current_line == '' and word or current_line .. ' ' .. word
        else
            if current_line ~= '' then
                lines[#lines + 1] = current_line
            end
            current_line = word
        end
    end
    
    if current_line ~= '' then
        lines[#lines + 1] = current_line
    end
    
    return table_concat(lines, '\n')
end

---Centers text within specified width
---@param str string
---@param width integer Target width
---@param fill_char? string Fill character (default: space)
---@return string
function string.center(str, width, fill_char)
    if not str then return str end
    fill_char = fill_char or ' '
    
    local str_len = #str
    if str_len >= width then return str end
    
    local padding = width - str_len
    local left_pad = math_floor(padding / 2)
    local right_pad = padding - left_pad
    
    return string_rep(fill_char, left_pad) .. str .. string_rep(fill_char, right_pad)
end

---Converts string to proper title case following English grammar
---@param str string
---@return string
function string.titlecase(str)
    if not str then return str end
    
    local small_words = {
        a = true, an = true, ['and'] = true, as = true, at = true,
        but = true, by = true, ['for'] = true, ['if'] = true, ['in'] = true,
        of = true, on = true, ['or'] = true, the = true, to = true,
        up = true, via = true, with = true
    }
    
    local words = str:split('%s+')
    
    for i, word in ipairs(words) do
        local lower_word = word:lower()
        if i == 1 or i == #words or not small_words[lower_word] then
            words[i] = word:sub(1, 1):upper() .. word:sub(2):lower()
        else
            words[i] = lower_word
        end
    end
    
    return table_concat(words, ' ')
end

---Generates a simple hash of the string (djb2 algorithm)
---@param str string
---@return integer
function string.hash(str)
    if not str then return 0 end
    
    local hash = 5381
    for i = 1, #str do
        hash = ((hash << 5) + hash) + string_byte(str, i)
        hash = hash & 0xFFFFFFFF -- Keep it 32-bit
    end
    
    return hash
end

---Compares two strings ignoring case
---@param str1 string
---@param str2 string
---@return boolean
function string.iequals(str1, str2)
    if not str1 or not str2 then return str1 == str2 end
    return str1:lower() == str2:lower()
end

return lib.string
