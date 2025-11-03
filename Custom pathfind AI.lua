--!nocheck
--services
local PathFindingService = game:GetService("PathfindingService")
local OOP = require(script.OOP)
local WaypointClearConfig = require(workspace.Actor.WayPointClear.Config)

--settings
local VisualRayEnabled = false
local VisualLPSEnabled = true

--registers the NPC
local NPC = OOP.New(script.Parent, VisualRayEnabled, VisualLPSEnabled)

--NPC body parts
local char = NPC.Character
local head = NPC.Head
local Torso = NPC.Torso
local Hum = NPC.Humanoid

--raycast options
local FovDistance = OOP.FovDistance
local NumberOfRays = 1
--debug options
local CheckForLastLPSPosition = true --turn on for less lag
local MAX_TRIES = 25

--other variables
local CatchPlayerTries = 0

--pathfind

task.spawn(function()
	while task.wait(0.05) do
		local TargetCharacter = char:GetAttribute("AggroPlayer") and workspace:FindFirstChild(char:GetAttribute("AggroPlayer")) --checks for aggro player
		local LastPositionPlayerWasSeen = NPC.LastPositionPlayerWasSeen --last known pos of player
		local waypos = TargetCharacter and TargetCharacter.Torso.Position or LastPositionPlayerWasSeen -- where to head if player was last seen
		
		--path creation
		local path = PathFindingService:CreatePath({
			WaypointSpacing = 8, --8 --15
			AgentRadius = 1.5,
			AgentHeight = 5.8,
			AgentCanJump = true
		})
		--skip cycle if NPC is dead
		if Hum.Health <= 0 then
			continue
		end
		--clear last pos seen if reached and hasn't found player
		if LastPositionPlayerWasSeen and (LastPositionPlayerWasSeen - Torso.Position).Magnitude <= 1.5 then
			print("Player wasn't found in his last seen position")
			NPC.LastPositionPlayerWasSeen = nil
			LastPositionPlayerWasSeen = nil
			char:SetAttribute("AggroPlayer", nil)
			--clear variables
		end
		-- pathfind towards target
		if char:GetAttribute("AggroPlayer") then
			--roam variable, if it isn't a player it will be Roam
			if char:GetAttribute("AggroPlayer") == "Roam" then
				--ROAM THROUGH MAP WAYPOINTS
				for i,v: Part in ipairs(OOP.OrderTable(OOP.RoamWayPoints:GetChildren())) do
					if char:GetAttribute("AggroPlayer") ~= "Roam" then
						Hum:MoveTo(Torso.Position) -- halt movement
						path = nil
						break
					end
					--make path towards waypoint
					path:ComputeAsync(Torso.Position, v.Position)
					local Waypoints = path:GetWaypoints()

					--if the path is succesful, go through each waypoint
					if path.Status == Enum.PathStatus.Success then
						for n,y:PathWaypoint in Waypoints do --nesting, variable defining
							if not char:GetAttribute("AggroPlayer") then
								--if the aggro player attribute is cleared, stop pathfinding
								print("give up gng :sob::finger_cross:")
								Hum:MoveTo(Torso.Position)
								break
							end

							if char:GetAttribute("AggroPlayer") ~= "Roam" then
								-- if player has been found while roaming, stop pathfinding
								Hum:MoveTo(Torso.Position) -- halt movement
								path = nil
								print("Found Player")
								break
							end
							--if the magnitude to the waypoint from the torso is less or 4, break
							if (Torso.Position - v.Position).Magnitude <= 4 then
								break
							end

							if n ~= 1 then
								--for better pathfinding feeling, skip the first iteration
								local allow = 0

								Hum:MoveTo(y.Position)
								--jump if needed
								if y.Action == Enum.PathWaypointAction.Jump then
									Hum.Jump = true
								end
								--wait until reached waypoint or timeout
								while (Torso.Position - y.Position).magnitude > 1.5 and allow < 25 do
									allow = allow + 1
									game:GetService("RunService").Heartbeat:wait()
								end
								--waypoint representation
								local WaypointPart = Instance.new("Part")
								WaypointPart.Anchored = true
								WaypointPart.CanCollide = false
								WaypointPart.Name = "WayPart"
								WaypointPart.BrickColor = BrickColor.new("Sea green")
								WaypointPart.Material = Enum.Material.Neon
								WaypointPart.Size = Vector3.new(.5,.5,.5)
								WaypointPart.Position = y.Position + Vector3.new(0, 2, 0)
								WaypointPart.Parent = workspace
							end
						end
					end
				end
			else
				--go to last position player was seen/go to player
				if TargetCharacter or char:GetAttribute("AggroPlayer") == "LastPos" then
					--go to last pos
					path:ComputeAsync(Torso.Position, waypos)
					local Waypoints = path:GetWaypoints()
					--if the player is in freefall, skip pathfinding
					if TargetCharacter and TargetCharacter.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
						continue
					end
					--if path is successful, go through each waypoint towards target, confirm target is alive
					if path.Status == Enum.PathStatus.Success and not (TargetCharacter and TargetCharacter.Humanoid.Health <= 0)  then
						for i,v:PathWaypoint in Waypoints do
							if not char:GetAttribute("AggroPlayer") then
								--if aggro player attribute is cleared, stop pathfinding
								print("give up gng :sob::finger_cross:")
								Hum:MoveTo(Torso.Position)
								break
							end
							if i ~= 1 then
								--for better pathfinding feeling, skip the first iteration
								local allow = 0
								--go towards target, else go to last position known
								if TargetCharacter then
									Hum:MoveTo(v.Position, TargetCharacter.Torso)
								else
									Hum:MoveTo(LastPositionPlayerWasSeen)
								end
								--jump if needed
								if v.Action == Enum.PathWaypointAction.Jump then
									print("Jump")
									Hum.Jump = true
								end
								--3.8
								--wait until reached waypoint or timeout)
								while (Torso.Position - v.Position).magnitude > 3.8 and allow <= 20 do
									allow = allow + 1
									game:GetService("RunService").Heartbeat:wait()
								end
								--waypoint representation
								local WaypointPart = Instance.new("Part")
								WaypointPart.Anchored = true
								WaypointPart.CanCollide = false
								WaypointPart.Name = "WayPart"
								WaypointPart.BrickColor = BrickColor.new("Sea green")
								WaypointPart.Material = Enum.Material.Neon
								WaypointPart.Size = Vector3.new(.5,.5,.5)
								WaypointPart.Position = v.Position + Vector3.new(0, 2, 0)
								WaypointPart.Parent = workspace
							end
						end
					end
					--if no path found, print and break
				elseif path.Status == Enum.PathStatus.NoPath then
					print("no path found")
					break
				else
					break
				end
			end
		end
	end
