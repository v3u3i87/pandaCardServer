-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local s_sub = string.sub
local cjson = require "include.cjson"

local _M = {}
_M.data = config.template.pay

_M.month_card_count_reward = 10  --10次之后无奖励
_M.pay_type ={
	nonal = 1,
	month_card = 2,
	high_card = 3
}

function _M:get(id)
	return self.data[id]
end

function _M:is_month_card(id)
	if not self.data[id] or  not self.data[id].tp or self.data[id].tp ~= 2 then return false end
	return true
end

function _M:is_high_card(id)
	if not self.data[id] or  not self.data[id].tp or self.data[id].tp ~= 3 then return false end
	return true
end

function _M:month_card_reward()
	return {[5] = 5}
end

function _M:high_card_reward()
	return {[5] = 10}
end

function _M:get_pay_item_type(id)
	if not self.data[id] or not self.data[id].tp then return 0 end
	return self.data[id].tp
end

function _M:get_pay_reward(id)
	if not self.data[id] or not self.data[id].mz then return 0 end
	return self.data[id].mz
end

return _M