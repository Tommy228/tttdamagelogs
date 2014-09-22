util.AddNetworkString("RDMAdd");
util.AddNetworkString("RDMRespond");
util.AddNetworkString("DLRDM_Start");
util.AddNetworkString("RDMApologise")
util.AddNetworkString("forbid")
util.AddNetworkString("noforbid")
util.AddNetworkString("DL_PreviousReports")

AddCSLuaFile("cl_rdm_manager.lua");
AddCSLuaFile("sh_notify.lua");
AddCSLuaFile("dermas/cl_respond.lua");
AddCSLuaFile("dermas/cl_infolabel.lua");
AddCSLuaFile("dermas/cl_repport.lua");
AddCSLuaFile("dermas/cl_repportPanel.lua");

include("sh_notify.lua");

Damagelog.rdmReporter = Damagelog.rdmReporter or {};
Damagelog.rdmReporter.stored = Damagelog.rdmReporter.stored or {};
Damagelog.rdmReporter.respond = Damagelog.rdmReporter.respond or {};
Damagelog.rdmReporter.prevRespond = Damagelog.rdmReporter.prevRespond or {}

function Damagelog.rdmReporter:SendAdmin(ply, index)
	if (!ply) then
		ply = {};
		
		for k, v in pairs(player.GetAll()) do
			if (v:CanUseRDMManager()) then
				table.insert(ply, v);
			end;
		end;
	end;
	
	if (index) then
		if (self.stored[index]) then
			net.Start("RDMAdd");
				net.WriteTable(self.stored[index]);
			net.Send(ply);
		end;
	else
		for k, v in pairs(self.stored) do
			net.Start("RDMAdd");
				net.WriteTable(v);
			net.Send(ply);
		end;
	end;
end;

function Damagelog.rdmReporter:SendRespond(ply)
	local steamID = ply:SteamID();
	net.Start("RDMRespond");
	net.WriteTable(Damagelog.rdmReporter.respond[steamID] or {});
	net.WriteTable(Damagelog.rdmReporter.prevRespond[steamID] or {});
	net.Send(ply);
end;

function Damagelog.rdmReporter:AddReport(ply, message, killer)
	if not Damagelog.RDM_Manager_Enabled then return end
	if (IsValid(ply) and ply.rdmInfo) then
		local repport = {
			time = ply.rdmInfo.time,
			round = ply.rdmInfo.round,
			message = message,
			
			ply = ply,
			plyName = ply:Nick(),
			plySteam = ply:SteamID(),

			state = 1;
			
			state_ply = NULL,
			
		};
				
		if ply.DeathDmgLog and ply.rdmInfo and ply.rdmInfo.round then
			repport.lastLogs = ply.DeathDmgLog[ply.rdmInfo.round]
		end
		
		repport.index = table.insert(self.stored, repport);

		if (killer and IsValid(killer)) then
			local steamID = killer:SteamID();

			repport.attacker = killer;
			repport.attackerName = killer:Nick();
			repport.attackerSteam = steamID;

			local respond = {
				message = repport.message,
				victim = repport.plyName,
				round = repport.round,
				time = repport.time,
				report = repport.index
			};

			if (!self.respond[steamID]) then
				self.respond[steamID] = {};
			end;

			respond.index = table.insert(self.respond[steamID], respond);

			if (!killer:Alive() or GetRoundState() != ROUND_ACTIVE) then
				Damagelog.rdmReporter:SendRespond(killer);
			end;
		end;
		
		Damagelog.rdmReporter:SendAdmin(nil, repport.index);
		Damagelog.notify:AddMessage("admin", "A new report has been submitted!", nil, "ui/vote_failure.wav");

		ply.rdmInfo = nil;
		
		local tbl = table.Copy(repport)
		local to_remove = {}
		for _,value in pairs(tbl) do
			if type(value) == "Entity" or type(value) == "Player" then
				tbl[_] = nil
			end
		end
		local encoded = util.TableToJSON(tbl)
		if Damagelog.Use_MySQL and Damagelog.MySQL_Connected then
			local insert_report = Damagelog.database:query("INSERT INTO damagelog_previousreports (`_index`, `report`) VALUES("..repport.index..","..sql.SQLStr(encoded)..");")
			insert_report:start()	
		elseif not Damagelog.Use_MySQL then
			local count = sql.QueryValue("SELECT COUNT(id) FROM damagelog_previousreports;")
			sql.Query("INSERT INTO damagelog_previousreports (`id`, `_index`, `report`) VALUES("..tostring(count+1)..","..repport.index..","..sql.SQLStr(encoded)..");")
		end	
	end;
