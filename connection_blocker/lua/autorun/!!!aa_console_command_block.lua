/*
	Server connect block for singleplayer made by Hackcraft STEAM_0:1:50714411
*/

if !game.SinglePlayer then return end
print("Loaded singleplayer connect to server block!")

// Locals 
local meta = FindMetaTable("Player")
local CurTime = CurTime
local IsValid = IsValid
local ipairs = ipairs
local pairs = pairs
local table = table.Copy(table)
local file = table.Copy(file)
local string = table.Copy(string)
local net = table.Copy(net)
local util = table.Copy(util)
local debug = table.Copy(debug)
local engine = table.Copy(engine)
local RunStringLog = {}
local ComplileStringLog = {}
local ComplileFileLog = {}
local SendLuaLog = {}
local badSauce = {
	["RunString"] = true,
	["LuaCmd"] = true,
	["lua_run"] = true
}

if SERVER then
	util.AddNetworkString("ConnectCommandBlock_Search")
end

/*
	Chat message
*/
local function ChatMessages(tab)
	if CLIENT then
		local ply = LocalPlayer()
		for k, text in ipairs(tab) do
			chat.AddText(Color(153,0,0), "[WARNING] ", Color(240,240,240), text)
		end
	else
		local ply = player.GetHumans()[1]
		if !IsValid(ply) then return end
		for k, text in ipairs(tab) do
			ply:ChatPrint("[WARNING] " .. text)
		end
	end
end

/*
	Get addon from file
*/
local function AddonFromFile(path)
	for k, v in ipairs(engine.GetAddons()) do
		if isstring(v.title) then
			local files, folders = file.Find(path, v.title)
			if files[1] then
--				print(v.title)
				return v.title, "http://steamcommunity.com/sharedfiles/filedetails/?id=" .. v.wsid
			end
		end
	end

	return false
end

/*
	Get addon from ip
*/
local function TableHasIP(ip, tab)
	for k, v in ipairs(tab) do
--			print(v.code)
		if string.find(v.code, ip) then
--				print(v.path)
			return v.path
		end
	end
	return false
end

local function AddonFromIP(ip)
	local hasIP

	// RunStringLog
	hasIP = TableHasIP(ip, RunStringLog)
	if hasIP then return hasIP end

	// ComplileStringLog
	hasIP = TableHasIP(ip, ComplileStringLog)
	if hasIP then return hasIP end

	// ComplileFileLog
	hasIP = TableHasIP(ip, ComplileFileLog)
	if hasIP then return hasIP end

	// SendLuaLog
	hasIP = TableHasIP(ip, SendLuaLog)
	if hasIP then return hasIP end

	return false
end
 
/*
	Handle bad!
*/
local attempts = {}
local function HandleConnectionAttempt(ip, info)

	if attempts[fullip .. info.short_src] != nil then return end
	attempts[fullip .. info.short_src] = true

	local fullip = ip

	if string.find(ip, ";") then
		local start, _, _ = string.find(ip, ";")
		ip = string.Left(ip, start - 1)
	end
	ip = string.Trim(ip)

--	print(ip)
	
	local path = info.short_src
	local isAddon, link = AddonFromFile(path)

	if isAddon then
		ChatMessages({
			"An addon tried to connect you to: " .. fullip,
			"The suspected addon is: " .. isAddon,
			"The Workshop link is: " .. link,
			"Please note that this is not 100% accurate!"
		})
		return
	end

	// 2nd check!
	local where = AddonFromIP(ip)

	if where then
		local isAddon, link = AddonFromFile(where)
		if isAddon then
			ChatMessages({
				"An addon tried to connect you to: " .. fullip,
				"The suspected addon is: " .. isAddon,
				"The suspected file is: " .. where,
				"The Workshop link is: " .. link,
				"Please note that this is not 100% accurate!"
			})
			return
		else
			ChatMessages({
				"An addon tried to connect you to: " .. fullip,
				"The suspected file is: " .. where,
				"Please note that this is not 100% accurate!"
			})
			return
		end
	end

	// We didn't find a location, time to see if our other side knows!

		net.Start("ConnectCommandBlock_Search")
			net.WriteString(ip)
			net.WriteString(fullip)
			net.WriteString(path)
	if CLIENT then
		net.SendToServer()
	else
		net.Send(player.GetHumans()[1])
	end

end

/*
	ConCommand
*/
local SendConCommand = SendConCommand or meta.ConCommand

function meta:ConCommand(command, bSkipQueue)
	if string.Left(command, 7) == "connect" then print("blocked: " .. command) command = command .. " " HandleConnectionAttempt(string.TrimLeft(command, "connect "), debug.getinfo(2)) return end
	SendConCommand(self, command)
end

/*
	RunConsoleCommand
*/
local RCC = RCC or RunConsoleCommand

function RunConsoleCommand(command, args, argStr)
	if string.Left(command, 7) == "connect" then args = args or "nil" print("blocked: " .. command .. " " .. args) HandleConnectionAttempt(args, debug.getinfo(2)) return end
	return RCC(command, args, argStr)
end


--[[ Loggers ]]--

/*
	RunString
*/
local RunStringDetour = RunStringDetour or RunString

function RunString(str)
	table.insert(RunStringLog, {["code"] = str, ["path"] = debug.getinfo(2).short_src})
	return RunStringDetour(str)
end

/*
	CompileString
*/
local CompileStringDetour = CompileStringDetour or CompileString

function CompileString(code, identifier, HandleError)
	table.insert(ComplileStringLog, {["code"] = code, ["path"] = debug.getinfo(2).short_src})
	return CompileStringDetour(code, identifier, HandleError)
end

/*
	CompileFile
*/
local CompileFileDetour = CompileFileDetour or CompileFile

function CompileFile(path)
	table.insert(ComplileFileLog, {["code"] = file.Read(path, "LUA"), ["path"] = debug.getinfo(2).short_src})
	return CompileFileDetour(path)
end

/*
	SendLua
*/
local SendLuaCommand = SendLuaCommand or meta.SendLua

function meta:SendLua(str)
	table.insert(SendLuaLog, {["code"] = str, ["path"] = debug.getinfo(2).short_src})
	return SendLuaCommand(self, str)
end

/*
	Net messages
*/
net.Receive("ConnectCommandBlock_Search", function(len, ply)

	local ip = net.ReadString()
	local fullip = net.ReadString()
	local path = net.ReadString()

	if attempts[ip .. path] != nil then return end
	attempts[ip .. path] = true

	local where = AddonFromIP(ip)
 
	// Look on vise versa
	if where then
		local isAddon, link = AddonFromFile(where)
		if isAddon then
			ChatMessages({
				"An addon tried to connect you to: " .. fullip,
				"The suspected addon is: " .. isAddon,
				"The suspected file is: " .. where,
				"The Workshop link is: " .. link,
				"Please note that this is not 100% accurate!"
			})
			return
		else
			ChatMessages({
				"An addon tried to connect you to: " .. fullip,
				"The suspected file is: " .. where,
				"Please note that this is not 100% accurate!"
			})
			return
		end
	end

	if badSauce[path] != nil then
		ChatMessages({
			"An addon tried to connect you to: " .. fullip,
			"The code was executed from: " .. path,
			"We were unable to find the origin :("
		})
		return
	else
		ChatMessages({
			"A Lua file tried to connect you to: " .. fullip,
			"The suspected file is: " .. path,
			"Please note that this is not 100% accurate!"
		})
		return
	end

end)
 
