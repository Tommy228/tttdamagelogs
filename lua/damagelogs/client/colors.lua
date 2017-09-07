if file.Exists("damagelog/colors_v3.txt", "DATA") and not Damagelog.colors then
	local colors = file.Read("damagelog/colors_v3.txt", "DATA")

	if colors then
		Damagelog.colors = util.JSONToTable(colors)
	end
end

function Damagelog:AddColor(id, default)
	if not self.colors then
		self.colors = {}
	end

	if not self.colors[id] then
		self.colors[id] = {
			Default = default,
			Custom = default
		}
	elseif self.colors[id].Default ~= default then
		self.colors[id].Default = default
	end
end

function Damagelog:GetColor(index)
	return self.colors[index] and self.colors[index].Custom or Color(0, 0, 0)
end

function Damagelog:SaveColors()
	file.Write("damagelog/colors_v3.txt", util.TableToJSON(self.colors))
end