end;

function Damagelog.rdmReporter:StartRepport(ply, doesCreate)
	if (doesCreate) then
		ply.rdmInfo = {
			time = Damagelog.Time,
			round = Damagelog.CurrentRound,
		};
	end;
	
	net.Start("DLRDM_Start");
	if ply.DeathDmgLog and ply.DeathDmgLog[Damagelog.CurrentRound] then
		net.WriteUInt(1, 1);
		net.WriteTable(ply.DeathDmgLog[Damagelog.CurrentRound]);
	else
		net.WriteUInt(0,1);
	end;
	net.Send(ply);
end;

function Damagelog.rdmReporter:CanReport(ply)
	if (IsValid(ply)) then
		local found_admin = false
		if #player.GetAll() <= 1 then
			return false, "You are alone!"
		end
		for k,v in pairs(player.GetAll()) do
			if v:CanUseRDMManager() then
				found_admin = true
				break
			end
		end
		if not found_admin then
			return false, "No admins online!"
		end
		if (!ply:Alive() or GetRoundState() != ROUND_ACTIVE) then
			if (ply.rdmRoundPlay) then
				return true;
			else
				return false, "You need to play before reporting!";
			end;
		else
			return false, "You can't report when you are alive!";
		end;
	end;
end;

function Damagelog.rdmReporter:SendPreviousReports(ply)
	net.Start("DL_PreviousReports")
	net.WriteTable(Damagelog.previous_reports)
	if ply then
		net.Send(ply)
	else
		local tbl = {}
		for k,v in pairs(player.GetAll()) do
			if v:CanUseRDMManager() then
				table.insert(tbl, v)
			end
		end
		net.Send(tbl)
	end
end

net.Receive("RDMAdd", function(len, ply)
	local message = net.ReadString();
	local killer = net.ReadEntity();

	if (ply.rdmInfo and message) then
		Damagelog.rdmReporter:AddReport(ply, message, killer);
	end;
end);

net.Receive("RDMRespond", function(len, ply)
	local message = net.ReadString();
	local previous = net.ReadUInt(1) == 1
	local index = net.ReadUInt(8);
	local steamID = ply:SteamID();
	
	local tbl = previous and Damagelog.rdmReporter.prevRespond or Damagelog.rdmReporter.respond
			
	if (tbl) then
		local respond  
		if not previous then
			respond = Damagelog.rdmReporter.respond[steamID][index]
		else
			respond = Damagelog.rdmReporter.prevRespond[steamID][index]
		end

		if (respond) then
			if not previous then
				table.remove(Damagelog.rdmReporter.respond[steamID], index);
				Damagelog.rdmReporter.stored[respond.report].attackerMessage = message;
				Damagelog.rdmReporter:SendAdmin(nil, respond.report, true);
			else
				table.remove(Damagelog.rdmReporter.prevRespond[steamID], index);
				Damagelog.previous_reports[respond.report].attackerMessage = message;
				Damagelog.rdmReporter:SendPreviousReports()
			end
			Damagelog.notify:AddMessage("admin", "A response has been submitted! ", "icon16/error.png", "ui/vote_yes.wav");
		end;
		
		if not previous then
			local tbl = table.Copy(Damagelog.rdmReporter.stored[index])
			local to_remove = {}
			for _,value in pairs(tbl) do
				if type(value) == "Entity" or type(value) == "Player" then
					tbl[_] = nil
				end
			end
			local encoded = util.TableToJSON(tbl)
			local query = "UPDATE damagelog_previousreports SET report = "..sql.SQLStr(encoded).." WHERE _index = "..tbl.index..";"
			if Damagelog.Use_MySQL and Damagelog.MySQL_Connected then
				local update = Damagelog.database:query(query)
				update:start()
			elseif not Damagelog.Use_MySQL then
				sql.Query(query)
			end
		end
		
		local found = false
		if not previous then
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == Damagelog.rdmReporter.stored[respond.report].plySteam then
					found = v
					break
				end
			end
		end
		if found then
			net.Start("RDMApologise")
			net.WriteEntity(ply)
			net.WriteString(message)
			net.Send(found)
		end
	end;
	
end);

