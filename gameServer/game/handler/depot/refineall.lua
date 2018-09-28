-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.item"
local math_floor = math.floor
--local cjson = require "include.cjson"
local _M = function(role,data)
	
	local equips = role.army:get_equipment_list_by_pos(data.pos)
	local uids ={}
	local refine = require 'game.handler.depot.refine'
	local bcontinue = true
	local counts = {}
	local uncontinue = {}
	local maxlev = 99999
	local items = {}
	--ngx.log(ngx.ERR,"equips:",cjson.encode(equips))
	for i,v in ipairs(equips) do
		local item = role.depot:get(v)
		if item then
			items[v] = item
			local reflev = item:get_refine_lev()
			if  reflev < maxlev then maxlev = reflev end 
		end
	end
	--ngx.log(ngx.ERR,"maxlev:",maxlev)
	maxlev = (math.floor(maxlev / 2) +1 ) * 2

	while bcontinue do
		bcontinue = false
		for v,item in pairs(items) do
			if not uncontinue[v] then
				local reflev = item:get_refine_lev()
				--ngx.log(ngx.ERR,"maxlev:",maxlev," reflev:",reflev," v:",v)
				if reflev < maxlev then
					local rs = refine(role,{id=v,typ=2})
					if rs == 0 then
						counts[v] = (counts[v] or 0) + 1
						bcontinue = true
					else
						uncontinue[v] = true
					end
				else
					uncontinue[v] = true
				end
			end
		end
	end
	return 0
end

return _M
