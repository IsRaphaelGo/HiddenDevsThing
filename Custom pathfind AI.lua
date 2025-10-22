--!nocheck
local PathFindingService = game:GetService("PathfindingService")
local OOP = require(script.OOP)
local WaypointClearConfig = require(workspace.Actor.WayPointClear.Config)

--settings
local VisualRayEnabled = false
local VisualLPSEnabled = true

local NPC = OOP.New(script.Parent, VisualRayEnabled, VisualLPSEnabled)

local char = NPC.Character
local head = NPC.Head
local Torso = NPC.Torso
local Hum = NPC.Humanoid

local FovDistance = OOP.FovDistance
local NumberOfRays = 1
--debug options
local CheckForLastLPSPosition = true --turn on for less lag

local MAX_TRIES = 25
local CatchPlayerTries = 0

--pathfind

task.spawn(function()
	while task.wait(0.05) do
		local TargetCharacter = char:GetAttribute("AggroPlayer") and workspace:FindFirstChild(char:GetAttribute("AggroPlayer"))
		local LastPositionPlayerWasSeen = NPC.LastPositionPlayerWasSeen
		local waypos = TargetCharacter and TargetCharacter.Torso.Position or LastPositionPlayerWasSeen
		local path = PathFindingService:CreatePath({
			WaypointSpacing = 8, --8 --15
			AgentRadius = 1.5,
			AgentHeight = 5.8,
			AgentCanJump = true
		})

		if Hum.Health <= 0 then
			continue
		end

		if LastPositionPlayerWasSeen and (LastPositionPlayerWasSeen - Torso.Position).Magnitude <= 1.5 then
			print("Player wasn't found in his last seen position")
			NPC.LastPositionPlayerWasSeen = nil
			LastPositionPlayerWasSeen = nil
			char:SetAttribute("AggroPlayer", nil)
		end

		if char:GetAttribute("AggroPlayer") then
			if char:GetAttribute("AggroPlayer") == "Roam" then
				--ROAM THROUGH MAP
				for i,v: Part in ipairs(OOP.OrderTable(OOP.RoamWayPoints:GetChildren())) do
					if char:GetAttribute("AggroPlayer") ~= "Roam" then
						Hum:MoveTo(Torso.Position) -- halt movement
						path = nil
						break
					end
					path:ComputeAsync(Torso.Position, v.Position)
					local Waypoints = path:GetWaypoints()


					if path.Status == Enum.PathStatus.Success then
						for n,y:PathWaypoint in Waypoints do
							if not char:GetAttribute("AggroPlayer") then
								print("give up gng :sob::finger_cross:")
								Hum:MoveTo(Torso.Position)
								break
							end

							if char:GetAttribute("AggroPlayer") ~= "Roam" then
								Hum:MoveTo(Torso.Position) -- halt movement
								path = nil
								print("Found Player")
								break
							end

							if (Torso.Position - v.Position).Magnitude <= 4 then
								break
							end

							if n ~= 1 then
								local allow = 0

								Hum:MoveTo(y.Position)

								if y.Action == Enum.PathWaypointAction.Jump then
									Hum.Jump = true
								end

								while (Torso.Position - y.Position).magnitude > 1.5 and allow < 25 do
									allow = allow + 1
									game:GetService("RunService").Heartbeat:wait()
								end

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
				if TargetCharacter or char:GetAttribute("AggroPlayer") == "LastPos" then
					--go to last pos
					path:ComputeAsync(Torso.Position, waypos)
					local Waypoints = path:GetWaypoints()

					if TargetCharacter and TargetCharacter.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
						continue
					end

					if path.Status == Enum.PathStatus.Success and not (TargetCharacter and TargetCharacter.Humanoid.Health <= 0)  then
						for i,v:PathWaypoint in Waypoints do
							if not char:GetAttribute("AggroPlayer") then
								print("give up gng :sob::finger_cross:")
								Hum:MoveTo(Torso.Position)
								break
							end
							if i ~= 1 then

								local allow = 0
								if TargetCharacter then
									Hum:MoveTo(v.Position, TargetCharacter.Torso)
								else
									Hum:MoveTo(LastPositionPlayerWasSeen)
								end


								if v.Action == Enum.PathWaypointAction.Jump then
									print("Jump")
									Hum.Jump = true
								end
								--3.8
								while (Torso.Position - v.Position).magnitude > 3.8 and allow <= 20 do
									allow = allow + 1
									game:GetService("RunService").Heartbeat:wait()
								end

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

--raycast

while task.wait(0.05) do
	local RayCasts, VisualRayCasts, SuccessRays = NPC:CreateRayCasts(25) -- Raycast, VisualCast

	if CatchPlayerTries >= MAX_TRIES then
		--print("Go to breadcumbs (where player was last seen) and afterwards roam")
		--create waypoints that'll go to breadcrumbs, and make the pathfind system flexible with attribute
		--so it'll pathfind its way onto each waypoint of the breadcrumbs
		--dont make it pathfind in ai script dumbass

		if NPC.LastPositionPlayerWasSeen then
			if NPC.VisualLPS then
				if CheckForLastLPSPosition and NPC.LastLPSRegistered and (NPC.LastLPSRegistered - NPC.LastPositionPlayerWasSeen).Magnitude > 0.5 or CheckForLastLPSPosition and not NPC.LastLPSRegistered then
					NPC:CreateVisualLPS()
				elseif not CheckForLastLPSPosition then
					NPC:CreateVisualLPS()
				end
			end

			char:SetAttribute("AggroPlayer", "LastPos")		
		else
			if char:GetAttribute("AggroPlayer") ~= "Roam" then
				print("roam through map")
				char:SetAttribute("AggroPlayer", nil)
				NPC.LastPositionPlayerWasSeen = nil
				char:SetAttribute("AggroPlayer", "Roam")
				--start roaming through map
			end
		end

		CatchPlayerTries = 0
		print("set nil")
	elseif OOP.IsPlayerInTable(SuccessRays) then
		CatchPlayerTries = 0
		char:SetAttribute("AggroPLayer", nil) --stop following whoever it was following
	else
		CatchPlayerTries+=1
		if NPC.LastPositionPlayerWasSeen then
			print("Player was last seen somewhere")
			if NPC.VisualLPS then
				if CheckForLastLPSPosition and NPC.LastLPSRegistered and (NPC.LastLPSRegistered - NPC.LastPositionPlayerWasSeen).Magnitude > 0.5 or CheckForLastLPSPosition and not NPC.LastLPSRegistered then
					NPC:CreateVisualLPS()
				elseif not CheckForLastLPSPosition then
					NPC:CreateVisualLPS()
				end
			end

			char:SetAttribute("AggroPlayer", "LastPos")
		end
		game:GetService("RunService").Heartbeat:wait()
	end

	for i, Raycast: RaycastResult in SuccessRays do
		if Raycast[1] then
			if VisualRayCasts[i] then
				VisualRayCasts[i].BrickColor = BrickColor.new("Really red")
			end

			local TargetCharacter = OOP.GetCharacter(Raycast[1].Instance)
			
			if TargetCharacter and TargetCharacter:FindFirstChild("Humanoid") and TargetCharacter.Humanoid.Health > 0 then
				char:SetAttribute("AggroPlayer", TargetCharacter.Name)
				NPC.LastPositionPlayerWasSeen = TargetCharacter.Torso.Position
			end
		end
	end
end

--module

--!nocheck
local TweenService = game:GetService("TweenService")

local module = {}
module.__index = module

module.NumberOfRays = 1
module.FovDistance = 60
module.Tilt = -1
module.TOTAL_ANGLE = 90

module.RoamWayPoints = workspace.Waypoints

module.FilterTable = {script.Parent}
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.FilterDescendantsInstances = module.FilterTable

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

function module:Create_Cast(deg)
	local RayResult = workspace:Raycast(self.Head.Position, self.Head.CFrame:ToWorldSpace(CFrame.Angles(math.rad(module.Tilt), math.rad(deg), 0)).LookVector * module.FovDistance, RayParams)
	local HitPosition = RayResult and RayResult.Position or self.Head.Position + self.Head.CFrame:ToWorldSpace(CFrame.Angles(math.rad(module.Tilt), math.rad(deg), 0)).LookVector * module.FovDistance
	
	return RayResult, HitPosition
end

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

function module:CreateVectors(Hitpos)
	local Directionvector = Hitpos - self.Head.Position
	local MiddlePoint = self.Head.Position + Directionvector * 0.5
	local Distance = Directionvector.Magnitude

	return Directionvector, MiddlePoint, Distance
end

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

function module:CreateRayCasts(amount)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:match("HeadRayCast") then
			v:Destroy()
		end
	end
	
	local AnglePerEachCast = module.TOTAL_ANGLE / amount
	
	local RayTable = {}
	local VisualTable = {}
	local SuccessTable = {}
	local Directionvector, MiddlePoint, Distance, VisualCast
	
	local CurrentAngle = 45
	
	for i = 1, amount, 1 do
		local RayResult, HitPosition
		if i == 1 then
			RayResult, HitPosition = self:Create_Cast(CurrentAngle)
		else
			RayResult, HitPosition = self:Create_Cast(CurrentAngle - AnglePerEachCast)
		end
		
		Directionvector, MiddlePoint, Distance = self:CreateVectors(HitPosition)
		
		if self.VisualRayCast then
			VisualCast = self:CreateVisualRayCast(HitPosition, MiddlePoint, Distance, i)
			VisualTable[i] = VisualCast
		end
		
		if RayResult then
			SuccessTable[i] = {RayResult}
		end
		
		RayTable[i] = {RayResult, HitPosition}
		CurrentAngle -= AnglePerEachCast
	end
	
	return RayTable, VisualTable, SuccessTable
end

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