net.Receive("forbid", function(_, ply)
	local steamid = net.ReadString()
	if not steamid then return end
	for k,v in pairs(Damagelog.rdmReporter.stored) do
		if v.attackerSteam == steamid and v.plySteam == ply:SteamID() then
			v.forbid = true
			v.noforbid = false
			for _,pl in pairs(player.GetAll()) do
				if pl:CanUseRDMManager() then
					Damagelog.rdmReporter:SendAdmin(pl, k);
					Damagelog.notify:AddMessage(pl, "A report has been updated!", "icon16/information.png");
				end
			end
			local tbl = table.Copy(v)
			local to_remove = {}
			for _,value in pairs(tbl) do
				if type(value) == "Entity" or type(value) == "Player" then
					tbl[_] = nil
				end
			end
			local encoded = util.TableToJSON(tbl)
			local query = "UPDATE damagelog_previousreports SET report = "..sql.SQLStr(encoded).." WHERE _index = "..tbl.index..";"
			if Damagelog.Use_MySQL and Damagelog.MySQL_Connected then
				local update = Damagelog.database:query(query)
				update:start()
			elseif not Damagelog.Use_MySQL then
				sql.Query(query)
			end
		end
	end;	
end)

net.Receive("noforbid", function(_, ply)
	local steamid = net.ReadString()
	if not steamid then return end
	for k,v in pairs(Damagelog.rdmReporter.stored) do
		if v.attackerSteam == steamid and v.plySteam == ply:SteamID() then
			v.noforbid = true
			v.forbid = false
			for _,pl in pairs(player.GetAll()) do
				if pl:CanUseRDMManager() then
					Damagelog.rdmReporter:SendAdmin(pl, k);
					Damagelog.notify:AddMessage(pl, "A report has been updated!", "icon16/information.png");
				end
			end
			local tbl = table.Copy(v)
			local to_remove = {}
			for _,value in pairs(tbl) do
				if type(value) == "Entity" or type(value) == "Player" then
					tbl[_] = nil
				end
			end
			local encoded = util.TableToJSON(tbl)
			local query = "UPDATE damagelog_previousreports SET report = "..sql.SQLStr(encoded).." WHERE _index = "..tbl.index..";"
			if Damagelog.Use_MySQL and Damagelog.MySQL_Connected then
				local update = Damagelog.database:query(query)
				update:start()
			elseif not Damagelog.Use_MySQL then
				sql.Query(query)
			end
		end
	end
end)


hook.Add("TTTEndRound", "RDM_Respond", function()
	for k, v in pairs(player.GetAll()) do
		local steamID = v:SteamID();

		if (v:Alive()) then
			Damagelog.rdmReporter:SendRespond(v);
		end;
	end;
end);

function Damagelog:TruncateReports()
	if Damagelog.Use_MySQL and Damagelog.MySQL_Connected then
		local truncate_reports = Damagelog.database:query("TRUNCATE damagelog_previousreports;")
		truncate_reports:start()
	elseif not Damagelog.Use_MySQL then
		sql.Query("DELETE FROM damagelog_previousreports;")
	end
end

hook.Add("TTTBeginRound", "RDM_Respond", function()
	Damagelog:TruncateReports()
	for k, v in pairs(player.GetAll()) do
		v.rdmRoundPlay = true;
		v.rdmSend = nil;
		v.rdmInfo = nil;
	end;
end);

