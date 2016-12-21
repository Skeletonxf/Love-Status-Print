sp = require("statusPrint")

function love.draw()
  sp.draw()
end

function love.update(dt)
  sp.update(dt)
end

print("Hello")

-- the module doesn't notice "OK"
print("Hi","OK")

print("Wow")

print("Wow")

-- module just prints "function"
print(function() print("Wow") end)

-- module prints each value out recursively and visually
-- nests the contents with "--"
print({{"wow"},"hi",5}) 


--print(sp.draw)

--print(draw)