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
   local function wrap(tag, value)
      return ("<%s>%s</%s>"):format(tag, value, tag)
   end
   local function row(data, tag, pattern)
      tag = tag or "td"
      local result = {}
      for i=1, #data do
         table.insert(result, wrap(tag, (pattern):format(data[i])))
      end
      return table.concat(result, "\n")
   end
   local function datarow(data)
      return wrap("tr", row(data, "td", "%.6f"))
   end
   local function header(data)
      return wrap("tr", row(data, "th", "%s"))
   end

   local datarows = {}
   for i=2, #t do
      table.insert(datarows, datarow(t[i]))
   end

   print(([[
   <table>
      <thead>
         %s
      </thead>
      <tbody>
         %s
      </tbody>
   </table>
   ]]
   ):format(header(t[1]), table.concat(datarows, "\n")))
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
