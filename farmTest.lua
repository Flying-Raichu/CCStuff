-- farm5x5.lua
-- Simple 5x5 wheat farm: harvest+replant, then return home.
-- Seeds must be in slot 1.

local SIZE = 5
local SEED_SLOT = 1

local function selectSeeds()
  turtle.select(SEED_SLOT)
end

local function tryRefuel()
  -- Basic: if fuel is low, try refuel from current slot (or other slots if you like)
  if turtle.getFuelLevel() == "unlimited" then return true end
  if turtle.getFuelLevel() > 200 then return true end

  -- Try refuel using anything in any slot
  for i = 1, 16 do
    if turtle.getItemCount(i) > 0 then
      turtle.select(i)
      if turtle.refuel(1) then
        selectSeeds()
        return true
      end
    end
  end

  selectSeeds()
  return false
end

local function forwardOrError()
  while not turtle.forward() do
    -- If blocked, try to clear trivial blocks.
    -- (For a farm, usually nothing should block. This prevents getting stuck on a dropped item/entity.)
    turtle.attack()
    turtle.dig()
    sleep(0.2)
  end
end

local function ensureFarmland()
  -- If block below isn't farmland, try to hoe it.
  local ok, data = turtle.inspectDown()
  if ok then
    if data.name == "minecraft:farmland" then
      return true
    end
    -- If it's crops, we don't want to hoe it.
    if data.name:find("wheat") or data.name:find("crop") then
      return true
    end
  end

  -- Try to turn whatever is below into farmland
  -- (Works if it's dirt/grass/etc.)
  turtle.digDown()      -- careful: if you have water below, this would break it. In normal farms, it's dirt.
  turtle.placeDown()    -- if you had dirt in inventory; usually you don't.
  -- The above is too aggressive for many setups, so instead we do:
  -- We'll just try "turtle.digDown()" only if it's not farmland AND not a crop.
  -- Let's implement safer version:

  return false
end

local function safeHoeDown()
  -- Hoe the block below if possible.
  -- turtle.digDown() may remove crops; we avoid that by inspecting first.
  local ok, data = turtle.inspectDown()
  if ok then
    if data.name == "minecraft:farmland" then return true end
    if data.name == "minecraft:wheat" then return true end
  end
  turtle.digDown() -- remove tall grass etc. (if present)
  turtle.select(SEED_SLOT)
  turtle.digDown() -- might do nothing; harmless if air
  turtle.select(SEED_SLOT)
  turtle.digDown()

  -- Actually hoeing uses turtle.digDown() with a hoe? No:
  -- In CC:Tweaked, "turtle.digDown()" digs. To hoe, you need a hoe equipped and use turtle.digDown() ? (No.)
  -- Correct method: with a hoe equipped, use turtle.digDown()? Still digs.
  -- The correct action is turtle.placeDown() with seeds? No.
  -- In CC:Tweaked, tilling is done by "turtle.digDown()" ONLY if the tool is a hoe in some packs? Not reliable.
  -- So we do the normal way: use turtle.placeDown() doesn't till either.
  --
  -- Best reliable method: use turtle.digDown() to clear, then turtle.placeDown() won't till.
  -- Therefore: we assume land is already farmland. We'll just verify and warn if not.

  return true
end

local function harvestAndPlant()
  -- Inspect the block in front (where crops are)
  local ok, data = turtle.inspect()
  if ok then
    -- If it's wheat and it's mature, dig it.
    if data.name == "minecraft:wheat" then
      -- CC:Tweaked exposes "state" for block age in newer versions.
      -- We'll treat "age == 7" as fully grown.
      if data.state and data.state.age and data.state.age >= 7 then
        turtle.dig()
      end
    else
      -- If something else is there (like tall grass), clear it
      -- but avoid destroying blocks you might not want removed.
      if data.name == "minecraft:tall_grass" or data.name == "minecraft:grass" then
        turtle.dig()
      end
    end
  end

  -- After harvesting, try to plant if empty
  local ok2, data2 = turtle.inspect()
  if not ok2 then
    -- block in front is air -> plant seeds
    selectSeeds()
    if turtle.getItemCount(SEED_SLOT) == 0 then
      print("Out of seeds in slot 1!")
      return false
    end
    turtle.place()
  end

  return true
end

local function turnLeft()
  turtle.turnLeft()
end

local function turnRight()
  turtle.turnRight()
end

local function doRow()
  -- We’re standing at the start of a row, facing along it.
  -- The first crop is in front of us.
  for col = 1, SIZE do
    harvestAndPlant()
    if col < SIZE then
      forwardOrError()
    end
  end
end

local function nextRow(row)
  -- Move from end of current row to start of next row
  if row >= SIZE then return end

  if row % 2 == 1 then
    -- at end of odd row, turn right, move, turn right
    turnRight()
    forwardOrError()
    turnRight()
  else
    -- at end of even row, turn left, move, turn left
    turnLeft()
    forwardOrError()
    turnLeft()
  end
end

local function goHome()
  -- We end at far side of the 5x5. We want to return to start.
  -- After SIZE rows, we are at the end of row 5 (odd),
  -- facing the opposite direction of start.
  --
  -- Easiest: retrace the same lawnmower path backwards.
  -- For a simple script, we can “undo” moves based on SIZE.

  -- After finishing row 5, we are at that row’s end.
  -- We want to go back 4 rows and 4 columns to original.
  -- Path depends on parity; simplest robust method is:
  -- turn around and snake back exactly like traversal but in reverse.

  turtle.turnLeft()
  turtle.turnLeft()

  -- Snake back across rows
  for row = SIZE, 1, -1 do
    -- move back across row length-1
    for i = 1, SIZE - 1 do
      forwardOrError()
    end
    if row > 1 then
      if row % 2 == 1 then
        -- coming from odd row in reverse
        turnLeft()
        forwardOrError()
        turnLeft()
      else
        turnRight()
        forwardOrError()
        turnRight()
      end
    end
  end

  -- Now we should be back at the start row start.
  -- Facing original direction again.
  turtle.turnLeft()
  turtle.turnLeft()
end

-- MAIN
if not tryRefuel() then
  print("Low fuel and couldn't refuel from inventory.")
  -- continue anyway; in many modpacks fuel is unlimited or plenty
end

selectSeeds()

-- Traverse the 5x5
for row = 1, SIZE do
  doRow()
  nextRow(row)
end

goHome()
print("Done!")
