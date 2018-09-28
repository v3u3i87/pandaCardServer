-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.task"
local timetool = require "include.timetool"

local _M = model:extends()
_M.class = "task"
_M.push_name  = "tasklist"
_M.changed_name_in_role = "tasklist"
_M.attrs = {
	p = 0,		--任务原型id
	g = 0,		--进度(当前完成数量)
	s = 0,		--当前状态   0—	未激活   1—任务中 2—已完成任务进度 3—已领取奖励 4.任务已过期
	--et =0,
	--lt =0,
}

function _M:__up_version()
	_M.super.__up_version(self)
	if not self.data.et then
		self.data.et = config:get_end_time(self.data.p)

	end
end

function _M:get_schedule()
	return self.data.g or 0
end

function _M:trigger(value)
	if self.data.s == 0 or self.data.s == 3 then return self.data.s == 3 end
	if self.data.lt and timetool:now() < self.data.lt  then return false end
	local old_g = self.data.g
	local old_s = self.data.s
	if value and value >0 then if not config:check_tc(self.role,self.data.p,value) then value = 0 end end

	if config:is_reached_trigger(self.data.p) then
		if value and value > 0 then 
			self.data.g = value
		else
			self.data.g = config:get_reached_schedule(self.role,self.data.p)
		end
	else
		self.data.g = self.data.g + (value or 1)
	end
	--ngx.log(ngx.ERR,"p:",self.data.p," g:",self.data.g, "check_finish():",config:check_finish(self.role,self.data.p) , " get_num():",config:get_num(self.data.p))
	if self.data.s < 4 and config:check_finish(self.role,self.data.p) and config:get_num(self.data.p) <=1  then
		self.data.s = 2
	else
		self.data.s = 1
	end
	if self.data.s ~= old_s then self:changed("s") end
	if self.data.g ~= old_g then self:changed("g") end
	return false
end

function _M:can_finish()
	return self.data.s == 2
end

function _M:finish(pos,num)
	local profit = config:get_profit(self.data.p,pos,num)
	local new_task = config:get_next_task(self.data.p,self.data.g)
	self.data.s = 3
	if new_task == self.data.p then self.data.s = 1 end
	self:changed("s")
	return profit,new_task
end

function _M:failed()
	if self.data.et == 0 or not self.data.et then return false end
	return  timetool:now() >= self.data.et
end

function _M:set_s(value)
	self.data.s = value
	self:changed("s")
end

return _M