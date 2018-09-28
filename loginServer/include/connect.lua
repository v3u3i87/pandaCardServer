local class = require "include.class"
local timetool = require "include.timetool"
local cjson = require "include.cjson"

local _M = class()

function _M:__init(client_type)
	local CClient = require "include.client"
	self.client_type = client_type or CClient.client_type.websocket
	self.client = CClient:new();
	self.idx = nil
	self.role = nil
	self.start_time = timetool:now()
	self.log_rec = {
		client_ip = ngx.var.remote_addr or "unknown",
		role_id = 0,
		content = "",
		request_time = self.start_time,
	}
end

function _M:append_log(task,status,result)
	if self.config.log.active then
		self.log_rec.return_time = timetool:now()
		self.log_rec.task = task or "unknown"
		self.log_rec.status = status or 0
		self.log_rec.result = result or ""
		self.logMgr:append(self.log_rec)
	end
end

function _M:process_error(code,msg,task,ext,blog)
	local m = {
		task = task or "error",
		status = code,
		msg = msg,
		ext = ext,
		time = timetool:now()
	}
	local msg = cjson.encode(m)
	if blog then
		ngx.log(ngx.ERR,msg)
	end
	self:append_log(task or "error",code,msg)
	self.client:send(msg)
end

function _M:role_update_thread_run()
	while self.role do
		ngx.sleep(self.config.role.update_interval)
		self.role:update()
		self.role:push_update()
	end	
end

function _M:mainHandler(data,typ)
	self.global:request()
	self.log_rec.request_time = timetool:now()
	self.log_rec.content = data
	
	if typ == "text" then
		local ok,data = pcall(cjson.decode,data)
		if ok and type(data) == 'table' then
			local task = data.task
			if type(task) ~= "string" or #task < 1 then return self:process_error(2,'task error',nil,data.ext) end
			local ok, handler = pcall(require, "game.handler."..task)
			if not ok or type(handler) ~= 'function' then return self:process_error(2,'without this task:'..task,data.ext) end
			if not self.role and task ~= "login" then return self:process_error(3,"no role login",task,data.ext) end
			local ok,result = handler(self.role,data)
			if ok ~= 0 then 
				if self.role and not self.role.isgm then self.role:push_update() end
				return self:process_error(ok,result,task,data.ext)
			end
			if task == "login" then
				if data.uid == "gm" then
					self.role = {isgm = 1}
					self.log_rec.role_id = -1
					self.global.gm_client = self.client
				else
					idx = self.clientMgr:add(self.client)
					self.client.uid = data.uid
					self.role = self.roleMgr:get_role(data.uid)
					if self.role then
						self.role:login(self.client)
						--self.role:update()
						ngx.thread.spawn(self.role_update_thread_run,self)
						self.log_rec.role_id = self.role:get_id()
					end
				end
			else
				if self.role and not self.role.isgm then 
					self.role:push_update()
				end
			end

			result = result or {}
			result.status = 0
			result.task = data.task
			result.time = timetool:now()
			result.ext = data.ext
			local rs = cjson.encode(result)
			self:append_log(task,result.status,rs)
			self.client:send(rs)
		elseif type(self.log_rec.content) == 'string' and  self.log_rec.content == "HeartBeat" then
			self.client:send(self.log_rec.content)
		else
			self:process_error(1,'data structure error')
			ngx.log(ngx.ERR,"data.err:",data)
		end
	else
		self:process_error(1,'wrong data format')
	end
end

function _M:safeMainHandler(data,typ)
	local ok,result = pcall(self.mainHandler,self,data,typ)
	if not ok then return self:process_error(1,result or "server error",nil,data,true) end
end

function _M:run(global,config)
	self.global = global or require "include.global"

	if self.global:get_status() ~= self.global.status_type.running then
		local arg = ngx.req.get_uri_args()
		if arg.gm ~= ngx.md5(self.global.gm_password) then
			local ok,err = self.client:init(self.client_type);
			self.client:send('{"status":5,"task":"error","msg":"server is not running"}')
			ngx.say("server is not running")
			return
		end
	end
	
	self.global:init()
	
	self.config = config or require "game.config"
	self.clientMgr = require "manager.clientMgr"
	self.roleMgr = require "manager.roleMgr"
	self.logMgr = require "manager.logMgr"
	
	self:append_log("connect")
	local ok,err = self.client:init(self.client_type,self.config.net.timeout,self.config.net.max_payload_len,self.safeMainHandler,self,true);

	if self.role and self.role.logout then self.role:logout() end
	if idx then	self.clientMgr:remove(idx) end

	self.log_rec.content = ""
	self.log_rec.request_time = self.start_time
	if ok then
		self:append_log("disconnect",0,"normal")
	else
		self:append_log("disconnect",-1,err or "has a error")
	end
end

return _M