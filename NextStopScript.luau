local nextStop = script.Parent.NextStop
local display = script.Parent.NextStopText
--local distance = nil
--local nextMarker = nil
local min = nil
local setLine = "X"
local setDest = "Not in service"
local speed = script.Parent.Parent.Parent.Main.controls.Dash.spd
local finished = false
local changePoints = game.ReplicatedStorage.ChangePointsEvent

local lineData = {
	line0 = {
		id = "X",
		from = "Welcome to the board system",
		to = "Not in service",
		stops = nil
	},
	
	line1 = {
		id = "1",
		from = "Harbour",
		to = "Forest Loop",
		stops = {
			"Harbour",
			"Container Terminal",
			"Railyard",
			"Powerplant",
			"Industrial Estate",
			"West Street",
			"TFT Headquarters",
			"Business Plaza",
			"Financial Quarter",
			"Riverside",
			"Main Station",
			"Old Town",
			"Theatre",
			"Main Square",
			"Chad Park",
			"Tramston South",
			"Tram Suburb",
			"Forest Bridge",
			"Duckon Pond",
			"Forest Loop"
		}
	},
	
	line2 = {
		id = "2",
		from = "Shopping Mall",
		to = "Tv Tower",
		stops = {
			"Shopping Mall",
			"City Hotel",
			"Main Square",
			"Chad Park",
			"Tramston South",
			"Tram Suburb",
			"Tram Depot",
			"Media Estate",
			"Tv Tower"
		}
	},
	
	line3 = {
		id = "3",
		from = "Sea Park",
		to = "Shopping Mall",
		stops = {
			"Sea Park",
			"Amber Beach",
			"Seaside Resort",
			"West Street",
			"TFT Headquarters",
			"Business Plaza",
			"Financial Quarter",
			"Riverside",
			"Main Station",
			"Old Town",
			"Theatre",
			"City Hotel",
			"Shopping Mall"
		}
	},
}

local playername = script.Parent.Parent.Parent.Parent.Parent.Name
local player = game.Players:FindFirstChild(playername)
local snackBonus = player.PlayerScripts.SnackBonusScript.SnackBonus

local function searchForPathToKey(key, value)
	local paths = {}
	for line, data in pairs(lineData) do
		if data[key] == value then
			local path = {line, key}
			table.insert(paths, path)
		end
	end
	return paths
end

local function findDistanceTo(object)
	local character = player.Character
	local coordinateDifference = object.Position - character.HumanoidRootPart.Position
	return coordinateDifference.Magnitude
end

local function toMeters(distance)
	return distance * 100 / 357
end

