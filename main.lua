-- cache the default print function

local oldPrint = print

-- non holey table to track message content
local printMessages = {}
-- non holey table to track timeout
local printMessageTimeShown = {}
-- string indexed table to track duplicate count
local duplicatePrintMessageTracker = {}

-- puts all recieved prints onto a table
function addToScreenPrintStack(...)
  local flagFoundIdenticalMessage = false
  local foundMessageKey
  local foundMessageValue
  for k, v in ipairs(printMessages) do
    if v == ... then -- TODO 
      flagFoundIdenticalMessage = true -- TODO exit loop
      foundMessageKey = k
      foundMessageValue = v
    end
  end
  if flagFoundIdenticalMessage then
    -- reset the timeout for the duplicate message
    printMessageTimeShown[foundMessageKey] = 0
    -- track duplicates
    if duplicatePrintMessageTracker[foundMessageValue] then
      duplicatePrintMessageTracker[foundMessageValue] = duplicatePrintMessageTracker[foundMessageValue] + 1
    else
      duplicatePrintMessageTracker[foundMessageValue] = 2
    end
  else
    -- push this message onto the end of the table
    printMessages[#printMessages+1] = ... -- TODO Fix this only working for first arg
    -- set the time shown for this mirrored table
    -- at the same index to 0
    printMessageTimeShown[#printMessages] = 0
  end
end

-- redefine the print function to also include love screen printing
print = function(...)
  addToScreenPrintStack(...)
  oldPrint(...)
end

local function update(dt)
  -- increment delta time to all shown messages
  -- flag any messages shown over 2 seconds
  local flagRemoval = {}
  for k, v in ipairs(printMessageTimeShown) do
    if k == 1 then
      printMessageTimeShown[k] = v + dt
    else
    printMessageTimeShown[k] = v + dt*0.25
    end
    if v > 1 then
      flagRemoval[#flagRemoval+1] = k
    end
  end
  -- remove all the flags and the messages shown over 2 seconds
  for _, v in pairs(flagRemoval) do
    table.remove(printMessageTimeShown, v)
    table.remove(printMessages,v)
    -- clear any relevant duplicate message track
    if duplicatePrintMessageTracker[v] then
      duplicatePrintMessageTracker[v] = nil
    end
  end
end

local function draw()
  for k, v in ipairs(printMessages) do
    local messageSuffix = ""
    if duplicatePrintMessageTracker[v] then
      -- set the message to the string of the duplicate count if applicable
      messageSuffix = messageSuffix .. " - " .. duplicatePrintMessageTracker[v]
    end
    love.graphics.setColor( 255, 255, 255, 255 - printMessageTimeShown[k]*250)
    love.graphics.printf(v .. messageSuffix,5,5+(15*(k-1)),200,"left")
  end
end

function love.draw()
  draw()
end

function love.update(dt)
  update(dt)
end

print("Hello")

print("Hi")

print("Wow")

print("Wow")
