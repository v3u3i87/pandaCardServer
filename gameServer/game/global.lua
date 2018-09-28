-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local CTimer = require "include.timer"
local _M = require "include.global"

_M.gm_password = "123qwe!@#"
local _old_init = _M.__init
local _old_take_off = _M.take_off

function _M:__init()
	ngx.log(ngx.ERR,"global init0")
	_old_init(self)
	ngx.log(ngx.ERR,"global init1")
	local config = self.config
	ngx.log(ngx.ERR,"global init2")
	self.generalMgr = require "game.model.general"
	self.generalMgr:init(config:get_db_config("general"))
	ngx.log(ngx.ERR,"global init3")
	self.resourceMgr = require "game.model.resourceMgr"
	self.resourceMgr:init(config:get_db_config("resource"))
	ngx.log(ngx.ERR,"global init4")
	self.rewardMgr = require "game.model.rewardMgr"
	self.rewardMgr:init(config:get_db_config("reward"))
	ngx.log(ngx.ERR,"global init5")
	self.countMgr = require "game.model.countMgr"
	self.countMgr:init(config:get_db_config("count"))
	ngx.log(ngx.ERR,"global init6")
	self.timer.reward_check = CTimer:new(60,config.reward_check_interval,0,function(self,rewardMgr) if self:idle() then rewardMgr:send() end end,self,self.rewardMgr)
	self.timer.general_check = CTimer:new(60,config.general_check_interval,0,function(self,generalMgr) if self:idle() then generalMgr:send() end end,self,self.generalMgr)
	self.timer.general_save = CTimer:new(60,config.general_save_interval,0,function(self,generalMgr) if self:idle() then generalMgr:save() end end,self,self.generalMgr)
	self.timer.resource_check = CTimer:new(60,config.resource_check_interval,0,function(self,resourceMgr) if self:idle() then resourceMgr:send() end end,self,self.resourceMgr)
	self.timer.countMgr_check = CTimer:new(60,config.count_check_interval,0,function(self,countMgr) if self:idle() then countMgr:send() end end,self,self.countMgr)
ngx.log(ngx.ERR,"global init7")
end

function _M:take_off()
	_old_take_off(self)
	if self.generalMgr then self.generalMgr:save() end
end

return _M