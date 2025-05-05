local ArrayUtil = {
    _VERSION = 'ArrayUtil v1.0.0',
    _DESCRIPTION =
    'Array method for lua, as a design object, the array is still stored as a table, so if you want to output processing results, use built-in table method',

}



-- Helper function to convert a value to a string representation
local function val_to_str(v)
    if type(v) == 'string' then
        v = string.gsub(v, '\n', '\\n')
        if string.match(string.gsub(v, '[^\'"]', ''), '^"+$') then
            return '"' .. v .. '"'
        end
        return "'" .. string.gsub(v, "'", '\\"') .. "'"
    else
        return type(v) == 'table' and ArrayUtil.toString(v) or tostring(v)
    end
end

-- Helper function to convert a key to a string representation
local function key_to_str(k)
    if type(k) == 'string' and string.match(k, '^[_%a][_%a%d]*$') then
        return k
    else
        return '[' .. val_to_str(k) .. ']'
    end
end

-- Helper & Convenience Functions
function ArrayUtil.getTableType(t)
    local o = { isTable = false, isArray = false, isDictionary = false, isMixed = false }
    local ndx = 0

    if not t then return nil end

    if type(t) == 'table' then
        o.isTable = true
        if ArrayUtil.isEmpty(t) then
            o.isArray = true
        else
            for i, _ in ipairs(t) do
                ndx = ndx + 1
                if i ~= ndx then
                    o.isArray = false
                    o.isMixed = true
                    break
                end
                o.isArray = true
            end

            if not o.isArray and not o.isMixed then
                for k, _ in pairs(t) do
                    if type(k) == 'number' then
                        o.isDictionary = false
                        break
                    end
                    o.isDictionary = true
                end
            end
        end
    end

    return o
end

function ArrayUtil.isArray(t)
    if not t then return nil end
    local tableInfo = ArrayUtil.getTableType(t)
    if tableInfo then
        return tableInfo.isArray
    end
end

function ArrayUtil.isDictionary(t)
    if not t then return nil end
    local tableInfo = ArrayUtil.getTableType(t)
    if tableInfo then
        return tableInfo.isDictionary
    end
end

function ArrayUtil.isEmpty(t)
    if not t then return nil end
    return next(t) == nil
end

function ArrayUtil.isMixed(t)
    if not t then return nil end
    local tableInfo = ArrayUtil.getTableType(t)
    if tableInfo then
        return tableInfo.isMixed
    end
end

function ArrayUtil.isTable(t)
    if not t then return nil end
    return type(t) == 'table'
end

function ArrayUtil.toString(t)
    if not t then return nil end

    local tableInfo = ArrayUtil.getTableType(t)
    local result, done = {}, {}

    if tableInfo.isTable then
        for k, v in ipairs(t) do
            table.insert(result, val_to_str(v))
            done[k] = true
        end

        for k, v in pairs(t) do
            if not done[k] then
                table.insert(result, key_to_str(k) .. '=' .. val_to_str(v))
            end
        end

        return table.concat(result, ',')
    end

    return false
end

-- Array Methods

---@param t table,
---@param searchElement any
---@param startIndex? number
---@param stopIndex? number
---@return number?
---Binary search for the first index of a value in a sorted array.
function ArrayUtil.binaryFirst(t, searchElement, startIndex, stopIndex)
    if not startIndex then startIndex = 1 end
    if not stopIndex then stopIndex = #t end

    while startIndex < stopIndex do
        local middle = math.floor(startIndex + (stopIndex - startIndex) * 0.5)
        local value = t[middle]
        if value < searchElement then
            startIndex = middle + 1
        else
            stopIndex = middle
        end
    end

    if startIndex == stopIndex and t[startIndex] < searchElement then
        startIndex = startIndex + 1
    end

    if startIndex > #t then
        startIndex = nil
    end

    return startIndex
end