end)

--raycasts

while task.wait(0.05) do
	--create raycasts
	local RayCasts, VisualRayCasts, SuccessRays = NPC:CreateRayCasts(25) -- Raycast, VisualCast
	--if tries exceed the maximun tries
	if CatchPlayerTries >= MAX_TRIES then
		--[[print("Go to breadcumbs (where player was last seen) and afterwards roam")
		create waypoints that'll go to breadcrumbs, and make the pathfind system flexible with attribute
		so it'll pathfind its way onto each waypoint of the breadcrumbs
		dont make it pathfind in ai script dumbass]]
		--^^^^^^^^^^ self comments

		--if it has a last position seen
		if NPC.LastPositionPlayerWasSeen then
			--if visual last player seen debug option
			if NPC.VisualLPS then
				--less lag debug option, makes sure they don't clump together, alteast 0.5 studs away
				if CheckForLastLPSPosition and NPC.LastLPSRegistered and (NPC.LastLPSRegistered - NPC.LastPositionPlayerWasSeen).Magnitude > 0.5 or CheckForLastLPSPosition and not NPC.LastLPSRegistered then
					NPC:CreateVisualLPS()
				elseif not CheckForLastLPSPosition then
					NPC:CreateVisualLPS()
				end
			end
			--goes towards the last position
			char:SetAttribute("AggroPlayer", "LastPos")
		else
			--if the npc doesn't have last position seen and aggro isn't roam, change it to roam 
			if char:GetAttribute("AggroPlayer") ~= "Roam" then
				print("roam through map")
				char:SetAttribute("AggroPlayer", nil)
				NPC.LastPositionPlayerWasSeen = nil
				char:SetAttribute("AggroPlayer", "Roam")
				--start roaming through map
			end
		end

		--reset tries
		CatchPlayerTries = 0
		print("set nil")
	elseif OOP.IsPlayerInTable(SuccessRays) then
		--if player found through raycasts, reset tries and aggro onto player
		CatchPlayerTries = 0
		char:SetAttribute("AggroPLayer", nil) --stop following whoever it was following
	else
		--if no player found nor max tries, increment tries and go to last position seen if it has plr
		CatchPlayerTries+=1
		if NPC.LastPositionPlayerWasSeen then
			print("Player was last seen somewhere")
			if NPC.VisualLPS then
				--less lag debug option, makes sure they don't clump together, alteast 0.5 studs away
				if CheckForLastLPSPosition and NPC.LastLPSRegistered and (NPC.LastLPSRegistered - NPC.LastPositionPlayerWasSeen).Magnitude > 0.5 or CheckForLastLPSPosition and not NPC.LastLPSRegistered then
					NPC:CreateVisualLPS()
				elseif not CheckForLastLPSPosition then
					--debug option off
					NPC:CreateVisualLPS()
				end
			end
			--set aggro to last pos
			char:SetAttribute("AggroPlayer", "LastPos")
		end
		--lil wait to prevent overload
		game:GetService("RunService").Heartbeat:wait()
	end
	--turn each successfull ray red, successfull raycasts are the ones that hit any object
	for i, Raycast: RaycastResult in SuccessRays do
		if Raycast[1] then
			if VisualRayCasts[i] then
				VisualRayCasts[i].BrickColor = BrickColor.new("Really red")
			end
			--get character from raycast hit instance
			local TargetCharacter = OOP.GetCharacter(Raycast[1].Instance)
			--if player was found and has a living humanoid, set aggro onto them and register last position seen
			if TargetCharacter and TargetCharacter:FindFirstChild("Humanoid") and TargetCharacter.Humanoid.Health > 0 then
				char:SetAttribute("AggroPlayer", TargetCharacter.Name)
				NPC.LastPositionPlayerWasSeen = TargetCharacter.Torso.Position
			end
		end
	end
