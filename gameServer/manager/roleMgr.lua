-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local CDb = require "include.db"
local timetool = require "include.timetool"
local t_insert = table.insert
local swapHashKV = require "include.swaphashkv"

local _M = {}
_M.roles = {}
_M.ids = {}
_M.ids_hash = {}
_M.names = {}
_M.id_names = {}
_M.changed_roles = {}

function _M:init_names()
	local result = self.db:get_all_record({"id","uid","rname"})
	if not result then return false	end
	
	for i=1,#result do
		self.ids_hash[result[i].uid] = result[i].id
		t_insert(self.ids,result[i].uid)
		if result[i].rname and result[i].rname ~= "" then
			self.names[result[i].rname] = result[i].uid
		end
	end
	self.id_names = swapHashKV(self.names)
	return true	
end

function _M:init(db_config,all_attributes,CRole)
	self.db = CDb:new(db_config)
	self.all_attributes = all_attributes
	self.CRole = CRole or require "include.role"
	if self:init_names() then
		self.binit = true
	end
end

function _M:load_role(rid)
	if not rid or rid <=0  then return false end
	if not self.roles[rid] then
		local role_data = {uid = rid}
		if not self.ids_hash[rid] then
			if not self.db:append(role_data) then return false end
			self.ids_hash[rid] = role_data.id
			t_insert(self.ids,rid)
		else
			--ngx.log(ngx.ERR,"rid:",rid)
			role_data = self.db:get_record(self.ids_hash[rid])
		end
		--local cjson = require "include.cjson"
		--ngx.log(ngx.ERR,"role_data:",cjson.encode(role_data))
		self.roles[rid] = self.CRole:new(rid,role_data)
		self.roles[rid]:set_manager(self)
		--ngx.log(ngx.ERR,"self.roles[rid].id:",self.roles[rid].id)
	end
	
	local bcreate = false
	if self.roles[rid]:get_name() ~= "" then
		bcreate = true
	end
	
	return self.roles[rid],bcreate
end

function _M:get_role(rid)
	self:load_role(rid)
	return self.roles[rid]
end

function _M:get_role_in_cache(rid)
	return self.roles[rid]
end

function _M:get_role_id(rname)
	return self.names[rname]
end

function _M:get_role_byname(rname)
	local rid = self.names[rname]
	if not rid then return false end
	return self:get_role(rid)
end

function _M:get_all_role_ids()
	return self.ids
end

function _M:get_all_role_ids_hash()
	return self.ids_hash
end

function _M:get_role_name(rid)
	return self.id_names[rid] or ""
end

function _M:role_rename(rid,old_name,new_name)
	if old_name then 
		self.names[old_name] = nil
		self.id_names[rid] = nil
	end
	self.names[new_name] = rid
	--self.id_names[new_name] = rid
	self.id_names[rid] = new_name
end

function _M:is_name_exist(name)
	if self.names[name] then return true end
	return false
end

function _M:role_changed(role,bsave)
	if bsave then
		self.changed_roles[role:get_id()] = nil
	else
		self.changed_roles[role:get_id()] = role
	end
end

function _M:clean(force)
	if force then
		self:save()
		for rid,role in pairs(self.roles) do
			if not role:is_online() then
				self.roles[rid] = nil
			end
		end
	else
		local ct = timetool:now() - 24 * 3600
		for rid,role in pairs(self.roles) do
			if not self.changed_roles[rid] and not role:is_online() and role:get_last_request_time() < ct then
				self.roles[rid] = nil
			end
		end
	end
	self.db:clean(force)
end

function _M:save_role(rid)
	if not self.roles[rid] then return true end
	self.db:update(self.roles[rid]:get_save_data())
	return self.db:save()
end

function _M:save(limit)
	local st = timetool:now()
	local srs = {}
	local srs_num = 0
	for rid,role in pairs(self.changed_roles) do
		self.db:update(role:get_save_data())
		t_insert(srs,role)
		srs_num = srs_num + 1
		if limit and srs_num == limit then break end
	end
	if srs_num == 0 then return true,0 end
	local result = self.db:save()
	if not result then 
		ngx.log(ngx.ERR,"=====>save role data error")
		return false
	else
		for i,role in ipairs(srs) do
			role:saved()
		end
	end
	ngx.log(ngx.NOTICE,"=====>save role data:" , srs_num ,"  use time:", timetool:now()-st, "ms ")
	return true,srs_num
end

function _M:get_chat_sender(role,channel)
	local sender = {}
	sender.channel = channel
	if role then
		sender.info = role:get_simple_info()
	else
		sender.info = {
			id = 0,
			name = "system",
			lev = 999
		}
	end

	local mem = nil
	if role then 
		mem = role:get_member_by_channel(channel)
	elseif channel == 0 then 
		mem = 'all'
	end

	return sender,mem
end

function _M:send_chat_msg(role,channel,content)
	local sender,mem = self:get_chat_sender(role,channel)
	if not mem then return false end
	ngx.timer.at(0,
		function(premature,sender,content,mem,roleMgr)
			if mem == 'all' then
				for rid,torole in pairs(roleMgr.roles) do
					if torole:is_online() then
						torole:push_chat(sender,content)
					end
				end
			else
				for i,rid in ipairs(mem) do
					local torole = roleMgr:get_role_in_cache(rid)
					if torole and torole:is_online() then
						torole:push_chat(sender,content)
					end
				end
			end
		end,
		sender,content,mem,self
	)
	return true
end

function _M:kick_role(roles)
	roles = roles or self.roles
	for id,role in pairs(self.roles) do
		if role and role:is_online() then
			role:kick("service close")
			role:logout()
		end
	end
end

return _M