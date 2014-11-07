#!/usr/bin/env luajit

local bench = require("bench")

local iterate_times, iterate_array = bench.iterate_times, bench.iterate_array
local make_grid, print_table  = bench.make_grid, bench.print_table

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

print_table(make_grid(testLocalize(), {'non-localized', 'localized'}))