---@param t table,
---@param searchElement any
---@param startIndex? number
---@param stopIndex? number
---@return number?
---Binary search for the last index of a value in a sorted array.
function ArrayUtil.binaryLast(t, searchElement, startIndex, stopIndex)
    if not startIndex then startIndex = 1 end
    if not stopIndex then stopIndex = #t end

    while startIndex < stopIndex do
        local middle = math.floor(startIndex + (stopIndex - startIndex) * 0.5)
        local value = t[middle]
        if value <= searchElement then
            startIndex = middle + 1
        else
            stopIndex = middle
        end
    end

    if startIndex == stopIndex and t[startIndex] > searchElement and t[startIndex - 1] == searchElement then
        startIndex = startIndex - 1
    elseif startIndex >= #t and t[startIndex] ~= searchElement and t[startIndex - 1] ~= searchElement then
        startIndex = nil
    end

    return startIndex
end

---@param t table,
---@param indexA number, Starting index for Part A
---@param indexB number, Starting index for Part B
---@param count number, Number of elements to swap
---@return table
---Swap two blocks of an array.
function ArrayUtil.blockSwap(t, indexA, indexB, count)
    local stopA = indexA + count - 1
    local stopB = indexB + count - 1
    local blockA = {}
    local n = 0

    for i = indexA, stopA do
        table.insert(blockA, t[i])
        t[i] = t[indexB + n]
        n = n + 1
    end

    n = 1
    for i = indexB, stopB do
        t[i] = blockA[n]
        n = n + 1
    end

    return t
end

---@param t table, First table
---@param ... any, Additional values or tables to concatenate
---@return table
---Concatenate multiple arrays or values into a new array.
function ArrayUtil.concat(t, ...)
    local tableInfo = ArrayUtil.getTableType(t)
    local newArray = {}
    local args = { ... }

    if tableInfo and tableInfo.isArray then
        for _, v in ipairs(t) do
            table.insert(newArray, v)
        end
        for _, arg in ipairs(args) do
            if type(arg) == 'table' and ArrayUtil.isArray(arg) then
                for _, v in ipairs(arg) do
                    table.insert(newArray, v)
                end
            else
                table.insert(newArray, arg)
            end
        end
    end

    return newArray
end

---@param t table
---@return function
---Returns an iterator function that can be used to iterate over the entries of a table.
function ArrayUtil.entries(t)
    local tableInfo = ArrayUtil.getTableType(t)
    local co

    local function iterateArray()
        for i, v in ipairs(t) do
            coroutine.yield(i, v)
        end
    end

    local function iterateTable()
        for k, v in pairs(t) do
            coroutine.yield(k, v)
        end
    end

    local function next()
        if not co then return nil, nil end
        local _, key, val = coroutine.resume(co)
        return key, val
    end

    if tableInfo and tableInfo.isArray then
        co = coroutine.create(tableInfo.isArray and iterateArray or iterateTable)
    end

    return next
end

---@param t table,
---@param callBack function, Callback function to execute for each element
---@param context any, Context to bind to the callback function
---@return boolean
---Checks if all elements in the array pass the test implemented by the provided function.
function ArrayUtil.every(t, callBack, context)
    local tableInfo = ArrayUtil.getTableType(t)
    local success, result

    if tableInfo and tableInfo.isArray then
        if ArrayUtil.isEmpty(t) then
            return true
        end
        if tableInfo.isArray then
            for i, v in ipairs(t) do
                success, result = pcall(callBack, v, i, t, context or ArrayUtil)
                if not success or not result then
                    return false
                end
            end
        else
            for k, v in pairs(t) do
                success, result = pcall(callBack, v, k, t, context or ArrayUtil)
                if not success or not result then
                    return false
                end
            end
        end
        return true
    end

    return false
end

---@param t table,
---@param val any, Value to fill the array with
---@param start? number, Starting index (inclusive)
---@param stop? number, Endind index (inclusive)
---@return table
---Fills all elements in the array with the specified value.The array shouldn't be empty.
function ArrayUtil.fill(t, val, start, stop)
    local tableInfo = ArrayUtil.getTableType(t)
    local length = ArrayUtil.length(t)

    if tableInfo and tableInfo.isTable then
        if not start or start < 1 then start = 1 end
        if not stop or stop > length then stop = length end
        if tableInfo.isArray then
            for i = start, stop do
                t[i] = val
            end
        else
            for k, _ in pairs(t) do
                t[k] = val
            end
        end
    end

    return t
end