concommand.Add("DLRDM_ForceVictim", function(ply, cmd, args)
	local victim = args[1]
	print(victim, tonumber(victim), Entity(tonumber(victim)))
	if tonumber(victim) and IsValid(Entity(tonumber(victim))) then
		victim = Entity(tonumber(victim))
		Damagelog.rdmReporter:SendRespond(victim)
	end
end)

hook.Add("PlayerDeath", "RDM_Killer", function(victim, infl, attacker)
	if (Damagelog.RDM_Manager_Window == 1) then
		victim.rdmSend = true;
		victim.rdmInfo = {
			time = Damagelog.Time,
			round = Damagelog.CurrentRound,
		};
	end;

	Damagelog.rdmReporter:SendRespond(victim);
end);

hook.Add("PlayerSay", "DLRDM_Command", function(ply, text, teamOnly)
	text = text:lower();

	if string.Left(text, #Damagelog.RDM_Manager_Command) == Damagelog.RDM_Manager_Command and Damagelog.RDM_Manager_Enabled then
		local succes, fail = Damagelog.rdmReporter:CanReport(ply);
		if (succes) then
			Damagelog.rdmReporter:StartRepport(ply, true);
		else
			if (fail) then
				Damagelog.notify:AddMessage(ply, fail,
				"icon16/information.png", "buttons/weapon_cant_buy.wav");
			end;
		end;

		return "";
	end;
end);

hook.Add("PlayerAuthed", "RDM_SendAdmin", function(ply)
	if ply:CanUseRDMManager() and Damagelog.RDM_Manager_Enabled then
		Damagelog.rdmReporter:SendAdmin(ply);
		for k,v in pairs(Damagelog.previous_reports) do
			if ply:SteamID() == v.state_ply_steamid then
				v.state_ply = ply
			end
		end
		timer.Simple(10, function()
			Damagelog.rdmReporter:SendPreviousReports()
		end)
	end;
	if Damagelog.RDM_Manager_Enabled then
		Damagelog.rdmReporter:SendRespond(ply)
	end
end);

concommand.Add("DLRDM_Repport", function(ply)
	if not Damagelog.RDM_Manager_Enabled then return end
	if (IsValid(ply)) then
		if (!ply:Alive()) then
			if (ply.rdmSend) then
				ply.rdmSend = nil;
				Damagelog.rdmReporter:StartRepport(ply);
			else
				Damagelog.rdmReporter:StartRepport(ply, true);
			end;
		end;
	end;
end);

concommand.Add("DLRDM_State", function(ply, cmd, args, str)
	if not Damagelog.RDM_Manager_Enabled then return end 
	if (IsValid(ply) and ply:CanUseRDMManager()) then
		if (args[1] and args[2]) then
			local index = tonumber(args[1]);
			local state = tonumber(args[2]);
			local previous = tonumber(args[3]) == 1

			local tbl
			if previous then
				tbl = Damagelog.previous_reports
			else
				tbl = Damagelog.rdmReporter.stored
			end
			if (index and tbl[index] and state) then
				local report = tbl[index];
				report.state = state;
				if state == 2 or state == 3 then
					report.state_ply_steamid = ply:SteamID()
					report.state_ply = ply
				else
					report.state_ply_steamid = nil
					report.state_ply = NULL
				end
				
				for k,v in pairs(player.GetAll()) do
					if v:CanUseRDMManager() then
						if previous then
							Damagelog.rdmReporter:SendPreviousReports()
						else
							Damagelog.rdmReporter:SendAdmin(v, index);
						end
						Damagelog.notify:AddMessage(v, "A report has been updated!", "icon16/information.png");
					end
				end
				local tbl = table.Copy(tbl[index])
				local to_remove = {}
				for _,value in pairs(tbl) do
					if type(value) == "Entity" or type(value) == "Player" then
						tbl[_] = nil
					end
				end
				local encoded = util.TableToJSON(tbl)
				local update = Damagelog.database:query("UPDATE damagelog_previousreports SET report = "..sql.SQLStr(encoded).." WHERE _index = "..tbl.index..";")
				update:start()
			end;
		end;
	end;
end);
