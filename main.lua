sp = require("statusPrint")

function love.draw()
  sp.draw()
end

function love.update(dt)
  sp.update(dt)
end

print("Hello")

print("Hi","OK")

print("Wow")

print("Wow")

print(function() print("Wow") end)

print({{"wow"},"hi",5})

--print(sp.draw)

--print(draw)