local statusPrint = {
  _VERSION     = 'Status Print 0.1',
  _DESCRIPTION = 'Overrides print() to add love2d display on screen',
  _URL         = 'https://github.com/Skeletonxf/Love-Status-Print',
  _LICENSE = [[
    ZLIB license

    Copyright © 2016 Skeletonxf

    This software is provided 'as-is', without any express or implied
    warranty. In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
      claim that you wrote the original software. If you use this software
      in a product, an acknowledgement in the product documentation would be
      appreciated but is not required.
    2. Altered source versions must be plainly marked as such, and must not be
      misrepresented as being the original software.
    3. This notice may not be removed or altered from any source distribution.
  ]]
}

-- for ease of integration when passed a value that
-- cannot be yet converted into a meaningful string value to print
-- on the screen this module simply does nothing silently
-- setting this to true will instead cause the module to
-- throw up an error
statusPrint.errorMode = false

-- make a copy of the default print function
statusPrint.oldPrint = print

-- min time in seconds that a message can be shown at
-- messages under the bottom one still showing decay at quarter rate
-- so will last longer
statusPrint.minTimeForMessage = 1.5

-- string to set printing location
-- "top" is the top corner of the screen (and the default behaviour)
-- "bottom-left" will print from the bottom left corner of the screen
statusPrint.screenPrintLocation = "top"

-- word wrap length for printing
statusPrint.maxLineLength = 200

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
    if v > statusPrint.minTimeForMessage then
      flagRemoval[#flagRemoval+1] = k
    end
  end
  -- remove all the flags and the messages shown over the time
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
  local verticalStep = 15
  local paddingX = 5
  local paddingY = 5
  local startYPrint = 0
  if statusPrint.screenPrintLocation == "bottom-left" then
    verticalStep = -verticalStep
    startYPrint = love.graphics.getHeight()
    paddingY = -25
  else
    -- default behaviour
  end
  for i, v in ipairs(printMessages) do
    local messageSuffix = ""
    if duplicatePrintMessageTracker[v] then
      -- set the message to the string of the duplicate count if applicable
      messageSuffix = messageSuffix .. " - " .. duplicatePrintMessageTracker[v]
    end
    love.graphics.setColor( 255, 255, 255,
      255 - (printMessageTimeShown[i]/statusPrint.minTimeForMessage)*250)
    love.graphics.printf(v .. messageSuffix,
      paddingX,startYPrint+paddingY+(verticalStep*(i-1)),statusPrint.maxLineLength,"left")
  end
end

return statusPrint