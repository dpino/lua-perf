module(...,package.seeall)

local function array(n)
   local result = {}
   for i=1, n do
      table.insert(result, tostring(i))
   end
   return result
end

function iterate_array(f, times)
   times = times or 100000000
   local a = array(100)
   local begin = os.clock()
   for i=1,times do
      f(a)
   end
   local finish = os.clock()
   return finish - begin
end

function iterate_times(f, times)
   times = times or 100000000
   local begin = os.clock()
   for i=1, times do
      f(i)
   end
   local finish = os.clock()
   return finish - begin
end

function print_table(t, header)
   local function print_row(row, pattern)
      io.write(("| "..pattern.." |"):format(row[1]))
      for i=2, #row do
         io.write(string.format((" "..pattern.." |"):format(row[i])))
      end
      io.write("\n")
   end
   local function print_datarow(header)
      print_row(header, "%.6f")
   end
   local function print_header(header)
      print_row(header, "%s")
   end

   print_header(t[1])
   for i=2, #t do
      print_datarow(t[i])
   end
   io.write("\n")
end

function make_grid(data, keys)
   local grid = {}

   local header = {}
   for _, k in ipairs(keys) do
      table.insert(header, k)
   end
   table.insert(grid, header)

   for i=1,#keys do
      local k1 = keys[i]
      local row = {}
      for j=1,#keys do
         local k2 = keys[j]
         table.insert(row, data[k1]/data[k2])
      end
      table.insert(grid, row)
   end
   
   return grid
end
