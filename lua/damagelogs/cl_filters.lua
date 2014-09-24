
if file.Exists("damagelog/filters.txt", "DATA") and not Damagelog.filter_settings then
	local settings = file.Read("damagelog/filters.txt", "DATA")
	if settings then
		Damagelog.filter_settings = util.JSONToTable(settings)
	end
end

function Damagelog:SaveFilters()
	local temp = table.Copy(self.filter_settings)
	temp["Filter by player"] = false
	file.Write("damagelog/filters.txt", util.TableToJSON(temp))
end

Damagelog.filters = Damagelog.filters or {}
Damagelog.filter_settings = Damagelog.filter_settings or {} 

DAMAGELOG_FILTER_BOOL = 1
DAMAGELOG_FILTER_PLAYER = 2

function Damagelog:AddFilter(name, filter_type, default_value)
	self.filters[name] = filter_type
	if self.filter_settings[name] == nil then
		self.filter_settings[name] = default_value
	end
end
if not Damagelog.filters["Filter by player"] then
	Damagelog:AddFilter("Filter by player", DAMAGELOG_FILTER_PLAYER, false)
end
	
function Damagelog:SettingToStr(filter_type, value)
	if filter_type == DAMAGELOG_FILTER_BOOL then
		if value then
			return "Enabled", Color(0, 200, 0)
		else
			return "Disabled", Color(200, 0, 0)
		end
	elseif filter_type == DAMAGELOG_FILTER_PLAYER then
		if not value then
			return "Disabled"
		end
		for k,v in pairs(player.GetAll()) do
			if v:SteamID() == value then
				return v:Nick()
			end
		end
		return "<player not found>"
	end
end