end

---------------------------------------------------------------------------------------------------------
--OOP Module

--!nocheck
local TweenService = game:GetService("TweenService")

--oop settings
local module = {}
module.__index = module

--configurable variables
module.NumberOfRays = 1
module.FovDistance = 60
module.Tilt = -1
module.TOTAL_ANGLE = 90

--roam waypoints
module.RoamWayPoints = workspace.Waypoints

--filters any glass and the NPC itself
module.FilterTable = {script.Parent}
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.FilterDescendantsInstances = module.FilterTable

--constructor
function module.New(model: Model, VisualRayCast, VisualLPS)
	local self = setmetatable({}, module)
	self.Character = model
	self.Head = model.Head
	self.Torso = model.Torso
	self.Humanoid = model.Humanoid
	self.HumanoidRootPart = model.HumanoidRootPart
	self.Hair = model:FindFirstChild("Hair")
	self.VisualRayCast = VisualRayCast
	self.VisualLPS = VisualLPS
	self.LastPositionPlayerWasSeen = nil
	self.LastLPSRegistered = nil
	
	return self
end

--extra functions
function module.OrderTable(Table)
	local orderedtable = {}
	for i,v in pairs(Table) do
		orderedtable[tonumber(v.Name)] = v
	end
	return orderedtable
end

function module.GetCharacter(part)
	if part and part.Parent and part.Parent.Parent then
		local humanoid = part.Parent:FindFirstChild("Humanoid")
		local humparentparent = part.Parent.Parent:FindFirstChild("Humanoid")

		if humanoid then
			return humanoid.Parent
		elseif humparentparent then
			return humparentparent
		end
	end
end

function module.IsPlayerInTable(Table)
	for i,v in pairs(Table) do
		if module.GetCharacter(v.Instance) then
			return true
		end
	end
	return false
end

function module.GetTableLength(Table)
	local totalnumber = 0
	for i,v in Table do
		totalnumber+=1
	end
	return totalnumber
end

--creates a single raycast at a given degree
function module:Create_Cast(deg)
	local RayResult = workspace:Raycast(self.Head.Position, self.Head.CFrame:ToWorldSpace(CFrame.Angles(math.rad(module.Tilt), math.rad(deg), 0)).LookVector * module.FovDistance, RayParams)
	local HitPosition = RayResult and RayResult.Position or self.Head.Position + self.Head.CFrame:ToWorldSpace(CFrame.Angles(math.rad(module.Tilt), math.rad(deg), 0)).LookVector * module.FovDistance
	
	return RayResult, HitPosition
end

