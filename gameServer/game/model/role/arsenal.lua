-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.arsenal"
local timetool = require "include.timetool"
local bconfig = require "game.config"
local task_config = require "game.template.task"
local vip_config = require "game.template.vip"
local open_config = require "game.template.open"

local math_floor = math.floor
local _M = model:extends()
_M.class = "role.arsenal"
_M.push_name  = "arsenal"
_M.changed_name_in_role = "arsenal"
_M.attrs = {
--[[
		每隔1.5小时会自动恢复1次。恢复到上限后不再恢复。
		n_num	数字	剩余挑战次数
		b_num	数字	购买次数
		count	数字	宝箱进度
		g_num	数字	领取宝箱次数
]]
	--n_num = config.arsen_max_n_num,
	b_num = 0,
	count = {0,0,0,0,0,0,0,0,0},
	g_num = {0,0,0,0,0,0,0,0,0},
	n_ut = 0,
}


function _M:__up_version()
	_M.super.__up_version(self)
	--if self.data.n_ut == 0 then self.data.n_ut = timetool:now() end
	if not self.data.n_num then self.data.n_num = vip_config:get_fun_itmes(self.role,vip_config.type.arsen_max_n_num) end
	if not self.vip then self.vip = 0	end
end

function _M:on_time_up()
	self.data.n_num = vip_config:get_fun_itmes(self.role,vip_config.type.arsen_max_n_num)	 --config:get_max_num(self.vip)
	self.data.b_num =  0
	self.data.n_ut = 0
	--self.data.count = {0,0,0,0,0,0,0,0,0}
	--self.data.g_num = {0,0,0,0,0,0,0,0,0}
	self.data.s = 0
	self:changed("n_num")
	self:changed("b_num")
	self:changed("n_ut")
	--self:changed("count")
	--self:changed("g_num")
end

function _M:on_vip_up()
	local last = self.vip or 0
	self.data.n_num  = self.data.n_num  + vip_config:get_fun_itmes(self.role,vip_config.type.arsen_max_n_num) - 
			vip_config:get_fun_itmes_vip(last,vip_config.type.arsen_max_n_num)
	self:changed("n_num")
	self.vip = self.role:get_vip_level()
end

function _M:update(vip)
	if not vip then vip = 0 end
	if not self.vip then self.vip = 0 end
	if self.vip ~= vip then self.vip = vip end
	local ltime = timetool:now() 
	if self.data.n_num < vip_config:get_fun_itmes(self.role,vip_config.type.arsen_max_n_num) and ltime - self.data.n_ut >= config.interval_time then 
			--self.data.n_num = self.data.n_num + 1
			self.data.n_num = self.data.n_num + math_floor((ltime - self.data.n_ut) /config.interval_time)
			self.data.n_ut = ltime

			if self.data.n_num >= vip_config:get_fun_itmes(self.role,vip_config.type.arsen_max_n_num) then
				self.data.n_ut = 0
			end
			self:changed("n_num")
			self:changed("n_ut")
	end
end

function _M:can_challenge(pos,num,level)
	if num >1 and not open_config:check_vip(self.role,open_config.need_vip.arsenal_challenge_num) then return false end

	self.role.tasklist:trigger(task_config.trigger_type.arsenal_challenge,num)
	if self.data.n_num - num >= 0 and config:check_challenge_level(pos,level) then return true end
	return false
end

function _M:cost_challenge(pos,num)
	self.data.n_num = self.data.n_num - num
	if self.data.n_num + num == vip_config:get_fun_itmes(self.role,vip_config.type.arsen_max_n_num) then
		self.data.n_ut = timetool:now() 
		self:changed("n_ut")
	end
	self.data.count[pos] = self.data.count[pos] + num
	self:changed("count")
	self:changed("n_num")
	
	self.role.tasklist:trigger(task_config.trigger_type.arsenal_win,num)
	self.role.activitylist:trigger(task_config.trigger_type.arsenal_win,num)

end

function _M:get_challenge_profit(id,num)
	return config:get_profit(id,num)
end


function _M:can_get_box(pos)
	local need_count = config:get_box_need_count(pos,self.data.g_num[pos])
	if need_count > 0 and need_count <= self.data.count[pos] then return true end
	return false
end

function _M:get_box(pos)
	return config:get_box(pos)
end

function _M:get_box_end(pos)
	self.data.g_num[pos] = self.data.g_num[pos] + 1
	self.data.count[pos] = 0
	self:changed("count")
	self:changed("g_num")
end

function _M:can_buy_num(num)
	--local max_buy = config:get_max_buy(self.vip)
	local max_buy = vip_config:get_fun_itmes(self.role,vip_config.type.arsen_max_b_mum)
	if max_buy > 0 and max_buy >= self.data.b_num + num then return true end
	return false
end

function _M:get_buy_cost(num)
	return config:get_buy_num_cost(self.data.b_num,num)
end

function _M:add_buy_num(num)
	self.data.b_num = self.data.b_num + num
	self.data.n_num = self.data.n_num + num
	self:changed("b_num")
	self:changed("n_num")
end


function _M:get_buy_num( )
	return self.data.b_num
end

return _M