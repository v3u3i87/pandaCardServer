local timetool = require "include.timetool"
local CTimer = require "include.timer"

local _M = {}
_M.gm_password = "123qwe!@#"
_M.complete = false
_M.begin = false
_M.last_request_time = 0
_M.timer = {}
_M.busy = 0
_M.status_type = {
	running = 1,
	closed = 2,
}
_M.status = _M.status_type.running

function _M:__init()
	local config = require "game.config"
	config:init()
	self.mailMgr = require "manager.mailMgr"
	local CMail = require(config.mail.model)
	self.mailMgr:init(config:get_db_config("mail"),CMail,config.mail.failure_time)
	self.roleMgr = require "manager.roleMgr"
	local CRole = require(config.role.model)
	self.roleMgr:init(config:get_db_config("role"),config.role.attributes,CRole)
	self.rankMgr = require "manager.rankMgr"
	self.rankMgr:init(config:get_db_config("rank"),config.rank)
	self.roleMgr:clean(true)
	
	self.timer.role_save = CTimer:new(60,config.role.save_interval,0,function(self,roleMgr) if self:idle() then roleMgr:save(100) end end,self,self.roleMgr)
	self.timer.role_clean = CTimer:new(60,config.role.clean_interval,0,function(self,roleMgr) if self:idle() then roleMgr:clean() end end,self,self.roleMgr)
	self.timer.mail_save = CTimer:new(60,config.mail.save_interval,0,function(self,mailMgr) if self:idle() then mailMgr:save() end end,self,self.mailMgr)

	if config.log.active then
		self.logMgr = require "manager.logMgr"
		self.logMgr:init(config:get_db_config("log"))
		self.timer.log_save = CTimer:new(60,config.log.save_interval,0,function(self,logMgr) if self:idle() then logMgr:save() end end,self,self.logMgr)
	end
	self.config = config
end

function _M:init()
	if not self.begin then
		self.begin = true
		self:__init()
		self.complete = true
	end
	while not self.complete do
		ngx.sleep(1)
	end
end

function _M:request()
	local cur = timetool:now(true)
	if self.last_request_time - cur < 1 then
		self.busy = self.busy + 1
	else
		self.last_request_time = cur
		self.busy = 0
	end
end

function _M:idle()
	local cur = timetool:now(true)
	if cur - self.last_request_time > 1 then return true end
	if self.busy < 50 then return true end
	return false
end

function _M:get_status()
	return self.status
end

function _M:take_off()
	for i,v in pairs(self.timer) do
		v:stop()
	end
	self.timer = {}
	
	if self.roleMgr then 
		self.roleMgr:kick_role()
		self.roleMgr:save()
	end
	
	if self.rankMgr then self.rankMgr:save() end
	if self.logMgr then self.logMgr:save() end
	if self.mailMgr then self.mailMgr:save() end
end

function _M:open()
	self:close()
	if self.gm_client then self.gm_client:send('{"status":0,"time":'.. timetool:now() ..',"task":"gm.service_open"}') end
	os.exit()
end

function _M:close()
	if self.status == self.status_type.closed then return end
	self.status = self.status_type.closed
	self:take_off()
end

return _M