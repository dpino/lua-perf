#!/usr/bin/env luajit

-- Benchmark based on http://springrts.com/wiki/Lua_Performance

local bench = require("bench")

local iterate_times, iterate_array = bench.iterate_times, bench.iterate_array
local make_grid, print_table  = bench.make_grid, bench.print_table

local data = {}

-- jit.off(true, true)

-- Test 1. Localize.

local function testLocalize()
   local result = {}

   jit.flush()

   -- Non-localized function
   result["non-localized"] = iterate_times(function()
      local result = 0
      for i=1, 10000 do
         local value = math.max(i, result)
         if result < value then
            result = i
         end
      end
      return result
   end, 10000)

   jit.flush()

   -- Localized function
   result["localized"] = iterate_times(function()
      local max = math.max
      local result = 0
      for i=1, 10000 do
         local value = max(i, result)
         if result < value then
            result = i
         end
      end
      return result
   end, 10000)

   return result
end


-- Test 2. Localize class methods.

local function testLocalizeClassMethods()
   local result = {}

   local MyClass = {}
   function MyClass.new(val)
      return setmetatable({value = val}, {__index = MyClass})
   end
   function MyClass.pow(self)
      return self.value * self.value
   end

   local object = MyClass.new(2)

   -- Localize function
   result["localized"] = iterate_times(function(a)
      local result = 0
      local pow = object.pow
      for i=1,10000 do
         local x = pow(object)
         local y = pow(object)
         local z = pow(object)
         result = result + (x + y + z)
      end
      return result
   end, 10000)

   jit.flush()

   -- Non-localize function
   result["non-localized"] = iterate_times(function(a)
      local result = 0
      for i=1,10000 do
         local x = object:pow()
         local y = object:pow()
         local z = object:pow()
         result = result + (x + y + z)
      end
      return result
   end, 10000)

   return result
end


-- Test 3. Unpack a table.

local function testUnpack()
   local result = {}

   local a = { 100, 200, 50, 75 }

   -- Unpack function
   result["unpack"] = iterate_times(function()
      local result
      for i=1, 10000 do
         result = math.min(unpack(a))
         result = result + i
      end
      return result
   end, 10000)

   jit.flush()

   local a = (function()
      local result = {}
      for i=1, 10000 do
         result[i] = i
      end
      return result
   end)()

   -- Non-unpack function
   result["non-unpack"] = iterate_times(function()
      local result
      for i=1, 10000-4 do
         result = math.min(a[i], a[i+1], a[i+2], a[i+3])
         result = result + i
      end
      return result
   end, 10000)

   return result
end


-- Test 4. Determine Maximum and Set It.

local function testDetermineMaximumAndSetIt()
   local result = {}

   local array = (function()
      local result = {}
      for i=1, 10000 do
         result[i] = math.floor(math.random(i)*10000)
      end
      return result
   end)()

   -- Max and set
   result["max-and-set"] = iterate_times(function()
      local max = math.max
      local result = 0
      for _, value in ipairs(array) do
         result = max(result, value)
      end
      return result
   end, 10000)

   jit.flush()

   -- Local max and set
   result["local-max-and-set"] = iterate_times(function()
      local result = 0
      for _, value in ipairs(array) do
         if value > result then result = value end
      end
      return result
   end, 10000)

   return result
end


-- Test 5. Nil check.

local function testNilCheck()
   local result = {}

   local max = math.max

   local array = (function()
      local result = {}
      for i=1, 10000 do
         result[i] = math.floor(math.random(i)*10000)
      end
      return result
   end)()

   -- Max and set
   result["nil-check"] = iterate_times(function()
      local result = 0
      for _, value in ipairs(array) do
         local y
         if value > 0.5 then y = 1 end
         if not y then result = 1 else result = y end
      end
      return result
   end, 10000)

   jit.flush()

   -- Local max and set
   result["use-or"] = iterate_times(function()
      local result, value = 0, 0
      for _, value in ipairs(array) do
         local y
         if value > 0.5 then y = 1 end
         result = y or 1
      end
      return result
   end, 10000)

   return result
end


-- Test 6. Pow.

local function testPow()
   local result = {}

   local array = (function()
      local result = {}
      for i=1, 10000 do
         result[i] = math.floor(math.random(i)) % 3
      end
      return result
   end)()

   -- Pow operator
   result["pow-operator"] = iterate_times(function()
      local result = 0
      for _, value in ipairs(array) do
         result = result + (value^2)
      end
      return result
   end, 10000)

   jit.flush()

   -- Multiplication
   result["multiplication"] = iterate_times(function()
      local result = 0
      for _, value in ipairs(array) do
         result = result + (value*value)
      end
      return result
   end, 10000)

   return result
end


-- Test 7. Modulus operator.

local function testModulus()
   local result = {}

   jit.flush()

   -- Math modulus
   result["math-modulus"] = iterate_times(function()
      local fmod = math.fmod
      local result = 0
      for i=1,10000 do
         local x = 1
         if fmod(i, 30) < 1 then
            x = 2
         end
         result = result * x
      end
      return result
   end, 10000)

   jit.flush()

   -- Modulus operator
   result["modulus-operator"] = iterate_times(function()
      local result = 0
      for i=1,10000 do
         local x = 1
         if i % 30 < 1 then
            x = 2
         end
         result = result * x
      end
      return result
   end, 10000)


   return result
