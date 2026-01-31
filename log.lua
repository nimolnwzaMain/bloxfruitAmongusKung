local Config = getgenv().HorstConfig
local player = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local CommF = RS.Remotes["CommF_"]
local HttpService = game:GetService("HttpService")
local Data = player:WaitForChild("Data")
local race = Data:WaitForChild("Race")
local raceTier = race:WaitForChild("C")

local function FormatNumber(num)
	if num >= 1e9 then
		return (math.floor(num / 1e8) / 10) .. "B"
	elseif num >= 1e6 then
		return (math.floor(num / 1e5) / 10) .. "M"
	elseif num >= 1e3 then
		return (math.floor(num / 1e2) / 10) .. "K"
	else
		return tostring(num)
	end
end

local function HasTool(name)
	if player.Backpack:FindFirstChild(name) then
		return true
	end
	if player.Character and player.Character:FindFirstChild(name) then
		return true
	end
	return false
end

local function CallComm(...)
	local remote = RS.Remotes:FindFirstChild("CommF_")
	if not remote then return end
	if remote:IsA("RemoteFunction") then
		return remote:InvokeServer(...)
	end
end

local MeleeStep = {
	["Superhuman"] = 1,
	["Death Step"] = 2,
	["Sharkman Karate"] = 3,
	["Electric Claw"] = 4,
	["Dragon Talon"] = 5,
	["Godhuman"] = 6,
	["Sanguine Art"] = 7
}

local function GetMelee()
	local maxStep = 0
	for name, step in pairs(MeleeStep) do
		if HasTool(name) then
			if step > maxStep then
				maxStep = step
			end
		end
	end
	return maxStep
end

local function GetItems()
	local Inventory = CommF:InvokeServer("getInventory")

	local items = {
		CDK = false,
		MIR = false,
		VAL = false,
	}

	for i, v in pairs(Inventory) do
		if type(v) == "table" then
			local name = v.Name or v.ItemName
			if name then
				if name == "Cursed Dual Katana" then
					items.CDK = true
				elseif name == "Mirror Fractal" then
					items.MIR = true
				elseif name == "Valkyrie Helm" then
					items.VAL = true
				end
			end
		end
	end

	return items, Inventory
end

local function GetPlayerData()
	return {
		Level = Data.Level.Value,
		Beli = Data.Beli.Value,
		BeliFormatted = FormatNumber(Data.Beli.Value),
		Fragments = Data.Fragments.Value,
		FragmentsFormatted = FormatNumber(Data.Fragments.Value),
		Fruit = Data.DevilFruit.Value
	}
end

local function GetEvo()
	if HasTool("Awakening") then
		return 4
	elseif CallComm("Wenlocktoad", "1") == -2 then
		return 3
	elseif CallComm("Alchemist", "1") == -2 then
		return 2
	else
		return 1
	end
end

local function GetRace()
	return {
		Name = race.Value,
		Evo = GetEvo(),
		Tier = raceTier.Value
	}
end

local function CheckInventory(rawInventory)
	local inv = Config.AutoFunctions.BF.MAIN.Inventory
	if not inv.Enable then
		return true
	end

	local have = {}
	for _, v in pairs(rawInventory) do
		if type(v) == "table" then
			local name = v.Name or v.ItemName
			if name then
				have[name] = true
			end
		end
	end

	for _, itemName in ipairs(inv.Name) do
		if not have[itemName] then
			print("[Horst]", "Inventory ไม่มี —", itemName)
			return false
		end
	end

	return true
end

local function CheckMainCondition(pdata, items, rawInventory)
	local main = Config.AutoFunctions.BF.MAIN

	if main.Level > 0 and pdata.Level < main.Level then
		print("[Horst]","MAIN fail: Level", pdata.Level, "/", main.Level)
		return false
	end

	if main.Beli > 0 and pdata.Beli < main.Beli then
		print("[Horst]","MAIN fail: Beli", pdata.Beli, "/", main.Beli)
		return false
	end

	if main.Fragments > 0 and pdata.Fragments < main.Fragments then
		print("[Horst]","MAIN fail: Fragments", pdata.Fragments, "/", main.Fragments)
		return false
	end

	if main.Lock_Race.Enable then
		local rName = race.Value
		local rEvo = GetEvo()
		local evoMap = { ["V1"] = 1, ["V2"] = 2, ["V3"] = 3, ["V4"] = 4 }
		local requiredEvo = evoMap[main.Lock_Race.Ability] or 1

		if rName ~= main.Lock_Race.Race then
			print("[Horst]","MAIN fail: Race", rName, "/ ต้อง", main.Lock_Race.Race)
			return false
		end
		if rEvo < requiredEvo then
			print("[Horst]","MAIN fail: Evo", rEvo, "/ ต้อง", requiredEvo)
			return false
		end
	end

	if not CheckInventory(rawInventory) then
		print("[Horst]","MAIN fail: Inventory ไม่ครบ")
		return false
	end

	return true
