
local Player = FindMetaTable("Player")

DAMAGELOG_NOTIFY_ALERT = 1
DAMAGELOG_NOTIFY_INFO = 2

if SERVER then

	util.AddNetworkString("DL_Notify")
	
	function Player:Damagelog_Notify(msg_type, msg, _time, sound)
		net.Start("DL_Notify")
		net.WriteUInt(msg_type, 4)
		net.WriteString(msg)
		net.WriteUInt(_time, 4)
		net.WriteString(sound)
		net.Send(self)
	end
	
else

	Damagelog.Notifications = Damagelog.Notifications or {}

	local icons = {
		[DAMAGELOG_NOTIFY_ALERT] = Material("icon16/exclamation.png"),
		[DAMAGELOG_NOTIFY_INFO] = Material("icon16/information.png")
	}

	function Damagelog:Notify(msg_type, msg, _time, soundFile)
		if GetConVar("ttt_dmglogs_outsidenotification"):GetBool() then
			sound.PlayFile("sound/" .. soundFile, "play", function()
			end)
		else
			surface.PlaySound(soundFile)
		end
		table.insert(Damagelog.Notifications, {
			text = msg,
			icon = icons[msg_type] or icons[DAMAGELOG_NOTIFY_ALERT],
			_time = _time,
			start = UnPredictedCurTime(),
		});
	end
	
	net.Receive("DL_Notify", function()
		Damagelog:Notify(net.ReadUInt(4), net.ReadString(), net.ReadUInt(4), net.ReadString())
	end)

	local function DrawNotif(x, y, w, h, text, icon)
		local red = 75 + (175 * math.abs(math.sin(UnPredictedCurTime() * 2)))
		local b = 2
		draw.RoundedBox(10, x, y, w, h, Color(red, 75, 75, 255))
		draw.RoundedBox(10, x + b, y + b, w - b*2, h - b*2, Color(150, 150, 150, 255))
		x = x + 10
		y = y + h / 2 - 8
		surface.SetDrawColor(Color(255, 255, 255, 255))
		surface.SetMaterial(icon)
		surface.DrawTexturedRect(x, y, 16, 16)
		x = x + 26
		surface.SetTextColor(Color(255, 255, 255, 255))
		surface.SetTextPos(x, y)
		surface.DrawText(text)
	end
	
	hook.Add("HUDPaint", "RDM_Manager", function()
		local notifications = Damagelog.Notifications
		if #notifications > 0 then
			local curtime = UnPredictedCurTime()
			surface.SetFont("CenterPrintText")
			for k, v in pairs(notifications) do
				local w,h = surface.GetTextSize(v.text)
				w = w + 50
				h = h + 8
				local x = ScrW() - w
				local y = ScrH() * 0.2
				local tx = x
				local ty = y + (h + 5) * k
				if v.rollBack then
					tx = tx + (((1 - math.max(v.start + 1 - curtime, 0)) ^ 2) * tx)
					DrawNotif(tx, ty, w, h, v.text, v.icon);
					if v.start + 1 <= curtime then
						table.remove(notifications, k)
					end
				else
					tx = tx + ((math.max(v.start + 1 - curtime, 0) ^ 2) * tx)
					DrawNotif(tx, ty, w, h, v.text, v.icon);
					if v.start + v._time <= curtime then
						v.rollBack = true
						v.start = curtime
					end
				end
			end
		end
	end)	
	
	
end