-- cache the default print function
local statusPrint = {}

-- for ease of integration when passed a value that
-- cannot be yet converted into a meaningful string value to print
-- on the screen this module simply does nothing silently
-- setting this to true will instead cause the module to
-- throw up an error
statusPrint.errorMode = false

statusPrint.oldPrint = print

-- time in seconds that a message can be shown at
-- messages under the bottom one still showing decay at quarter rate
statusPrint.maxTimeForMessage = 2

-- non holey table to track message content
local printMessages = {}
-- non holey table to track timeout
local printMessageTimeShown = {}
-- string indexed table to track duplicate count
local duplicatePrintMessageTracker = {}

-- puts the recieved print message onto a table
-- nest variable used for somewhat better table recursion printing
-- it is only relevant if passing table arguments as the message
function statusPrint.addToScreenPrintStack(message,nest)
  local msgType = type(message)
  local callAgainForTableValues = false
  if msgType == "string" then
    -- do nothing
  elseif msgType == "number" then
    -- conver the message to a number
    message = message .. ""
  elseif msgType == "boolean" then
    if message then
      message = "true"
    else
      message = "false"
    end
  elseif msgType == "nil" then
    message = "nil"
  elseif msgType == "table" then
    callAgainForTableValues = message
    message = "<table>"
  else
    if statusPrint.errorMode then
      error("Unsupported printing type given: " .. tostring(msgType),1,debug.traceback())
    else
      message = msgType
    end
  end

  -- nest the messages visually that were nested in a table
  if nest and type(nest) == "number" then
    for i = 0, nest do
      message = "--" .. message
    end
  end
  
  local flagFoundIdenticalMessage = false
  local foundMessageIndex
  local foundMessageValue
  for i, v in ipairs(printMessages) do
    if v == message then 
      flagFoundIdenticalMessage = true
      foundMessageIndex = i
      foundMessageValue = v
    end
  end
  if flagFoundIdenticalMessage then
    -- reset the timeout for the duplicate message
    printMessageTimeShown[foundMessageIndex] = 0
    -- track duplicates
    if duplicatePrintMessageTracker[foundMessageValue] then
      duplicatePrintMessageTracker[foundMessageValue] = duplicatePrintMessageTracker[foundMessageValue] + 1
    else
      duplicatePrintMessageTracker[foundMessageValue] = 2
    end
  else
    -- push this message onto the end of the table
    printMessages[#printMessages+1] = message
    -- set the time shown for this mirrored table
    -- at the same index to 0
    printMessageTimeShown[#printMessages] = 0
  end
  
  if callAgainForTableValues then
    if nest then
      nest = nest + 1
    else
      nest = 0
    end
    for _, v in pairs(callAgainForTableValues) do
      -- call the method again for each value in the table
      statusPrint.addToScreenPrintStack(v,nest)
    end
  end
end

-- redefine the print function to also include love screen printing
print = function(...)
  statusPrint.addToScreenPrintStack(...)
  statusPrint.oldPrint(...)
end

function statusPrint.update(dt)
  -- increment delta time to all shown messages
  -- flag any messages shown over 2 seconds
  local flagRemoval = {}
  for k, v in ipairs(printMessageTimeShown) do
    if k == 1 then
      printMessageTimeShown[k] = v + dt
    else
    printMessageTimeShown[k] = v + dt*0.25
    end
    if v > statusPrint.maxTimeForMessage then
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

function statusPrint.draw()
  for i, v in ipairs(printMessages) do
    local messageSuffix = ""
    if duplicatePrintMessageTracker[v] then
      -- set the message to the string of the duplicate count if applicable
      messageSuffix = messageSuffix .. " - " .. duplicatePrintMessageTracker[v]
    end
    love.graphics.setColor( 255, 255, 255, 255 - printMessageTimeShown[i]*250)
    love.graphics.printf(v .. messageSuffix,5,5+(15*(i-1)),200,"left")
  end
end

return statusPrint