---@param t table,
---@param callBack function, Callback function to execute for each element
---@param context any, Context to bind to the callback function
---@return table
---Filters the elements of the array based on the provided function.
---The array shouldn't be empty.
function ArrayUtil.filter(t, callBack, context)
    local tableInfo = ArrayUtil.getTableType(t)
    local returnArray = {}

    if tableInfo and tableInfo.isTable then
        if tableInfo.isArray then
            for i, v in ipairs(t) do
                local success, result = pcall(callBack, v, i, t, context or ArrayUtil)
                if success and result then
                    table.insert(returnArray, v)
                end
            end
        else
            for k, v in pairs(t) do
                local success, result = pcall(callBack, v, k, t, context or ArrayUtil)
                if success and result then
                    returnArray[k] = v
                end
            end
        end
    end

    return returnArray
end

---@param t table,
---@param callBack function, Callback function to execute for each element
---@param context any, Context to bind to the callback function
---@return any
---Finds the first element in the array that satisfies the provided testing function.
function ArrayUtil.find(t, callBack, context)
    local tableInfo = ArrayUtil.getTableType(t)
    local success, result, found

    if tableInfo and tableInfo.isTable then
        if tableInfo.isArray then
            for i, v in ipairs(t) do
                success, result = pcall(callBack, v, i, t, context or ArrayUtil)
                if success and result then
                    found = v
                    break
                end
            end
        else
            for k, v in pairs(t) do
                success, result = pcall(callBack, v, k, t, context or ArrayUtil)
                if success and result then
                    found = v
                    break
                end
            end
        end
    end

    return found
end

---@param t table,
---@param callBack function, Callback function to execute for each element
---@param context any, Context to bind to the callback function
---@return any
---Finds the index of element in the array that first satisfies the provided testing function.
function ArrayUtil.findIndex(t, callBack, context)
    local tableInfo = ArrayUtil.getTableType(t)
    local found = -1

    if tableInfo and tableInfo.isArray then
        for i, v in ipairs(t) do
            local success, result = pcall(callBack, v, i, t, context or ArrayUtil)
            if success and result then
                found = i
                break
            end
        end
    end

    return found
end

---@param t table,
---@param callBack function, Callback function to execute for each element
---@param context any, Context to bind to the callback function
---Iterates over each element in the array and executes the provided function.
function ArrayUtil.forEach(t, callBack, context)
    local tableInfo = ArrayUtil.getTableType(t)

    if tableInfo and tableInfo.isTable then
        if tableInfo.isArray then
            for i, v in ipairs(t) do
                pcall(callBack, v, i, t, context or ArrayUtil)
            end
        else
            for k, v in pairs(t) do
                pcall(callBack, v, k, t, context or ArrayUtil)
            end
        end
    end
end

---@param o any, Value to convert to an array
---@return table
---Converts a value to an array. If the value is a string, it converts it to an array of characters. If it's a table, it returns the table itself.
function ArrayUtil.from(o)
    local kind = type(o)
    local t = {}

    if kind == 'number' then
        o = tostring(o)
    end

    if kind == 'string' then
        for i = 1, string.len(o) do
            table.insert(t, string.sub(o, i, i))
        end
    elseif kind == 'table' then
        for _, v in pairs(o) do
            table.insert(t, v)
        end
    end

    return t
end

---@param t table,
---@param searchElement any,Element to search for
---@param fromIndex? number, Starting index for the search, default is 1, negative values are counted from the end
---@return boolean
---Checks if the array contains the specified element.
function ArrayUtil.includes(t, searchElement, fromIndex)
    local tableInfo = ArrayUtil.getTableType(t)
    local length = ArrayUtil.length(t)
    local result

    if tableInfo and tableInfo.isTable then
        if fromIndex and fromIndex > length then
            return false
        elseif fromIndex and fromIndex < 0 then
            fromIndex = length + fromIndex
            if fromIndex < 1 then fromIndex = 1 end
        end
        if tableInfo.isArray then
            fromIndex = fromIndex or 1
            for i = fromIndex, length do
                if t[i] == searchElement then
                    return true
                end
            end
            return false
        else
            for _, v in pairs(t) do
                if v == searchElement then
                    return true
                end
            end
            return false
        end
    end

    return false
end

