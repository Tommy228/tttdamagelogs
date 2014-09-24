Damagelog.notify = Damagelog.notify or {};

if (CLIENT) then
	Damagelog.notify.stored = Damagelog.notify.stored or {};

	function Damagelog.notify:AddMessage(message, icon, sounds, time)
		if (!message or message == "") then
			return;
		end;

		local curTime = UnPredictedCurTime();

		if (icon) then
			icon = Material(icon);
		else
			icon = Material("icon16/exclamation.png");
		end;

		if (sounds) then
			surface.PlaySound(sounds);
		end;

		table.insert(self.stored, {
			text = message,
			icon = icon,
			time = time or 5,
			start = curTime,
		});
	end;

	function Damagelog.notify:DrawHUDNotif(x, y, w, h, text, icon)
		local red = 75 + (175 * math.abs(math.sin(UnPredictedCurTime() * 2)))
		local b = 2;
		
		draw.RoundedBox(10, x, y, w, h, Color(red, 75, 75, 255));
		draw.RoundedBox(10, x + b, y + b, w - b*2, h - b*2, Color(150, 150, 150, 255));
		
		x = x + 10;
		y = y + h / 2 - 8;
		
		surface.SetDrawColor(Color(255, 255, 255, 255));
		surface.SetMaterial(icon);
		surface.DrawTexturedRect(x, y, 16, 16);
		
		x = x + 26;
		
		surface.SetTextColor(Color(255, 255, 255, 255));
		surface.SetTextPos(x, y);
		surface.SetFont("CenterPrintText");
		surface.DrawText(text);
	end;

	hook.Add("HUDPaint", "RDM_Notify", function()
		local self = Damagelog.notify;
		
		if (#self.stored == 0) then
			return;
		end;

		local curTime = UnPredictedCurTime();
		local scrW, scrH = ScrW(), ScrH();
		local w = 250;
		local h = 25;
		local x = scrW - w;
		local y = scrH * 0.2;

		for k, v in pairs(self.stored) do
			local tx = x;
			local ty = y + (h + 5) * k;

			if (v.rollBack) then
				tx = tx + (((1 - math.max(v.start + 1 - curTime, 0)) ^ 2) * tx);
				self:DrawHUDNotif(tx, ty, w, h, v.text, v.icon);

				if (v.start + 1 <= curTime) then
					table.remove(self.stored, k);
				end;
			else
				tx = tx + ((math.max(v.start + 1 - curTime, 0) ^ 2) * tx);
				self:DrawHUDNotif(tx, ty, w, h, v.text, v.icon);

				if (v.start + v.time <= curTime) then
					v.rollBack = true;
					v.start = curTime;
				end;
			end;
		end;
	end);

	net.Receive("DLRDM_Notify", function(len)
		local recue = net.ReadTable();
		
		Damagelog.notify:AddMessage(recue.message, recue.icon, recue.sounds, recue.time);
	end);
else
	util.AddNetworkString("DLRDM_Notify");

	function Damagelog.notify:AddMessage(ply, message, icon, sounds, time)
		if not Damagelog.RDM_Manager_Enabled then return end 
		if (!ply) then
			ply = player.GetAll();
		elseif (ply == "admin") then
			ply = {};
		
			for k, v in pairs(player.GetAll()) do
				if (v:CanUseRDMManager()) then
					table.insert(ply, v);
				end;
			end;
		end;

		if (message and message != "") then
			local toSend = {
				message = message,
				icon = icon or "icon16/exclamation.png",
				sounds = sounds,
				time = time or 5
			};

			net.Start("DLRDM_Notify");
				net.WriteTable(toSend);
			net.Send(ply);
		end;
	end;
end;
