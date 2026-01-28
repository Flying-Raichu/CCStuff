local SIZE = 5
local SEED_SLOT = 1

local function selectSeeds()
  turtle.select(SEED_SLOT)
end

local function forwardOrRetry()
  while not turtle.forward() do
    turtle.attack()
    sleep(0.2)
  end
end

local function harvestAndPlantDown()
  -- Look at the crop BELOW the turtle
  local ok, data = turtle.inspectDown()

  -- If there's a mature wheat crop, harvest it
  if ok and data.name == "minecraft:wheat" then
    if data.state and data.state.age and data.state.age >= 7 then
      turtle.digDown()
    end
  end

  -- If there's nothing below (or we just harvested), plant seeds
  local ok2, data2 = turtle.inspectDown()
  if not ok2 then
    selectSeeds()
    if turtle.getItemCount(SEED_SLOT) == 0 then
      error("Out of seeds in slot 1!")
    end
    turtle.placeDown()
  end
end

local function doRow()
  for col = 1, SIZE do
    harvestAndPlantDown()
    if col < SIZE then forwardOrRetry() end
  end
end

local function nextRow(row)
  if row >= SIZE then return end

  if row % 2 == 1 then
    turtle.turnRight()
    forwardOrRetry()
    turtle.turnRight()
  else
    turtle.turnLeft()
    forwardOrRetry()
    turtle.turnLeft()
  end
end

local function goHome()
  -- Turn around
  turtle.turnLeft()
  turtle.turnLeft()

  -- Snake back across rows
  for row = SIZE, 1, -1 do
    for i = 1, SIZE - 1 do forwardOrRetry() end
    if row > 1 then
      if row % 2 == 1 then
        turtle.turnLeft()
        forwardOrRetry()
        turtle.turnLeft()
      else
        turtle.turnRight()
        forwardOrRetry()
        turtle.turnRight()
      end
    end
  end

  -- Face original direction
  turtle.turnLeft()
  turtle.turnLeft()
end

selectSeeds()

for row = 1, SIZE do
  doRow()
  nextRow(row)
end

goHome()
print("Done!")
