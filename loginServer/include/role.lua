local class = require "include.class"
local mysql = require "include.mysql"
local cjson = require "include.cjson"
local timetool = require "include.timetool"
local t_insert = table.insert
local t_concat = table.concat

local _M = class()
_M.class = "role"
_M.all_attrs = {}
_M.db_config = {}
_M.dead_time = 7 * timetool.one_day

function _M:__init(id,data)
	self.id = id
	self.dirty = false
	self.dirty_attrs = {}
	if not data or type(data) ~= "table" then data = {} end

	self.idx = data.id
	self.name = data.rname
	self.logouttime = data.logouttime or timetool:now()
	if type(self.name) ~= "string" then self.name = "" end
	for i,v in ipairs(self.all_attrs) do
		if type(data[v]) == "string" then
			data[v] = cjson.decode(data[v])
		else
			data[v] = nil
		end
		local ok,model = pcall(require,"game.model.role."..v)
		--ngx.log(ngx.ERR,"ok:",ok," v:",v)
		if ok and model and model.is_role_model then
			self[v] = model:new(self,data[v])
		else
			ngx.log(ngx.ERR,model)
		end
	end

	for i,v in ipairs(self.all_attrs) do
		if self[v] then self[v]:init() end
	end
end

function _M:lock()
	while self.lock do
		ngx.sleep(0.1)
	end
	self.lock = true
	return true
end

function _M:unlock()
	self.lock = false
end

function _M:get_id()
	return self.id
end

function _M:get_name()
	return self.name or ""
end

function _M:set_manager(mgr)
	self.mgr = mgr
end

function _M:get_model(model_name)
	return self[model_name]
end

function _M:get_client_data()
	local data = {}
	data.id = self:get_id()
	data.name = self:get_name()
	for i,v in ipairs(self.all_attrs) do
		local model = self:get_model(v)
		if model then
			data[v] = model:get_client_data()
		end
	end
	return data
end

function _M:get_save_data()
	local data = {}
	data.id = self.idx
	data.uid = self:get_id()
	data.rname = self:get_name()
	data.logouttime = self:get_last_request_time()

	for i,v in ipairs(self.all_attrs) do
		local model = self:get_model(v)
		if model then
			data[v] = model:get_save_data()
		else
			data[v] = {}
		end
	end
	return data
end

function _M:saved()
	self.dirty = false
	self.dirty_attrs = {}
	if self.mgr then
		self.mgr:role_changed(self,true)
	end
end

function _M:save()
	if not self.dirty then return true end
	self.mgr:save_role(self:get_id())
	self:saved()
	return true
end

function _M:push(task,data)
	if not self.client then return false end
	local msg = {
		task = task or "role_push",
		status = 0,
		time = timetool:now(),
		data = data
	}
	self.client:push(cjson.encode(msg))
	return true
end

function _M:push_update()
	if not self.all_attrs_hash then
		self.all_attrs_hash = {}
		for i,v in ipairs(self.all_attrs) do
			self.all_attrs_hash[v] = 1
		end
	end

	local attrs = self.dirty_attrs
	if attrs == "all" or not attrs  then attrs = self.all_attrs_hash end
	for v,i in pairs(attrs) do
		if self[v] and self[v].is_role_model then
			self[v]:push_update()
		else
			local task = "data.update"
			local pd = {}
			pd.key = v
			pd.data = self[v]
			self:push(task,pd)
			self.dirty_attrs[v] = nil
		end
	end
	local ltime = timetool:now()
	if not self.last_online_time then self.last_online_time = ltime end
	self.base:add_online_time( ltime - self.last_online_time)
	self.last_online_time = ltime
end

function _M:push_chat(sender,content)
	return self:push("chat",{
		sender = sender.info,
		content = content,
		channel = sender.channel
	})
end

function _M:kick(reason)
	if self.client then
		self:push("kick",reason or "account in another place to log in")
		self.client:close()
		self.client = nil
	end
end

function _M:login(client)
	self:kick()
	self.client = client
	self.client_num = self.client_num or 0
	self.client_num = self.client_num + 1
	self.logouttime = timetool:now()
	self.last_online_time = self.logouttime
end

function _M:logout()
	self.client_num = self.client_num or 0
	self.client_num = self.client_num - 1
	if self.client_num < 1 then
		self.client = nil
	end
	self.logouttime = timetool:now()
end

function _M:is_online()
	if self.client then return true end
	return false
end

function _M:get_last_request_time()
	return self.logouttime or 0
end

function _M:changed(attr)
	self.dirty = true
	if not attr then 
		self.dirty_attrs = 'all'
	elseif self.dirty_attrs ~= 'all' then
		self.dirty_attrs[attr] = 1
	end
	if self.mgr then
		self.mgr:role_changed(self,false)
	end
end

function _M:update()
	if not self.extend then return end
	local config = require "include.config"
	for i,v in pairs(config.update_obj) do
		local upcount = self.extend:update(i)
		if upcount > 0 and self[v.data] and self[v.data][v.fun] then
			self[v.data][v.fun](self[v.data],upcount)
		end
	end
end

function _M:set_name(name)
	self.name = name
	self:changed("name")
end

function _M:is_dead()
	return timetool:now() - self:get_last_request_time() - self.dead_time > 0
end

function _M:get_simple_info()
	if self:is_dead() then return end
	local info = {
		id = self:get_id(),
		name = self:get_name(),
	}
	return info
end

function _M:get_rank_info(rt)
	local info = {}
	info.id = self.id
	info.data = self:get_simple_info()
	info.pt = 0
	return info
end

function _M:get_member_by_channel(channel)
	if type(channel) ~= "number" then return false end
	if channel > 0 then return {channel} end
	if channel == 0 then return 'all' end
	return false
end

function _M:receive_mail(mail)
	
end

function _M:is_in_mail_group(group)
	if not group then return false end
	if group == true then return true end
	return true
end

return _M