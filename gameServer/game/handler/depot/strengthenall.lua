-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.item"

local _M = function(role,data)
	if not data.pos or type(data.pos) ~= "number" then return 2 end
	if data.pos <= 0 or data.pos >9 then return 2 end
	local equips = role.army:get_equipment_list_by_pos(data.pos)
	local streng = require 'game.handler.depot.strengthen'
	local bcontinue = true
	local counts = {}
	local uncontinue = {}
	while bcontinue do
		bcontinue = false
		for i,v in ipairs(equips) do
			if not uncontinue[v] then
				local rs = streng(role,{id=v,num=1})
				if rs == 0 then
					counts[v] = (counts[v] or 0) + 1
					bcontinue = true
				else
					uncontinue[v] = true
				end
			end
		end
	end

	return 0,{data=counts}
end

return _M
