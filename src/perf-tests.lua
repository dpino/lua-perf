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

   local x, y = 1, -1

   jit.flush()

   -- Localize function
   result["localized"] = iterate_times(function(value)
      local max = math.max
      for i=1, 10000 do
         local result = max(value, y)
         value = x + result
      end
   end, 10000)

   jit.flush()

   -- Non-localize function
   result["non-localized"] = iterate_times(function(value)
      for i=1, 10000 do
         local result = math.max(value, y)
         value = x + result
      end
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
   local pow = object.pow

   -- Localize function
   result["localized"] = iterate_times(function(a)
      local result = 0
      for i=1,10000 do
         local x = pow(object)
         local y = pow(object)
         local z = pow(object)
         --[[
         local x = object:pow()
         local y = object:pow()
         local z = object:pow()
         --]]
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
   result["unpack"] = iterate_times(function(value)
      for i=1, 10000 do
         local result = math.min(unpack(a))
         result = result + value
      end
   end, 10000)

   jit.flush()

   -- Non-unpack function
   result["non-unpack"] = iterate_times(function(value)
      for i=1, 10000 do
         local result = math.min(a[1], a[2], a[3], a[4])
         result = result + value
      end
   end, 10000)

   return result
end


-- Test 4. Determine Maximum and Set It.

local function testDetermineMaximumAndSetIt()
   local result = {}

   local max = math.max
   local random = math.random

   -- Max and set
   result["max-and-set"] = iterate_times(function(value)
      for i=1, 10000 do
         local val = max(random(value), value)
         value = val + value
      end
   end, 10000)

   jit.flush()

   -- Local max and set
   result["local-max-and-set"] = iterate_times(function(value)
      for i=1, 10000 do
         local r = random(value)
         if r > value then value = r end
         value = value + value
      end
   end, 10000)

   return result
end


-- Test 5. Nil check.

local function testNilCheck()
   local result = {}

   local max = math.max
   local random = math.random

   -- Max and set
   result["nil-check"] = iterate_times(function(value)
      for i=1, 10000 do
         local y, x
         if random() > 0.5 then y = 1 end
         if y == nil then x = 1 else x = y end
         x = x * value
      end
   end, 10000)

   jit.flush()

   -- Local max and set
   result["use-or"] = iterate_times(function(value)
      for i=1, 10000 do
         local y
         if random() > 0.5 then y = 1 end
         local x = y or 1
         x = x * value
      end
   end, 10000)

   return result
end


-- Test 6. Pow.

local function testPow()
   local result = {}

   local x = 13

   -- Pow operator
   result["pow-operator"] = iterate_times(function(value)
      for i=1, 10000 do
         local y = x^2
         y = y * value
      end
   end, 10000)

   jit.flush()

   -- Multiplication
   result["multiplication"] = iterate_times(function(value)
      for i=1, 10000 do
         local y = x * x
         y = y * value
      end
   end, 10000)

   return result
end


-- Test 7. Modulus operator.

local function testModulus()
   local result = {}

   jit.flush()

   -- Math modulus
   result["math-modulus"] = iterate_times(function(val)
      local fmod = math.fmod
      for i=1,10000 do
         local x = 1
         if fmod(val, 30) < 1 then
            x = 2
         end
         val = val * x
      end
   end, 10000)

   jit.flush()

   -- Modulus operator
   result["modulus-operator"] = iterate_times(function(val)
      for i=1,10000 do
         local x = 1
         if val % 30 < 1 then
            x = 2
         end
         val = val * x
      end
   end, 10000)


   return result
end


-- Test 8. Functions as param for other functions.

local function testFunctionAsParam()
   local result = {}

   local func1 = function(a,b,func)
      return func(a+b)
   end
   local func2 = function(a)
      return a*2
   end

   -- Non localized function
   result["non-localized-function"] = iterate_times(function()
      local result = 1
      for i=1,10000 do
         local x = func1(1, 2, function(val) return val*2 end)
         result = result * x
      end
      return result
   end, 10000)

   jit.flush()

   -- Localized function
   result["localized-function"] = iterate_times(function()
      local result = 1
      for i=1,10000 do
         local x = func1(1, 2, func2)
         result = result * x
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
      for i=1,100 do
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
   end, 1000000)

   jit.flush()

   -- Buffering
   result["buffering"] = iterate_times(function()
      for i=1,#a do
         local y = a[i]
         y.x = y.x + 1
      end
   end, 1000000)

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
      local size = 0
      for i=1,10000 do
         size = size + 1
         result[size] = i
      end
      return result 
   end, 10000)

   return result
end

local function runTests()
   print("-- Test 1. Localize.")
   print_table(make_grid(testLocalize(), {'non-localized', 'localized'}))
   print("-- Test 2. Localize class methods.")
   print_table(make_grid(testLocalizeClassMethods(), {'non-localized', 'localized'}))
   print("-- Test 3. Unpack a table.")
   print_table(make_grid(testUnpack(), {'unpack', 'non-unpack'}))
   print("-- Test 4. Determine Maximum and Set It.")
   print_table(make_grid(testDetermineMaximumAndSetIt(), {'max-and-set', 'local-max-and-set'}))
   print("-- Test 5. Nil check.")
   print_table(make_grid(testNilCheck(), {'nil-check', 'use-or'}))
   print("-- Test 6. Pow.")
   print_table(make_grid(testPow(), {'pow-operator', 'multiplication'}))
   print("-- Test 7. Modulus operator.")
   print_table(make_grid(testModulus(), {'math-modulus', 'modulus-operator'}))
   print("-- Test 8. Functions as param for other functions.")
   print_table(make_grid(testFunctionAsParam(), {'non-localized-function', 'localized-function'}))
   print("-- Test 9. Iterators.")
   print_table(make_grid(testIterators(), {'pairs', 'ipairs', 'indexing'}))
   print("-- Test 10. Array access vs Object access.")
   print_table(make_grid(testArrayAccessVSObjectAccess(), {'array_access', 'object_access'}))
   print("-- Test 11. Buffered table item access.")
   print_table(make_grid(testBufferedTableItemAccess(), {'non-buffering', 'buffering'}))
   print("-- Test 12. Adding table items.")
   print_table(make_grid(testTableInsert(), {'table_insert', 'table_index'}))
end

runTests()