---@param t table,
---@param searchElement any,Element to search for
---@param fromIndex? number, Starting index for the search, default is 1, negative values are counted from the end
---@return number
---Checks if the array contains the specified element, and returns the index of the first occurrence. -1 if not found.
function ArrayUtil.indexOf(t, searchElement, fromIndex)
    local tableInfo = ArrayUtil.getTableType(t)
    local found = -1

    if tableInfo and tableInfo.isArray then
        fromIndex = fromIndex or 1
        if fromIndex < 0 then
            fromIndex = #t + 1 + fromIndex
        end
        if fromIndex < 1 then fromIndex = 1 end
        for i = fromIndex, #t do
            if searchElement == t[i] then
                found = i
                break
            end
        end
    end

    return found
end

---@param t table,
---@param start? number, Starting index for the sort
---@param stop? number, Ending index for the sort
---partially sorts the array using insertion sort algorithm.
function ArrayUtil.insertionSort(t, start, stop)
    start = start or 1
    stop = stop or #t

    if stop == 0 then
        return nil, false
    end

    for i = start + 1, stop do
        local tmp = t[i]
        local j = i - 1
        while j >= start and t[j] > tmp do
            t[j + 1] = t[j]
            j = j - 1
        end
        t[j + 1] = tmp
    end

    return t
end

---@param t table,
---@param separator? string, Separator to use for joining the elements
---@return string
---Joins the elements of the array into a string, separated by the specified separator.
function ArrayUtil.join(t, separator)
    local tableInfo = ArrayUtil.getTableType(t)
    separator = separator or ','

    if tableInfo and tableInfo.isTable then
        if not tableInfo.isArray then
            t = ArrayUtil.from(t)
        end
        return table.concat(t, separator)
    end

    return ''
end

---@param t table,
---@return function
---Returns an iterator function that can be used to iterate over the keys of the array.
function ArrayUtil.keys(t)
    local tableInfo = ArrayUtil.getTableType(t)
    local co

    local function iterateArray()
        for i = 1, #t do
            coroutine.yield(i)
        end
    end

    local function iterateTable()
        for k, _ in pairs(t) do
            coroutine.yield(k)
        end
    end

    local function next()
        if not co then return nil end
        local _, key = coroutine.resume(co)
        return key
    end

    if tableInfo and tableInfo.isTable then
        co = coroutine.create(tableInfo.isArray and iterateArray or iterateTable)
    end

    return next
end

---@param t table,
---@param searchElement any
---@param fromIndex? number
---@return integer
---Finds the last index of the specified element in the array, starting from the end.
---Returns -1 if not found.
function ArrayUtil.lastIndexOf(t, searchElement, fromIndex)
    local tableInfo = ArrayUtil.getTableType(t)
    local found = -1
    local length

    if tableInfo and tableInfo.isArray then
        length = #t
        fromIndex = fromIndex or length
        if fromIndex > length then
            fromIndex = length
        elseif fromIndex < 0 then
            fromIndex = length + fromIndex + 1
        end
        if fromIndex >= 1 then
            for i = fromIndex, 1, -1 do
                if searchElement == t[i] then
                    found = i
                    break
                end
            end
        end
    end

    return found
end

---return the length of the array
---@param t table
---@return integer
function ArrayUtil.length(t)
    local tableInfo = ArrayUtil.getTableType(t)
    local n = 0

    if tableInfo and tableInfo.isTable then
        if tableInfo.isArray then
            return #t
        else
            for _ in pairs(t) do
                n = n + 1
            end
            return n
        end
    end

    return -1
end

---map the array
---@param t table
---@param callBack function, Callback function to execute for each element
---@param context any, Context to bind to the callback function
---@return table
function ArrayUtil.map(t, callBack, context)
    local tableInfo = ArrayUtil.getTableType(t)
    local returnArray = {}

    if tableInfo and tableInfo.isTable then
        if tableInfo.isArray then
            for i, v in ipairs(t) do
                local success, result = pcall(callBack, v, i, t, context or ArrayUtil)
                if success then
                    table.insert(returnArray, result)
                end
            end
        else
            for k, v in pairs(t) do
                local success, result = pcall(callBack, v, k, t, context or ArrayUtil)
                if success then
                    returnArray[k] = result
                end
            end
        end
    end

    return returnArray
end

---return the first element of the array
---@param t table
---@return any
function ArrayUtil.pop(t)
    local tableInfo = ArrayUtil.getTableType(t)
    if tableInfo and tableInfo.isArray then
        return table.remove(t)
    end
