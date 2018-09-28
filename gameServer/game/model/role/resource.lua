-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.resource"
local timetool = require "include.timetool"
local bconfig = require "game.config"
local rankmgr = require "manager.rankMgr"
local roleMgr = require "manager.roleMgr"
local open_config = require "game.template.open"


local _M = model:extends()
_M.class = "role.resource"
_M.push_name  = "resource"
_M.changed_name_in_role = "resource"
_M.attrs = {
	step =0, --进度id
	inc =0,  --鼓舞次数
	pos =0,  --占领大关卡id
	max =0,
}

function _M:__up_version()
	_M.super.__up_version(self)
	if not self.vip then self.vip = 0	end
end

function _M:on_time_up()
	self.data.step =  0
	self.data.inc = 0
	self.data.pos =0
	self:changed("step")
	self:changed("inc")
	self:changed("pos")
end

function _M:update()
end

function _M:get_inc()
	return self.data.inc
end

function _M:can_stage_begin(id)
	if not  open_config:check_level(self.role,open_config.need_level.resource) then return false end
	local typ = config:get_stage_type(id)
	if typ == 1 and  id ~= self.data.step + 1 then return false 
	elseif typ == 2 and self.data.step < config:get_stage_need_step(id) then return false 
	end
	return true --测试屏蔽
	--return config:can_stage_begin(id)
end

function _M:set_stage_begin(id)
	self.stage_id = id
	config:set_stage_begin(id)
end

function _M:can_stage(id)
	return self.stage_id == id
end

function _M:stage(id,win)
	return config:stage(id,win,self.role:get_id())
end

function _M:set_stage_end(id,win)
	local typ = config:get_stage_type(id)
	self.stage_id = 0
	if win ~= 1 then return false end
	if typ == 1 then 
		self.data.step = self.data.step +1
		self:changed("step")
	elseif typ == 2 then
		self.data.pos = id
		self:changed("pos")
		config:set_stage_end(id)
	end
	if self.data.max < self.data.step then 
	self.data.max = self.data.step 
		self:changed("max")
	end

end

function _M:can_stage_all( )
	--一键扫荡VIP7或者指挥官等级70级开放
	return self.role:get_level() >= config.resource_all_need_level or self.role:get_vip_level() >= config.resource_all_need_vip
end

function _M:stage_all()
	local step = self.data.step
	self.data.step = self.data.max
	self:changed("step")
	return config:stage_all(step,self.data.max)
end

function _M:can_inspire()
	return self.data.inc < config.resource_inspire_max
end

function _M:get_inspire_cost()
	local num = config.resource_inspire_need_diamond[self.data.inc+1]
	return {[bconfig.resource.diamond] = num}
end

function _M:set_inspire()
	self.data.inc = self.data.inc +1
	self:changed("inc")
	return self.data.inc
end

function _M:set_step(step)
	if step > self.data.max then step = self.data.max end
	if step <0 then step = 1 end
	self.data.step = step
	self:changed("step")
end

return _M