local function findClosestStop(lineId)
	local lineIdData = searchForPathToKey("id", lineId)
	local lineIdNotInData = (#lineIdData == 0)
	if lineId == "X" or lineIdNotInData then
		return nil
	end
	local closestStop = nil
	local line = lineIdData[1][1]
	local currentLineData = lineData[line]
	local lineStops = currentLineData.stops
	local closestIndex = 1
	for index=2, #lineStops do
		local closestStopObject = game.Workspace[lineStops[closestIndex]].TramStop.Marker
		local currentStopObject = game.Workspace[lineStops[index]].TramStop.Marker
		local distanceToClosest = findDistanceTo(closestStopObject)
		local distanceToCurrent = findDistanceTo(currentStopObject)
		if distanceToCurrent < distanceToClosest then
			closestIndex = index
		end
	end
	
	--print("closest stop is " .. lineStops[closestIndex])
	return lineStops[closestIndex]
end

local function findNextStop(lineId, goingDown)
	local lineIdData = searchForPathToKey("id", lineId)
	local lineIdNotInData = (#lineIdData == 0)
	if lineId == "X" or lineIdNotInData then
		return nil
	end
	local closestStop = nil
	local line = lineIdData[1][1]
	local currentLineData = lineData[line]
	local lineStops = currentLineData.stops
	local closestIndex = 1
	for index=2, #lineStops do
		local closestStopObject = game.Workspace[lineStops[closestIndex]].TramStop.Marker
		local currentStopObject = game.Workspace[lineStops[index]].TramStop.Marker
		local distanceToClosest = findDistanceTo(closestStopObject)
		local distanceToCurrent = findDistanceTo(currentStopObject)
		if distanceToCurrent < distanceToClosest then
			closestIndex = index
		end
	end
	
	if goingDown then
		--print("next stop is " .. lineStops[closestIndex+1])
		return lineStops[closestIndex + 1]
	else
		--print("next stop is " .. lineStops[closestIndex-1])
		return lineStops[closestIndex - 1]
	end
end

local function addPoints(number)
	changePoints:FireServer(number)
end

local function displayMessage(message)
	display.Text = message
end

local function isStopped()
	local speedNumber = tonumber(speed.Text)
	return speedNumber > -5 and speedNumber < 5
end

local function isGoingDown(lineId, destination)
	local lineIdData = searchForPathToKey("id", lineId)
	local lineIdNotInData = (#lineIdData == 0)
	if lineId == "X" or lineIdNotInData then
		return nil
	end
	local line = lineIdData[1][1]
	local currentLineData = lineData[line]
	if currentLineData.to == destination then
		return true
	elseif currentLineData.from == destination then
		return false
	else
		return nil
	end
end

local function atEndOfLine(lineId, destination)
	local closestStop = findClosestStop(lineId)
	return closestStop == destination
end

local function setScreen()
	wait()
	setLine = script.Parent.Line.Text
	local closestStop = findClosestStop(setLine)
	if closestStop == nil then
		nextStop.Value = ""
		displayMessage("")
	else
		nextStop.Value = closestStop
	end
	setDest =  script.Parent.To.Text
end
 
script.Parent.Set.MouseButton1Click:connect(setScreen)

--print(player.Name .. " " .. tostring(snackBonus.Value))

local function runProgram(line, destination)
	--nextStop = findClosestStop(line)
	if line == "X" or nextStop.Value == "" then
		displayMessage("")
		return
	end
	local nextMarker = game.Workspace[nextStop.Value].TramStop.Marker
	local distance = findDistanceTo(nextMarker)
	local distanceMeters = toMeters(distance)
	local distanceString = tostring(math.floor(distanceMeters))
	local message = "Next: " .. nextStop.Value  .. " (" .. distanceString .. "m)"
	local loadingCompleted = false
	local lineFinished = false
	displayMessage(message)
	if distanceMeters < 25 then
		if isStopped() then
			displayMessage("Stay here until the passengers board")
			wait(2)
			local timer = 10
			while timer > 0 do
				if isStopped() then
					displayMessage("Loading passengers (" .. timer .. "s)")
					timer = timer - 1
				else
					break
				end
				if timer == 0 then
					loadingCompleted = true
				end
				wait(1)
			end
			
			if atEndOfLine(line, destination) then
				if lineFinished == false then
					if snackBonus.Value == true then
						displayMessage("End of the line (+45 points (snack bonus))")
						addPoints(45)
					else
						displayMessage("End of the line (+30 points)")
						addPoints(30)
					end
					wait(1)
					displayMessage("Please reset the line to Not in Service")
					wait(2)
					setLine = "X"
					nextStop.Value = ""
					displayMessage("")
				end
			else
				if loadingCompleted then
					if snackBonus.Value then
						displayMessage("Loading complete (+15 points (snack bonus))")
						addPoints(15)
					else
						displayMessage("Loading complete (+10 points)")
						addPoints(10)
					end
					wait(1)
				else
					displayMessage("Loading failed (-10 points)")
					addPoints(-10)
					wait(3)
				end
				nextStop.Value = findNextStop(line, isGoingDown(line, destination))
			end
			
			
			
		else
			displayMessage("Stop to let in passengers")
		end
	end
end

while wait(0.1) do
	runProgram(setLine, setDest)
end
