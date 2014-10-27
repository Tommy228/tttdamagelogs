
local html_size = 1220
local title_pos = 470
local legend_x = 540
local legend_y = 225

net.Receive("DL_SendStats", function()
	local length = net.ReadUInt(32)
	local data = net.ReadData(length)
	local decompressed = util.Decompress(data)
	local tbl = util.JSONToTable(decompressed)
	local m1, m2
	local jsons = {}
	for k,v in pairs(tbl) do
		local tbl = util.JSONToTable(k)
		jsons[k] = tbl
		if not m1 then
			m1 = tbl.month
		elseif tbl.month != m1 then
			m2 = tbl.month
			break
		end
	end
	if m2 and m1 < m2 then
		local tm1 = m1
		m1 = m2
		m2 = tm1
	end
	local months1, months2 = {}, {}
	for k,v in pairs(tbl) do
		local tbl = jsons[k] or util.JSONToTable(k)
		v.day = tbl.day
		v.month = tbl.month
		table.insert(tbl.month == m1 and months1 or months2, v)
	end
	table.SortByMember(months1, "day", true)
	table.SortByMember(months2, "day", true)
	Damagelog.MonthCategories = {}
	Damagelog.Serie1 = {}
	Damagelog.Serie2 = {}
	for k,v in ipairs(months2) do
		table.insert(Damagelog.MonthCategories, { day = v.day, month = v.month })
		table.insert(Damagelog.Serie1, v.teamkills)
		table.insert(Damagelog.Serie2, v.teamdamages)
	end
	for k,v in ipairs(months1) do
		table.insert(Damagelog.MonthCategories, { day = v.day, month = v.month })
		table.insert(Damagelog.Serie1, v.teamkills)
		table.insert(Damagelog.Serie2, v.teamdamages)
	end
	if #Damagelog.MonthCategories > 21 then
		local new_categories = {}
		local new_serie1 = {}
		local new_serie2 = {}
		for i=1,63,3 do
			local _date
			local value_teamkills, value_teamdamages
			if not Damagelog.MonthCategories[i] then break end
			if not Damagelog.MonthCategories[i+1] then
				_date = Damagelog.MonthCategories[i]
				value_teamkills = Damagelog.Serie1[i]
				value_teamdamages = Damagelog.Serie2[i]
			else
				_date = Damagelog.MonthCategories[i+1]
				if not Damagelog.MonthCategories[i+2] then
					value_teamkills = (Damagelog.Serie1[i] + Damagelog.Serie1[i+1]) / 2
					value_teamdamages = (Damagelog.Serie2[i] + Damagelog.Serie2[i+1]) / 2
				else
					value_teamkills = (Damagelog.Serie1[i] + Damagelog.Serie1[i+1] + Damagelog.Serie1[i+2]) / 3
					value_teamdamages = (Damagelog.Serie2[i] + Damagelog.Serie2[i+1] + Damagelog.Serie2[i+2]) / 3
				end
			end
			table.insert(new_categories, _date)
			table.insert(new_serie1, value_teamkills)
			table.insert(new_serie2, value_teamdamages)
		end
		Damagelog.MonthCategories = new_categories
		Damagelog.Serie1 = new_serie1
		Damagelog.Serie2 = new_serie2
	else
		html_size = 610
		title_pos = 155
		legend_x = 230
	end
	Damagelog.MonthCategoriesStr = "["
	Damagelog.Serie1Str = "["
	Damagelog.Serie2Str = "["
	for k,v in ipairs(Damagelog.MonthCategories) do
		local _end = k == #Damagelog.MonthCategories
		Damagelog.MonthCategoriesStr = Damagelog.MonthCategoriesStr.."'"..v.day.."/"..v.month..(_end and "']" or "',")
		Damagelog.Serie1Str = Damagelog.Serie1Str..math.Round(Damagelog.Serie1[k])..(_end and "]" or ",")
		Damagelog.Serie2Str = Damagelog.Serie2Str..math.Round(Damagelog.Serie2[k])..(_end and "]" or ",")
	end
end)

function Damagelog:Statistics(x,y)
		
	local html = vgui.Create("HTML")
	html:SetPos(5, 5)
	if not Damagelog.MonthCategories or #Damagelog.MonthCategories == 0 then
		html:SetHTML([[
			<body style="background-color:white">
				<p> No statistics yet ! After playing long enough, this tab will show you a line-chart of your teamkills/team damages. </p>
			</body>
		]])
	else
		html:SetHTML(string.format([[
		<!DOCTYPE HTML>
		<html>
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
			</head>
			<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
			<script type="text/javascript">
				$(function () 
				{
					$('#container').highcharts({
					title: {
						text: 'Statistics of the last 2 months',
						x: -%i,
						margin:70
					},
					xAxis: {
						categories: %s
					},
					yAxis: {
						title: {
							text: 'Percent'
						},
						plotLines: [{
							value: 0,
							width: 1,
							color: '#808080'
						}]
					},
					credits:{
						enabled:false
					},
					tooltip:{
						enabled:false,
						animation:false
					},
					legend: {
						layout: 'vertical',
						align: 'center',
						x:-%i,
						y:-225,
						verticalAlign: 'middle',
						borderWidth: 0
					},
					series: [{
						name: 'Teamkills',
						data:  %s
						}, {
						name: 'Team damages',
						data: %s
					}],
					plotOptions: {
						series: {
							enableMouseTracking: false
						}
					}	
					});
				});
			</script>
			<body>
				<script type="text/javascript" src="http://code.highcharts.com/highcharts.js"></script>
				<script type="text/javascript" src="http://code.highcharts.com/modules/exporting.js"></script>
				<div id="container" style="min-width: %ipx; height: 560px; margin: 0 auto"></div>
			</body>
		]], title_pos, Damagelog.MonthCategoriesStr, legend_x, Damagelog.Serie1Str, Damagelog.Serie2Str, html_size))
	end
	
	self.Tabs:AddSheet("Statistics", html, "icon16/chart_bar.png")

end