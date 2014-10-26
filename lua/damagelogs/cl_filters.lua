
if file.Exists("damagelog/filters.txt", "DATA") then
	file.Delete("damagelog/filters.txt")
end

if file.Exists("damagelog/filters_new.txt", "DATA") and not Damagelog.filter_settings then
	local settings = file.Read("damagelog/filters_new.txt", "DATA")
	if settings then
		Damagelog.filter_settings = util.JSONToTable(settings)
	end
end

function Damagelog:SaveFilters()
	local temp = table.Copy(self.filter_settings)
	file.Write("damagelog/filters_new.txt", util.TableToJSON(temp))
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