--turns the npc head 180 degrees and back (not currently used, planning on implementing it later)
function module:TurnHead()
	local Original_Orientation = self.Head.Orientation

	local HeadTween = TweenService:Create(self.Head, TweenInfo.new(1),{Orientation = Original_Orientation + Vector3.new(0, 180,0)}) -- CFrame = self.Head.CFrame * CFrame.Angles(0, math.rad(180), 0)
	local TurnHeadBackTween = TweenService:Create(self.Head, TweenInfo.new(.8), {Orientation = Original_Orientation})

	local function CreateWeld()
		local HairWeldClone = script.HairWeld:Clone()
		HairWeldClone.Parent = self.Hair.Handle
		HairWeldClone.Part0 = self.Hair.Handle
		HairWeldClone.Part1 = self.Head
	end

	local WeldCoroutine = coroutine.wrap(function()
		while task.wait(0.05) do
			self.Hair.Handle:FindFirstChildWhichIsA("Weld"):Destroy()

			CreateWeld()
		end
	end)

	WeldCoroutine()

	HeadTween:Play()

	local HeadTask = HeadTween.Completed:Connect(function()
		task.wait(0.8)
		TurnHeadBackTween:Play()
		print("turning Head back")
	end)
	TurnHeadBackTween.Completed:Wait()

	if not self.Hair.Handle:FindFirstChildWhichIsA("Weld") then
		CreateWeld()
	end
	
	HeadTask:Disconnect()
end
--DEPRECATED METHOD
function module:CreateRayCast(deg)
	--clear all visual rays
	for i,v in pairs(workspace:GetChildren()) do
		if v.Name:match("HeadRayCast") then
			v:Destroy()
		end
	end
	
	local RayResult, HitPosition = self:Create_Cast(deg)

	return {RayResult, HitPosition}
end

--creates direction vector, middle point and distance for visual raycast representation
function module:CreateVectors(Hitpos)
	local Directionvector = Hitpos - self.Head.Position
	local MiddlePoint = self.Head.Position + Directionvector * 0.5
	local Distance = Directionvector.Magnitude

	return Directionvector, MiddlePoint, Distance
end

--creates the visual raycast using the vectors, the id being the index of the raycast
function module:CreateVisualRayCast(HitPosition, MiddlePoint, Distance, ID)
	local VisualRay = Instance.new("Part")
	table.insert(module.FilterTable, VisualRay)
	RayParams.FilterDescendantsInstances = module.FilterTable
	VisualRay.Anchored = true
	VisualRay.CanCollide = false
	VisualRay.Size = Vector3.new(0.1, 0.1, Distance or module.FovDistance)
	VisualRay.CFrame = CFrame.new(MiddlePoint, HitPosition)
	VisualRay.Material = Enum.Material.Neon
	VisualRay.BrickColor = BrickColor.new("New Yeller")
	VisualRay.Name = "HeadRayCast"..tostring(ID)
	VisualRay.Parent = workspace

	return VisualRay
end

--better function for creating multiple raycasts, automatically divides the total angle by the amount of raycasts to make it easier
function module:CreateRayCasts(amount)
	--clear all previous visual rays
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:match("HeadRayCast") then
			v:Destroy()
		end
	end
	--angle per each cast
	local AnglePerEachCast = module.TOTAL_ANGLE / amount

	--variables
	local RayTable = {}
	local VisualTable = {}
	local SuccessTable = {}
	local Directionvector, MiddlePoint, Distance, VisualCast
	
	--stars from 45 degrees to -45 degrees
	local CurrentAngle = modul.TOTAL_ANGLE / 2
	
	--creates each raycast with designated angle
	for i = 1, amount, 1 do
		local RayResult, HitPosition
		if i == 1 then
			--45 degrees first cast
			RayResult, HitPosition = self:Create_Cast(CurrentAngle)
		else
			--subsequent casts
			RayResult, HitPosition = self:Create_Cast(CurrentAngle - AnglePerEachCast)
		end
		--creates vectors for each cast
		Directionvector, MiddlePoint, Distance = self:CreateVectors(HitPosition)

		--creates visual raycast if enabled
		if self.VisualRayCast then
			VisualCast = self:CreateVisualRayCast(HitPosition, MiddlePoint, Distance, i)
			VisualTable[i] = VisualCast
		end

		--if raycast hit something, add it to success table
		if RayResult then
			SuccessTable[i] = {RayResult}
		end
		--sends the raycast index with its result and hit position
		RayTable[i] = {RayResult, HitPosition}
		CurrentAngle -= AnglePerEachCast
	end
	
	return RayTable, VisualTable, SuccessTable
end

--creates visual last position seen
function module:CreateVisualLPS()
	local LastPartSeen = Instance.new("Part")
	table.insert(module.FilterTable, LastPartSeen)
	LastPartSeen.CanCollide = false
	LastPartSeen.Anchored = true
	LastPartSeen.Name = "LPS"
	LastPartSeen.Size = Vector3.new(3,3,3)
	LastPartSeen.BrickColor = BrickColor.new("Really red")
	LastPartSeen.Transparency = 0.6
	LastPartSeen.Position = self.LastPositionPlayerWasSeen
	LastPartSeen.Parent = workspace
	self.LastLPSRegistered = self.LastPositionPlayerWasSeen
end

return module