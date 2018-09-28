local class = require "include.class"
local deepcopy = require "include.deepcopy"
local s_split = require "include.stringsplit"
local t_insert = table.insert
local t_concat = table.concat

local _M = class()
_M.class = "role.model"
_M.push_name = "model"
_M.changed_name_in_role = nil
_M.is_role_model = true
_M.attrs = {}

_M.is_list = false
_M.child_model = nil
_M.is_key_num = false

function _M:__init(role,data,id,parent,in_parent_name)
	self.role = role
	self.id = id
	data = data or {}
	self.data = {}
	self.parent = parent
	self.in_parent_name = in_parent_name

	if self.is_list then
		self.max_id = 100
		self.child_num = 0
		for k,v in pairs(data) do
			if self.is_key_num then 
				local nk = tonumber(k) 
				if nk then 
					k = nk
					if k > self.max_id then self.max_id = k end
				end
			end
			if self.child_model and self.child_model.new then
				self.data[k] = self.child_model:new(self.role,v,k)
			else
				self.data[k] = v
			end
			self.child_num = self.child_num + 1
		end
	else
		self.data = data
		if type(data) == "table" then
			for k,v in pairs(self.attrs) do
				self.data[k] = data[k] or deepcopy(v)
			end
		else
			ngx.log(ngx.ERR,"self.id:",self.id," data:",data," in_parent_name:",in_parent_name)
		end
	end

	if self.__up_version and type(self.__up_version) == "function" then
		self:__up_version()
	end
end

function _M:__up_version()
end

function _M:init()
end

function _M:join(role,id)
	self.id = id
	self.role = role
end

function _M:get_role()
	return self.role
end

function _M:get_id()
	return self.id
end

function _M:get(id)
	return self.data[id]
end

function _M:set(id,value)
	self.data[id] = value
	self:changed(id)
end

function _M:deep_get(data,fun)
	if not data then return nil end
	local rd = {}
	if type(data) == "table" then
		if data.is_role_model then
			rd = data[fun](data)
		else
			for k,v in pairs(data) do
				rd[k] = self:deep_get(v,fun)
			end
		end
	else
		rd = data
	end
	return rd
end

function _M:get_client_data()
	return self:deep_get(self.data,"get_client_data")
end

function _M:get_save_data()
	return self:deep_get(self.data,"get_save_data")
end

function _M:append(id,obj)
	if not obj or self:get(id) then return false end
	self.data[id] = obj
	if type(id) == 'number' and self.max_id < id then self.max_id = id end
	if obj.is_role_model then
		obj:join(self:get_role(),id)
	end
	self.child_num = self.child_num + 1
	self:changed(id)
	return id
end

function _M:remove(id)
	local obj = self:get(id)
	if not obj then return false end
	self.data[id] = nil
	if obj.is_role_model then
		obj:join(nil,obj:get_id())
	end
	self.child_num = self.child_num - 1
	self:changed(id)
	return obj
end

function _M:on_child_changed(childsname,child_id,child_attrid,child_attrvalue)
	if type(child_attrid) ~= "table" then child_attrid = {child_attrid} end
	t_insert(child_attrid,1,child_id)
	t_insert(child_attrid,1,childsname)
	if self.parent and self.in_parent_name then
		self.parent:on_child_changed(self.in_parent_name,self.id,child_attrid,child_attrvalue)
	else
		if self.role then self.role:changed(self.changed_name_in_role) end
		self.child_changed_attrs = self.child_changed_attrs or {}
		local attrname = t_concat(child_attrid,".")
		self.child_changed_attrs[attrname] = self.child_changed_attrs[attrname] or {}
		for i,v in pairs(child_attrvalue) do
			self.child_changed_attrs[attrname][i] = v
		end
	end
end

function _M:changed(id,bremove)
	if self.parent and self.in_parent_name then
		local push_data = "NIL"
		if id then 
			local value = self:get(id) or "NIL"
			push_data = {[id]=self:deep_get(value,"get_client_data")}
		elseif not bremove then
			push_data = self:get_client_data()
		end
		
		self.parent:on_child_changed(self.in_parent_name,self.id,nil,push_data)
	else
		if self.role then
			self.role:changed(self.changed_name_in_role)
		end
		if id and self.changed_attrs ~= 1 then
			self.changed_attrs = self.changed_attrs or {}
			local value = self:get(id) or "NIL"
			self.changed_attrs[id] = self:deep_get(value,"get_client_data")
		else
			self.changed_attrs = 1
		end
	end
end

function _M:push(task,data)
	if self.role then
		self.role:push(task,data)
	end
end

function _M:push_update()
	if self.changed_attrs then
		local task = "data.update"
		local pd = {}
		pd.key = self.push_name
		if self.id then pd.key = pd.key .. "." .. self.id end
		
		if self.changed_attrs ==  1 then
			pd.data = self:get_client_data()
		else
			pd.data = self.changed_attrs
		end

		self:push(task,pd)
		self.changed_attrs  = nil
	end

	if self.child_changed_attrs then
		for i,v in pairs(self.child_changed_attrs) do
			local task = "data.update"
			local pd = {}
			pd.key = self.push_name
			if self.id then pd.key = pd.key .. "." .. self.id end
			pd.key = pd.key..'.'..i
			pd.data = v
			self:push(task,pd)
		end
		self.child_changed_attrs = nil
	end
	
	if self.is_list and self.child_model and self.child_model.push_update then
		for i,v in pairs(self.data) do
			v:push_update()
		end
	end
end

return _M