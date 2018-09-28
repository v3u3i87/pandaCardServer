-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.item"
--有个性化id
local _M = model:extends()
_M.class = "role.knapsack"
_M.push_name  = "knapsack"
_M.changed_name_in_role = "knapsack"

_M.is_list = true
_M.is_key_num = true

function _M:isfull(t)
	return self.data[t] >= config.knapsack_max_num
end

function _M:gain(t,n)
	if n < 1 then return false end
	if not self.data[t] then self.data[t] = 0 end
	self.data[t] = self.data[t] + n
	self:changed(t)
	return self.data[t]
end

function _M:consume(t,n)
	if n < 1 then return false end
	if not self.data[t] then return false end
	if self.data[t] < n then return false end
	self.data[t] = self.data[t] - n
	local n = self.data[t]
	if self.data[t] == 0 then self.data[t] = nil end
	self:changed(t)
	return n
end

function _M:check_num(t,n)
	local cn = self.data[t] or 0
	if cn < n then return false,(n-cn) end
	return true
end

function _M:check_num_more(cost)
	if not cost or type(cost) ~= "table" then return false end
	for k,v in pairs(cost) do
		if not self.data[k] or self.data[k] < v then return false end
	end
	return true
end

function _M:gain_more(profit)
	for k,v in pairs(profit) do
		self:gain(k,v)
	end
end

function _M:consume_more(cost)
	for k,v in pairs(cost) do
		self:consume(k,v)
	end
end

function _M:use(t,n)
	if self:get(t) < n then return false end
	
	
	return self:consume(t,n)
end

function _M:compose(t,n)
	local can,goalid,pernum = config:can_compose(t)
	if not can then return false end
	local neednum = n*pernum
	if self:get(t) < neednum then return false end
	self.role:gain(goalid,n)
	return self:consume(t,neednum)
end

function _M:get_num(t)
	return self.data[t] or 0
end

return _M