end


-- Test 8. Functions as param for other functions.

local function testFunctionAsParam()
   local result = {}

   local MAX = 1000
   local array = (function()
      local result = {}
      for i=1, MAX do
         result[i] = math.floor(math.random(i)) % 10
      end
      return result
   end)()
   local func1 = function(a,b,func)
      return func(a+b)
   end

   -- Non localized function
   result["non-localized-function"] = iterate_times(function()
      local result = 1
      for i=1,MAX-1 do
         local val1, val2 = array[i], array[i+1]
         local x = func1(val1, val2, function(val) return val*2 end)
         result = result + x
      end
      return result
   end, 10000)

   jit.flush()

   -- Localized function
   result["localized-function"] = iterate_times(function()
      local result = 1
      for i=1,MAX-1 do
         local func2 = function(a)
            return a*2
         end
         local val1, val2 = array[i], array[i+1]
         local x = func1(val1, val2, func2)
         result = result + x
      end
      return result
   end, 10000)

   return result
end


-- Test 9. Iterators.

local function testIterators()
   local result = {}

   jit.flush()

   -- Pairs
   result["pairs"] = iterate_array(function(a)
      local result = 0
      for j,v in pairs(a) do
         result = result + v
      end
      return result
   end, 1000000)

   jit.flush()

   -- iPairs
   result["ipairs"] = iterate_array(function(a)
      local result = 0
      for _,v in ipairs(a) do
         result = result + v
      end
      return result
   end, 1000000)

   jit.flush()

   -- Indexing
   result["indexing"] = iterate_array(function(a)
      local result = 0
      for i=1,#a do
         result = result + a[i]
      end
      return result
   end, 1000000)

   return result
end


-- Test 10. Array access vs Object access.

local function testArrayAccessVSObjectAccess()
   local result = {}

   local a = { foo="foo" }

   jit.flush()

   -- Array access
   result["array_access"] = iterate_times(function()
      local result = {}
      for i=1,10000 do
         table.insert(result, a["foo"])
      end
      return result
   end, 10000)

   jit.flush()

   -- Object access
   result["object_access"] = iterate_times(function()
      local result = {}
      for i=1,10000 do
         table.insert(result, a.foo)
      end
      return result
   end, 10000)

   return result
end


-- Test 11. Buffered table item access.

local function testBufferedTableItemAccess()
   local result = {}

   local a = (function()
      local result = {}
      for i=1,10000 do
         result[i] = { x = i }
      end
      return result
   end)()

   jit.flush()

   -- Non-buffering
   result["non-buffering"] = iterate_times(function()
      for i=1,#a do
         a[i].x = a[i].x + 1
      end
   end, 10000)

   jit.flush()

   -- Buffering
   result["buffering"] = iterate_times(function()
      for i=1,#a do
         local y = a[i]
         y.x = y.x + 1
      end
   end, 10000)

   return result
end


-- Test 12. Adding table items.

local function testTableInsert()
   local result = {}

   jit.flush()

   -- Table insert
   result["table_insert"] = iterate_times(function()
      local result = {}
      for i=1,10000 do
         table.insert(result, i)
      end
      return result
   end, 10000)

   jit.flush()

   local size = 0

   -- Table index
   result["table_index"] = iterate_times(function(value)
      local result = {}
      local size = 1
      for i=1,10000 do
         result[size] = i
         size = size + 1
      end
      return result
   end, 10000)

   return result
end

local function runTests()
   print("<i>-- Test 1. Localize.</i>")
   print_table(make_grid(testLocalize(), {'non-localized', 'localized'}))
   print("<i>-- Test 2. Localize class methods.</i>")
   print_table(make_grid(testLocalizeClassMethods(), {'non-localized', 'localized'}))
   print("<i>-- Test 3. Unpack a table.</i>")
   print_table(make_grid(testUnpack(), {'unpack', 'non-unpack'}))
   print("<i>-- Test 4. Determine Maximum and Set It.</i>")
   print_table(make_grid(testDetermineMaximumAndSetIt(), {'max-and-set', 'local-max-and-set'}))
   print("<i>-- Test 5. Nil check.</i>")
   print_table(make_grid(testNilCheck(), {'nil-check', 'use-or'}))
   print("<i>-- Test 6. Pow.</i>")
   print_table(make_grid(testPow(), {'pow-operator', 'multiplication'}))
   print("<i>-- Test 7. Modulus operator.</i>")
   print_table(make_grid(testModulus(), {'math-modulus', 'modulus-operator'}))
   print("<i>-- Test 8. Functions as param for other functions.</i>")
   print_table(make_grid(testFunctionAsParam(), {'non-localized-function', 'localized-function'}))
   print("<i>-- Test 9. Iterators.</i>")
   print_table(make_grid(testIterators(), {'pairs', 'ipairs', 'indexing'}))
   print("<i>-- Test 10. Array access vs Object access.</i>")
   print_table(make_grid(testArrayAccessVSObjectAccess(), {'array_access', 'object_access'}))
   print("<i>-- Test 11. Buffered table item access.</i>")
   print_table(make_grid(testBufferedTableItemAccess(), {'non-buffering', 'buffering'}))
   print("<i>-- Test 12. Adding table items.</i>")
   print_table(make_grid(testTableInsert(), {'table_insert', 'table_index'}))
end

runTests()
