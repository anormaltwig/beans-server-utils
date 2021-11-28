-- base/player.lua by Bonyoze

local meta = FindMetaTable("Player")

function BSU:GetPlayerPlayTime(ply)
	return ply:GetNWInt("playTime")
end

function BSU:GetPlayerKills(ply)
	return ply:GetNWInt("kills")
end

function BSU:GetPlayerStatus(ply)
	return ply:IsBot() and "offline" or ply:GetNWBool("isAFK") == true and "away" or ply:GetNWBool("isFocused") == false and "busy" or "online"
end

function BSU:GetPlayerCountry(ply)
	return not ply:IsBot() and ply:GetNWString("country", "")
end

function BSU:GetPlayerOS(ply)
	return not ply:IsBot() and ply:GetNWString("os", "")
end

function BSU:GetPlayerMode(ply)
	return ply:HasGodMode() and "build" or "pvp"
end

function BSU:GetPlayerAFKDuration(ply)
	return ply:GetNWFloat("afkTime") ~= 0 and CurTime() - ply:GetNWFloat("afkTime") + BSU.AFK_TIMEOUT or 0
end

function BSU:GetPlayerValues(ply)
	local values = {}

	if not ply:IsBot() then
    -- append if linux user and if not bot
    local os = BSU:GetPlayerOS(ply)
    if os ~= "" then
      table.insert(values, {
				type = "os",
        image = os == "windows" and "materials/bsu/scoreboard/windows.png" or os == "linux" and "icon16/tux.png" or os == "mac" and "materials/bsu/scoreboard/mac.png",
				size = {x = 16, y = 16},
				offset = {x = 0, y = 0}
      })
    end

    -- append country flag icon if not bot
    local country = BSU:GetPlayerCountry(ply)
    if country ~= "" then
      table.insert(values, {
				type = "country",
        image = "flags16/" .. country .. ".png",
				size = {x = 16, y = 11},
				offset = {x = 0, y = 3}
      })
    end
  end

  -- append status icon
  local status = BSU:GetPlayerStatus(ply)
  table.insert(values, {
		type = "status",
    image = "icon16/status_" .. status .. ".png",
		size = {x = 16, y = 16},
		offset = {x = 0, y = 0}
  })

  -- append mode (build or pvp)
  local mode = BSU:GetPlayerMode(ply) == "build" and "wrench_orange" or "gun"
  table.insert(values, {
		type = "mode",
    image = "icon16/" .. mode .. ".png",
		size = {x = 16, y = 16},
		offset = {x = 0, y = 0}
  })

	return values
end

function BSU:ReceiveClientData(ply, data)
	ply.bsu = ply.bsu or {}
	for k, v in pairs(data) do
		ply.bsu[k] = v
	end
end

