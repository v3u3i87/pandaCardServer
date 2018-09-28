-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"

local _M = {}
_M.data = {
	companion = {30,32,34,36,38,40,34,40,30,30},
	companion_cost = {0,0,0,0,0,0,600,600,600,600},
	battle = {1,3,4,9,14,40,50,60},
	relation = config.template.armyrelation,
}

function _M:can_unlock_companion(id,level)
	if not self.data.companion[id] then return false end
	if  self.data.companion[id] > level then return false end
	return true
end

function _M:can_unlock_battle(id,level)
	if not self.data.battle[id] then return false end
	if  self.data.battle[id] > level then return false end
	return true
end

function _M:get_unlock_companion_cost(id)
	if not self.data.companion_cost[id] then return false end
	if self.data.companion_cost[id] == 0 then return false end
	return {[config.resource.diamond] = self.data.companion_cost[id]}
end

function _M:get_relation_attributes(data)
	local rs = {
		base = {},
		rate = {}
	}
	local items = require "game.template.item"
	local relations = self.data.relation
	local soldiers = {}
	for i,v in ipairs(data.battle) do
		soldiers[v] = 1
	end
	for i,v in ipairs(data.companion) do
		soldiers[v] = 1
	end
	local act_rel = {}
	for i,v in ipairs(data.battle) do
		if relations[v] then
			for _,relation in pairs(relations[v]) do
				local bactive = true
				for _,r in ipairs(relation.relation_armyvalue) do
					local it = items:get_type(r)
					if it == items.type.soldier and not soldiers[r] then
						if not soldiers[r] then
							bactive = false
							break
						end
					elseif it == items.type.equipment or it == items.type.accessory then
						bactive = false
						for _,e in ipairs(data.equips[i]) do
							if e == r then
								bactive = true
								break
							end
						end
						if not bactive then break end
					else
						bactive = false
						break
					end
				end
				if bactive and not act_rel[relation.relation_name] then
					act_rel[relation.relation_name] = 1
					for _,p in ipairs(relation.relation_value) do
						if p[2] ==  1 then
							append_attributes(rs.base,{p},v)
						else
							append_attributes(rs.rate,{{p[1],1,p[2]}},v)
						end
					end
				end
			end
		end
	end

	return rs
end

return _M