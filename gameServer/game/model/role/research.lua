-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local timetool = require "include.timetool"
local lottery_config = require "game.template.research"
local deepcopy = require "include.deepcopy"
local config = require "game.config"

local _M = model:extends()
_M.class = "role.research"
_M.push_name  = "research"
_M.changed_name_in_role = "research"
_M.n_free_num  = 5
_M.h_free_num  = 1
_M.attrs = {
	lottery = {
		n_num = 0,
		h_num = 0,
		n_free = _M.n_free_num,
		h_free = 0,
		n_ut = 0,
		h_ut = 0,	--开始时间，每24小时获得一次免费次数
	},
	exchange = {
		m_num = 14,
		o_num = 4
	},
	shop = {
	},
}
function _M:__up_version()
	_M.super.__up_version(self)
	if self.data.lottery.n_ut == 0 then self.data.lottery.n_ut = timetool:get_hour_time(0) end
	if self.data.lottery.h_ut == 0 then self.data.lottery.h_ut = timetool:now() - timetool.one_day end
end

function _M:on_time_up()
	self.data.lottery.n_ut = timetool:get_hour_time(0)
	self.data.lottery.n_free = _M.n_free_num
	self:changed("lottery")
end



function _M:check_lottery_cost(typ)
	if self:get_lottery_free(typ) > 0 then return true,{} end
	local cost = lottery_config:get_lottery_cost(typ,lottery_config.cost_res_type.goods)
	local en =nil
	local diamond =0
	en,diamond,cost = self.role:check_resource_num(cost)
	if not en then
		cost = lottery_config:get_lottery_cost(typ,lottery_config.cost_res_type.gem)
		en,diamond,cost = self.role:check_resource_num(cost)
		if not en then return false,{}
		else return true,cost end
	end
		return true,cost
end

function _M:get_lottery_free(typ)
	if typ == lottery_config.lottery_type.normal_one then return self.data.lottery.n_free 
	elseif typ == lottery_config.lottery_type.diamond_one then 
		if timetool:now() - self.data.lottery.h_ut > timetool.one_day and self.data.lottery.h_free <=0 then 
			self.data.lottery.h_free = 1
			self.data.lottery.h_ut = timetool:now()
		end
		return self.data.lottery.h_free
	end
	return 0
end

function _M:cost_lottery_free(typ)
	if typ == lottery_config.lottery_type.normal_one  then  
		if self.data.lottery.n_free >0 then self.data.lottery.n_free =  self.data.lottery.n_free - 1 end
		self.data.lottery.n_num =  self.data.lottery.n_num +1
	elseif typ == lottery_config.lottery_type.diamond_one then
		if self.data.lottery.h_free >0 then 
			self.data.lottery.h_free = self.data.lottery.h_free -1
		end
		self.data.lottery.h_num =  self.data.lottery.h_num +1
	elseif typ == lottery_config.lottery_type.diamond_ten then
		self.data.lottery.h_num =  self.data.lottery.h_num +10
	end
	self:changed("lottery")
end

function _M:lottery_nomorl_one()
	local profit =lottery_config:lottery(lottery_config.lottery_type.normal_one,self.data.lottery.n_num,1)
	if profit then 
		self:cost_lottery_free(lottery_config.lottery_type.normal_one)
	end
	return profit
end

function _M:lottery_high_one()
	local profit =lottery_config:lottery(lottery_config.lottery_type.diamond_one,self.data.lottery.h_num,1)
	if profit then 
		self:cost_lottery_free(lottery_config.lottery_type.diamond_one)
	end
	return profit
end

function _M:lottery_high_ten()
	local profit =lottery_config:lottery(lottery_config.lottery_type.diamond_ten,self.data.lottery.h_num,10)
	if profit then 
		self:cost_lottery_free(lottery_config.lottery_type.diamond_ten)
	end
	return profit
end

function _M:exchange_money()
end

function _M:exchange_offline()
end

return _M