end

---insert the elements at the end of the array
---@param t table
---@param ... any
---@return integer
function ArrayUtil.push(t, ...)
    local tableInfo = ArrayUtil.getTableType(t)
    local args = { ... }

    if tableInfo and tableInfo.isArray then
        for _, arg in ipairs(args) do
            table.insert(t, arg)
        end
        return #t
    end
end

---reduce the array
---@param t table
---@param callBack function
---@param initialValue? number
---@return number?
function ArrayUtil.reduce(t, callBack, initialValue)
    local tableInfo = ArrayUtil.getTableType(t)
    local accumulator, success, reducedValue, start, length

    if tableInfo and tableInfo.isArray and #t > 0 and type(callBack) == 'function' then
        length = #t
        if length == 1 then
            return t[1]
        end
        if initialValue ~= nil then
            accumulator = initialValue
            start = 1
        else
            accumulator = t[1]
            start = 2
        end
        for i = start, length do
            success, reducedValue = pcall(callBack, accumulator, t[i], i, t)
            if success then
                accumulator = reducedValue
            else
                return nil
            end
        end
        return reducedValue
    end
end

---reduce the array from right to left
---@param t table
---@param callBack function
---@param initialValue? number
---@return number?
function ArrayUtil.reduceRight(t, callBack, initialValue)
    local tableInfo = ArrayUtil.getTableType(t)
    local accumulator, success, reducedValue, start, length

    if tableInfo and tableInfo.isArray and #t > 0 and type(callBack) == 'function' then
        length = #t
        if length == 1 then
            return t[1]
        end
        if initialValue ~= nil then
            accumulator = initialValue
            start = length
        else
            accumulator = t[length]
            start = length - 1
        end
        for i = start, 1, -1 do
            success, reducedValue = pcall(callBack, accumulator, t[i], i, t)
            if success then
                accumulator = reducedValue
            else
                return nil
            end
        end
        return reducedValue
    end
end

---reverse the array
---@param t table
---@param start number?
---@param stop number?
---@return table
function ArrayUtil.reverse(t, start, stop)
    local tableInfo = ArrayUtil.getTableType(t)
    local length, startIndex, stopIndex

    if tableInfo and tableInfo.isArray then
        length = #t
        start = start or 1
        if start < 1 then
            start = length + start
        end
        if start <= 0 then
            start = 1
        end
        stop = stop or length
        if stop < 0 then
            stop = length + stop
        end
        if stop > length then
            stop = length
        end
        if stop < start then
            stop = start
        end

        for i = 0, math.floor((stop - start) / 2) do
            startIndex = start + i
            stopIndex = stop - i
            if startIndex ~= stopIndex then
                t[startIndex], t[stopIndex] = t[stopIndex], t[startIndex]
            end
        end
    end

    return t
end

---shift the first element of the array
---@param t table
---@return number?
function ArrayUtil.shift(t)
    local tableInfo = ArrayUtil.getTableType(t)
    if tableInfo and tableInfo.isArray and #t > 0 then
        return table.remove(t, 1)
    end
end

---slice the array
---@param t table
---@param begin? number,Starting index (inclusive)
---@param stop? number, Ending index (exclusive)
---@return table
function ArrayUtil.slice(t, begin, stop)
    local tableInfo = ArrayUtil.getTableType(t)
    local newArray = {}
    local L

    if tableInfo and tableInfo.isArray then
        L = #t
        begin = begin or 1
        if begin < 0 then
            begin = L + begin
        end
        if begin <= 0 then
            begin = 1
        end
        stop = stop or L
        if stop < 0 then
            stop = L + stop
        end
        if stop > L then
            stop = L
        end

        for i = begin, stop do
            table.insert(newArray, t[i])
        end
    end

    return newArray
end

---check if the array has at least one element that satisfies the provided testing function
---@param t table
---@param callBack function
---@param context any
---@return boolean
function ArrayUtil.some(t, callBack, context)
    local tableInfo = ArrayUtil.getTableType(t)
    local success, result

    if tableInfo and tableInfo.isTable then
        if tableInfo.isArray then
            for i, v in ipairs(t) do
                success, result = pcall(callBack, v, i, t, context or ArrayUtil)
                if success and result then
                    return true
                end
            end
        else
            for k, v in pairs(t) do
                success, result = pcall(callBack, v, k, t, context or ArrayUtil)
                if success and result then
                    return true
                end
            end
        end
    end

    return false