end

local function CheckGodCondition(items)
	local bf = Config.AutoFunctions.BF
	local melee = GetMelee()
	local hasGodhuman = melee >= 6
	local hasSanguine = melee >= 7

	if bf.GOD_CDK_MIR_VAL then
		if hasGodhuman and items.CDK and items.MIR and items.VAL then
			print("[Horst]","GOD ผ่าน: GOD_CDK_MIR_VAL")
			return true
		end
	end
	if bf.GOD_MIR_VAL then
		if hasGodhuman and items.MIR and items.VAL then
			print("[Horst]","GOD ผ่าน: GOD_MIR_VAL")
			return true
		end
	end
	if bf.GOD_CDK then
		if hasGodhuman and items.CDK then
			print("[Horst]","GOD ผ่าน: GOD_CDK")
			return true
		end
	end
	if bf.GOD_SA then
		if hasGodhuman and hasSanguine then
			print("[Horst]","GOD ผ่าน: GOD_SA")
			return true
		end
	end
	if bf.GOD then
		if hasGodhuman then
			print("[Horst]","GOD ผ่าน: GOD")
			return true
		end
	end

	local hasAnyGodFlag = bf.GOD or bf.GOD_CDK or bf.GOD_SA or bf.GOD_MIR_VAL or bf.GOD_CDK_MIR_VAL
	if not hasAnyGodFlag then
		return true
	end

	print("[Horst]","GOD ไม่ผ่าน: Melee =", melee, "CDK =", items.CDK, "MIR =", items.MIR, "VAL =", items.VAL)
	return false
end

local doneSent = false

local function TryDone(pdata, items, rawInventory)
	if doneSent then return end

	local bf = Config.AutoFunctions.BF

	if not CheckMainCondition(pdata, items, rawInventory) then return end
	if not CheckGodCondition(items) then return end

	local ok, err = _G.Horst_AccountChangeDone()
	if ok then
		doneSent = true
		print("[Horst]","✅ AccountChangeDone ส่งสำเร็จ")
	else
		print("[Horst]","❌ AccountChangeDone Error:", err)
	end
end

local function BuildAndSend()
	if not Config.AutoFunctions.Enable then return end

	local melee = GetMelee()
	local items, rawInventory = GetItems()
	local pdata = GetPlayerData()
	local raceData = GetRace()

	local parts = {}

	table.insert(parts, "Melee[" .. melee .. "/7]")

	table.insert(parts, "B:" .. pdata.BeliFormatted)
	table.insert(parts, "F:" .. pdata.FragmentsFormatted)

	if raceData.Evo == 4 then
		table.insert(parts, raceData.Name .. " V4 T" .. raceData.Tier)
	else
		table.insert(parts, raceData.Name .. " V" .. raceData.Evo)
	end

	local function check(val)
		return val and "✅" or "❌"
	end
	table.insert(parts, "CDK[" .. check(items.CDK) .. "]")
	table.insert(parts, "MIR[" .. check(items.MIR) .. "]")
	table.insert(parts, "VAL[" .. check(items.VAL) .. "]")

	table.insert(parts, "Lv." .. pdata.Level)

	if pdata.Fruit ~= "" and pdata.Fruit ~= "None" then
		table.insert(parts, pdata.Fruit)
	else
		table.insert(parts, "No Fruit")
	end

	local description = table.concat(parts, ", ")

	local encodeJson = HttpService:JSONEncode({
		Level = pdata.Level,
		Beli = pdata.Beli,
		Fragments = pdata.Fragments,
		Fruit = pdata.Fruit,
		Race = raceData.Name,
		Evo = raceData.Evo,
		Melee = melee,
		CDK = items.CDK,
		MIR = items.MIR,
		VAL = items.VAL,
	})

	local ok, err = _G.Horst_SetDescription(description, encodeJson)
	if not ok then
		print("[Horst]","❌ SetDescription Error:", err)
	else
		print("[Horst]","✅ Updated:", description)
	end

	TryDone(pdata, items, rawInventory)
end

BuildAndSend()

Data.Level.Changed:Connect(BuildAndSend)
Data.Beli.Changed:Connect(BuildAndSend)
Data.Fragments.Changed:Connect(BuildAndSend)
Data.DevilFruit.Changed:Connect(BuildAndSend)
race.Changed:Connect(BuildAndSend)
raceTier.Changed:Connect(BuildAndSend)

task.spawn(function()
	while not doneSent do
		task.wait(1)
		local items, rawInventory = GetItems()
		local pdata = GetPlayerData()
		TryDone(pdata, items, rawInventory)
	end
end)