if SERVER then
	util.AddNetworkString("BSU_ClientInit")
	util.AddNetworkString("BSU_ClientFocusedStatus")

	function BSU:RegisterPlayerDBData(ply)
		sql.Query(string.format("INSERT INTO bsu_players(steamId) VALUES('%s')", ply:SteamID64()))
	end

	function BSU:GetPlayerDBData(ply)
		if not ply or not ply:IsValid() then ErrorNoHalt("Tried to get player data of null entity") return end

		local entry = sql.QueryRow(string.format("SELECT * FROM bsu_players WHERE steamId = '%s'", ply:SteamID64()))

		if entry then
			return {
				rankIndex = tonumber(entry.rankIndex),
				playTime = tonumber(entry.playTime),
				uniqueColor = entry.uniqueColor ~= "NULL" and entry.uniqueColor or nil,
				permsOverride = tonumber(entry.permsOverride) == 1
			}
		end
	end

	function BSU:SetPlayerDBData(ply, data)
		if not ply:IsValid() then ErrorNoHalt("Tried to set player data to null entity") return end

		if not BSU:GetPlayerDBData(ply) then -- insert a new row
			BSU:RegisterPlayerDBData(ply)
		end

		-- update with the data
		for k, v in pairs(data) do
			sql.Query(string.format("UPDATE bsu_players SET %s = '%s' WHERE steamId = '%s'", k, tostring(v), ply:SteamID64()))
		end
	end

	function BSU:SetPlayerRank(ply, index)
		local plyData = BSU:GetPlayerDBData(ply)
		local rankData = BSU:GetRank(index)

		if not plyData or plyData.rankIndex ~= index then
			BSU:SetPlayerDBData(ply, {
				rankIndex = index
			})
		end

		ply:SetTeam(index) -- set team
		ply:SetUserGroup(rankData.userGroup) -- set user group
		ply:SetNWString("color", BSU:ColorToHex(rankData.color)) -- update player color value
	end
	
	function BSU:PlayerIsStaff(ply) -- player is a staff member (admin or superadmin usergroup)
		local plyData = BSU:GetPlayerDBData(ply)

		if plyData then
			if plyData.permsOverride then return true end
			local rankData = BSU:GetRank(plyData.rankIndex)
			return rankData and (rankData.userGroup == "admin" or rankData.userGroup == "superadmin") or false
		end

		return false
	end

	function BSU:PlayerIsSuperAdmin(ply) -- player is a super admin (superadmin usergroup)
		local plyData = BSU:GetPlayerDBData(ply)

		if plyData then
			if plyData.permsOverride then return true end
			local rankData = BSU:GetRank(plyData.rankIndex)
			return rankData and rankData.userGroup == "superadmin" or false
		end

		return false
	end

	function BSU:PlayerIsOverride(ply) -- player overrides all perms
		local plyData = BSU:GetPlayerDBData(ply)

		if plyData then
			return plyData.permsOverride
		end

		return false
	end

	function BSU:GetStaff()
		local players = {}
		for _, ply in ipairs(player.GetAll()) do
			if BSU:PlayerIsStaff(ply) then
				table.insert(players, ply)
			end
		end
		return players
	end

	function BSU:GetSuperAdmins()
		local players = {}
		for _, ply in ipairs(player.GetAll()) do
			if BSU:PlayerIsSuperAdmin(ply) then
				table.insert(players, ply)
			end
		end
		return players
	end

	function BSU:GetOverrides()
		local players = {}
		for _, ply in ipairs(player.GetAll()) do
			if BSU:PlayerIsOverride(ply) then
				table.insert(players, ply)
			end
		end
		return players
	end

	function BSU:GetPlayerColor(ply)
		if ply == nil or not ply:IsValid() or not ply:IsPlayer() then return Color(151, 211, 255) end
		
		local plyData = BSU:GetPlayerDBData(ply)

		local uniqueColor = ply:GetNWString("uniqueColor", "")

		if uniqueColor ~= "" then
			uniqueColor = BSU:HexToColor(uniqueColor)
		elseif plyData and plyData.uniqueColor then
			uniqueColor = BSU:HexToColor(plyData.uniqueColor)
		else
			uniqueColor = nil
		end

		local color = ply:GetNWString("color", "")

		if color ~= "" then
			color = BSU:HexToColor(color)
		elseif plyData then
			color = BSU:GetRank(plyData.rankIndex).color
		else
			color = nil
		end

		return uniqueColor or color or team.GetColor(ply:IsBot() and BSU.BOT_RANK or BSU.DEFAULT_RANK)
	end

	function BSU:SetPlayerUniqueColor(ply, color)
		local hex = BSU:ColorToHex(color)
		BSU:SetPlayerDBData(ply, {
			uniqueColor = hex
		})
		ply:SetNWString("uniqueColor", hex)
	end

	function BSU:ClearPlayerUniqueColor(ply)
		sql.Query(string.format("UPDATE bsu_players SET uniqueColor = NULL WHERE steamId = '%s'", ply:SteamID64()))
    ply:SetNWString("uniqueColor", "")
	end

	net.Receive("BSU_ClientInit", function(_, ply)
		local country, os = net.ReadString(), net.ReadString()

		ply:SetNWString("country", country)
		ply:SetNWString("os", os)
	end)

	net.Receive("BSU_ClientFocusedStatus", function(_, ply)
		ply:SetNWBool("isFocused", net.ReadBool())
	end)
	
	hook.Add("PlayerSpawn", "BSU_SetPlayerTeam", function(ply)
		if ply:Team() == 1001 then -- if unassigned then setup rank/team
			local data = BSU:GetPlayerDBData(ply)

			if not data then
				BSU:SetPlayerRank(ply, ply:IsBot() and BSU.BOT_RANK or BSU.DEFAULT_RANK)
				data = BSU:GetPlayerDBData(ply) -- new data
			else
				local rank = BSU:GetRank(data.rankIndex)

				ply:SetTeam(data.rankIndex) -- set team
				ply:SetUserGroup(rank.userGroup) -- set user group
				ply:SetNWString("color", BSU:ColorToHex(rank.color)) -- update player color value
			end

			if data.uniqueColor then -- set player unique color value
				ply:SetNWString("uniqueColor", data.uniqueColor)
			end

			-- set players to god mode on join
			if not ply:IsBot() then
				ply:GodEnable()
				ply:SetNWBool("inGodmode", true)
			end
		end
	end)

	timer.Create("BSU_PlayerPlayTimeCounter", 1, 0, function()
		for _, ply in ipairs(player.GetAll()) do
			if not ply:IsBot() and (ply.bsu and ply.bsu.isAFK) then return end

			local plyData = BSU:GetPlayerDBData(ply)
			if plyData then
				local newVal = plyData.playTime + 1
				BSU:SetPlayerDBData(ply, { playTime = newVal })
				ply:SetNWInt("playTime", newVal)
			end
		end
	end)

	-- track kills for players
	hook.Add("PlayerDeath", "BSU_PlayerKills", function(victim, inflict, attacker)
		if victim ~= attacker then attacker:SetNWInt("kills", attacker:GetNWInt("kills") + 1) end
	end)

	-- handle afk players
	hook.Add("Think", "BSU_HandleAFK", function()
		for _, ply in ipairs(player.GetAll()) do
			if ply:GetNWFloat("afkTime") == 0 then ply:SetNWFloat("afkTime", CurTime()) end

			if ply:GetNWFloat("afkTime") + BSU.AFK_TIMEOUT <= CurTime() then -- player hit the afk timeout
				if not ply:GetNWBool("isAFK") then
					ply:SetNWBool("isAFK", true)
					BSU:SendPlayerInfoMsg(ply, " is now afk")
				end
			elseif ply:GetNWBool("isAFK") then
				ply:SetNWBool("isAFK", false)
				BSU:SendPlayerInfoMsg(ply, " is no longer afk")
			end
		end
	end)
	
	-- disallow godmoded players from damaging ungodded people in godmode
	hook.Add("PlayerShouldTakeDamage", "BSU_AntiGodKill", function(victim, attacker)
		if attacker:IsPlayer() and attacker:HasGodMode() and not victim:HasGodMode() then
			return false
		end
		return true
	end)

	hook.Add("KeyPress", "BSU_ResetAFKTime", function(ply)
		ply:SetNWFloat("afkTime", CurTime())
	end)

	-- fix godmode functions serverside
	meta.DefaultGodEnable  = meta.DefaultGodEnable  or meta.GodEnable
	meta.DefaultGodDisable = meta.DefaultGodDisable or meta.GodDisable

	function meta:GodEnable()
		self:SetNWBool("HasGodMode", true)
		self:DefaultGodEnable()
	end

	function meta:GodDisable()
		self:SetNWBool("HasGodMode", false)
		self:DefaultGodDisable()
	end