end

---Sort the array or key-value pairs of a table.
---@async
---@param t table
---@param ... any,If it is a number, the built-in function will be called. Custom functions can also be passed in.
---@return table
function ArrayUtil.sort(t, ...)
    local tableInfo = ArrayUtil.getTableType(t)
    local args = { ... }
    local direction, sortFunction

    local function descend(a, b)
        return a > b
    end

    local function tableAscend(a, b)
        return t[a] < t[b]
    end

    local function tableDescend(a, b)
        return t[a] > t[b]
    end

    if tableInfo and tableInfo.isTable then
        if #args > 0 then
            direction = args[1]
            if type(direction) == 'function' then
                sortFunction = direction
                direction = -1
            elseif #args == 2 then
                sortFunction = args[2]
            end
        end

        if tableInfo.isArray then
            if not sortFunction and direction == 1 then
                sortFunction = descend
            end
            table.sort(t, sortFunction)
        else
            sortFunction = sortFunction or (direction == 1 and tableDescend or tableAscend)
            local keyMap = {}
            local x = 0
            for k in pairs(t) do
                x = x + 1
                keyMap[x] = k
            end
            table.sort(keyMap, sortFunction)

            local function iterate()
                for _, v in ipairs(keyMap) do
                    coroutine.yield(v, t[v])
                end
            end

            local co = coroutine.create(iterate)
            local function next()
                if not co then return nil end
                local _, key, val = coroutine.resume(co)
                return key, val
            end

            return next, t
        end
    end

    return t
end

---Remove or replace existing elements in-place and/or add new elements
---@param t table
---@param begin number
---@param deleteCount? number
---@param ... any
---@return table
function ArrayUtil.splice(t, begin, deleteCount, ...)
    local tableInfo = ArrayUtil.getTableType(t)
    local args = { ... }
    local removed = {}
    local L, stop, r

    if tableInfo and tableInfo.isArray then
        L = #t
        if begin > L then
            begin = L
        elseif begin < 0 then
            begin = L + begin
        end
        if begin <= 0 then
            begin = 1
        end
        deleteCount = deleteCount or L

        if deleteCount > 0 then
            stop = begin + deleteCount - 1
            if stop > L then
                stop = L
            end
            for i = stop, begin, -1 do
                r = table.remove(t, i)
                table.insert(removed, r)
            end
            if #removed > 0 then
                removed = ArrayUtil.reverse(removed)
            end
        end

        if #args > 0 then
            if deleteCount == 0 then
                begin = begin + 1
            end
            for i, v in ipairs(args) do
                table.insert(t, begin + i - 1, v)
            end
        end
    end

    return removed
end

---Swap elements at a given position in an array
---@param t table
---@param ndx1 number
---@param ndx2 number
---@return table
function ArrayUtil.swap(t, ndx1, ndx2)
    local tableInfo = ArrayUtil.getTableType(t)
    if tableInfo and tableInfo.isArray then
        t[ndx1], t[ndx2] = t[ndx2], t[ndx1]
    end
    return t
end

---Add new elements to the beginning of the array
---@param t table
---@param ... any
---@return number
function ArrayUtil.unshift(t, ...)
    local args = { ... }
    local tableInfo = ArrayUtil.getTableType(t)

    if tableInfo and tableInfo.isArray then
        for i, v in ipairs(args) do
            table.insert(t, i, v)
        end
        return #t
    end
end

---Get the values of the array or table
---@param t table
---@return function
function ArrayUtil.values(t)
    local tableInfo = ArrayUtil.getTableType(t)
    local co

    local function iterateArray()
        for _, v in ipairs(t) do
            coroutine.yield(v)
        end
    end

    local function iterateTable()
        for _, v in pairs(t) do
            coroutine.yield(v)
        end
    end

    local function next()
        if not co then return nil end
        local _, val = coroutine.resume(co)
        return val
    end

    if tableInfo and tableInfo.isTable then
        co = coroutine.create(tableInfo.isArray and iterateArray or iterateTable)
    end

    return next
end

return ArrayUtil
