#!/usr/bin/env luajit

local bench = require("bench")

local iterate_times, iterate_array = bench.iterate_times, bench.iterate_array
local make_grid, print_table  = bench.make_grid, bench.print_table

local function testLocalize()
   local result = {}

   local max = math.max
   local x, y = 1, -1

   jit.flush()

   -- Non-localize function
   result["non-localized"] = iterate_times(function(value)
      local result = math.max(value, y)
      value = x + result
   end, 100000000)

   jit.flush()

   -- Localize function
   result["localized"] = iterate_times(function(value)
      local result = max(value, y)
      value = x + result
   end, 100000000)

   return result
end

local function testLocalize2()
   local result = {}

   local max = math.max

   jit.flush()

   -- Non-localize function
   result["non-localized"] = iterate_times(function(value)
      local x, y = 1, -1
      for i=1, 10000 do
         local result = math.max(value, y)
         value = x + result
      end
   end, 10000)

   jit.flush()

   -- Localize function
   result["localized"] = iterate_times(function(value)
      local x, y = 1, -1
      for i=1, 10000 do
         local result = max(value, y)
         value = x + result
      end
   end, 10000)

   return result
end

local function runTests()
   print_table(make_grid(testLocalize(), {'non-localized', 'localized'}))
   print_table(make_grid(testLocalize2(), {'non-localized', 'localized'}))
end

runTests()
