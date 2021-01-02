--- Continuous tree harvesting program.
-- Intended for arbitrary 1x1 trees. Larger stumps or trees with branches are
-- not supported.

local DELAY = 5
local MIN_FUEL = 40
local VALID_FUELS = {
  "minecraft:lava_bucket",
  "minecraft:coal",
}
local CAN_MINE = {
  "minecraft:leaves",
  "minecraft:log",
  "minecraft:sapling",
}

--- Prints a yellow warning to the console.
-- @param msg the message to print
local function printWarning(msg)
  local curColor = term.getTextColor()
  term.setTextColor(colors.yellow)
  print("WARNING:", msg)
  term.setTextColor(curColor)
end

--- Checks if a block should be mined.
-- @param blockType the name/type of block.
-- @return whether a block should be mined.
local function canMine(blockType)
  for _, bt in pairs(CAN_MINE) do
    if blockType == bt then
      return true
    end
  end
  return false
end

--- Refuel using all valid fuel in the turtle's inventory.
local function refuel()
  for slot = 1,16,1 do
    turtle.select(slot)
    local details = turtle.getItemDetail()
    if details then
      local itemName = details["name"]
      for _, fuelType in pairs(VALID_FUELS) do
        if itemName == fuelType then
          turtle.refuel()
          break
        end
      end
    end
  end
end

--- Plants a sapling in front of the turtle.
-- @return whether a sapling was found
local function plantSapling()
  -- Scan inventory for sapling.
  -- Start in the last known slot that had saplings.
  local saplingsFound 
  for slot = 1,16,1 do
    turtle.select(slot)
    local details = turtle.getItemDetail()
    if details and details["name"] == "minecraft:sapling" then
      break
    end
  end

  if saplingSlot == 0 then
    printWarning("Out of saplings")
    return false
  end

  -- Plant the sapling.
  turtle.place()
end

--- Harvest a tree in front of the turtle.
-- Assumes there is a tree in front of the turtle.
-- @return whether the tree was harvested
local function harvestTree()
  -- Make sure turtle has enough fuel.
  if turtle.getFuelLevel() < MIN_FUEL then
    refuel()
    if turtle.getFuelLevel() < MIN_FUEL then
      print("Not enough fuel to harvest tree")
      return false
    end
  end

  turtle.select(1)
  local keepGoing = true
  local yDelta = 0
  while keepGoing do
    keepGoing = false
    local hasBlock, blockData = turtle.inspect()
    if hasBlock then
      if blockData["name"] == "minecraft:log" then
        turtle.dig()
        -- Check that the turtle can continue moving up.
        local hasBlockUp, blockDataUp = turtle.inspectUp()
        if hasBlockUp then
          if blockDataUp["name"] == "minecraft:leaves" then
            turtle.digUp()
            if turtle.up() then
              yDelta = yDelta + 1
            end
            keepGoing = true
          end
          -- Else, something else is obstructing the turtle and should not
          -- be mined. 
        else
          if turtle.up() then
            yDelta = yDelta + 1
          end
          keepGoing = true
        end
      end
    end
  end

  -- Return to the start position.
  -- Assumes no blocks have been placed in the turtle's return path since
  -- harvesting began.
  for _ = 1,yDelta,1 do
    local hasPrintedWarning = false
    while true do
      local hasBlock, blockData = turtle.inspectDown()
      if hasBlock and canMine(blockData["name"]) then
        turtle.digDown()
      end
      if turtle.down() then
        break
      elseif not hasPrintedWarning then
        printWarning("Turtle obstructed")
      end
    end
  end

  return true
end

local function main()
  print("Starting tree harvesting program...")
  while true
  do
    local hasBlock, blockData = turtle.inspect()
    if hasBlock then
      blockName = blockData["name"]
      if blockName == "minecraft:log" then
        print("Harvesting tree...")
        if harvestTree() then
          print("Tree harvested")
        end
      elseif blockName == "minecraft:sapling" then
        -- Wait...
      else
        -- Invalid block
        printWarning("Invalid block in front of turtle")
      end
    else
      plantSapling()
    end

    sleep(DELAY)
  end
end

main()