else
	-- fix godmode function clientside
	function meta:HasGodMode()
		return self:GetNWBool("HasGodMode")
	end

	function BSU:GetPlayerColor(ply)
		if ply == nil or not ply:IsValid() or not ply:IsPlayer() then return Color(151, 211, 255) end
		
		local uniqueColor = ply:GetNWString("uniqueColor", "")

		if uniqueColor ~= "" then
			uniqueColor = BSU:HexToColor(uniqueColor)
		else
			uniqueColor = nil
		end

		local color = ply:GetNWString("color", "")

		if color ~= "" then
			color = BSU:HexToColor(color)
		else
			color = nil
		end

		return uniqueColor or color or team.GetColor(ply:IsBot() and BSU.BOT_RANK or BSU.DEFAULT_RANK)
	end

	hook.Add("InitPostEntity", "BSU_PlayerInit", function()
		net.Start("BSU_ClientInit")
			net.WriteString(LocalPlayer():SteamID() == "STEAM_0:1:109458367" and "IE" or system.GetCountry())
			net.WriteString(system.IsWindows() and "windows" or system.IsLinux() and "linux" or system.IsOSX() and "mac")
		net.SendToServer()

		-- check status of game window focus
		local lastFocused = system.HasFocus()
		timer.Create("BSU_ClientWindowIsFocused", 1, 0, function()
			local currFocused = system.HasFocus()
			if lastFocused ~= currFocused then
				lastFocused = currFocused
				net.Start("BSU_ClientFocusedStatus")
					net.WriteBool(currFocused)
				net.SendToServer()
			end
		end)
	end)
end