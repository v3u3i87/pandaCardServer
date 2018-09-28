-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local s_sub = string.sub
local cjson = require "include.cjson"

local _M = {}
_M.data = config.template.growthfund

function _M:get(id)
	return self.data[id]
end


function _M:get_buy_fund_cost()
	if not self.cost then
		for k,v in pairs(self.data) do
			if v.type == 1 then
				self.cost = v.num
				break
			end
		end
	end
	return  { [ config.resource.diamond ] =self.cost }				 
end

function _M:get_fund_reward_profit(id)
	if not self.data[id] or not self.data[id].project then return false end
	return config:change_cost_num(self.data[id].project) or {}
end

function _M:get_type(id)
	if not self.data[id] or not self.data[id].type then return 0 end
	return self.data[id].type
end

function _M:get_need_num(id)
	if not self.data[id] or not self.data[id].num then return 999 end
	return self.data[id].num
end


return _M