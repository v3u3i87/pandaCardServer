-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local CTask = require "game.model.role.task"
local config = require "game.template.task"
local countMgr = require "game.model.countMgr"
local timetool = require "include.timetool"
local CMail = require "game.model.role.mail"

local math_floor = math.floor

local table_insert =table.insert
local table_remove = table.remove

local _M = model:extends()
_M.class = "role.tasklist"
_M.push_name  = "tasklist"
_M.changed_name_in_role = "tasklist"

local cjson = require "include.cjson"

_M.is_list = true
_M.child_model = CTask
_M.is_key_num = true



function _M:__up_version()
	_M.super.__up_version(self)
end

function _M:on_time_up()
	self.tocs = self:init_tocs()
end

function _M:init_tocs()
	return {}
end
--[[function _M:init_tocs()
	local tocs = {}
	for id,task in pairs(self.data) do
		local proto = config:get(id)
		if proto and proto.type and proto.subtype  then  -- and not config:check_arry(tocs[proto.type],proto.subtype) 
		--if task:get_status() ~= 3 then
			tocs[proto.type] = tocs[proto.type] or {};
			table_insert(tocs[proto.type],proto.subtype)
		--end
		end
	end
	ngx.log(ngx.ERR,"tocs:",cjson.encode(tocs))
	return tocs
end]]--

function _M:init()
	--ngx.log(ngx.ERR,self.class,":22222222=:",self.push_name)
	self.triggerlist = {}
	self.chains = {}
	self.ids = {}
	for id,v in pairs(self.data) do
		local trigger_id = config:get_trigger_id(id)
		if trigger_id then
			self.triggerlist[trigger_id] = self.triggerlist[trigger_id] or {}
			table_insert(self.triggerlist[trigger_id],v)
		end
		local chain_id = config:get_chain_id(id)
		if chain_id and chain_id > 0 then self.chains[chain_id] = id end
		self.ids[id] = 1
	end
	self:refresh()

end

function _M:get_client_data()
	local data =  _M.super.get_client_data(self)
	data.p = self.tocs
	data.fundnum = countMgr:get_type_count(countMgr.type.fund)
	return data
end

function _M:add_tasks()
	local ids = config:get_ids(self.chains,self.ids)
	for i,id in ipairs(ids) do
		if not self.data[id] and config:check_condition(self.role,config:get_active_condition(id)) then
			self:append(id)
		end
	end
end

function _M:refresh()
	for id,task in pairs(self.data) do
		if task:failed() then
			if not config:is_task_end(id) then
				if not self:accept_next_task(task,id) then
					task:set_s(4)
				end
			else self:remove(id) end
		else
			local rs = task:trigger(0)
			if rs then self:accept_next_task(task,id) end
		end
	end
	self:add_tasks()

	local last_tocs = self.tocs
	self.tocs = self:init_tocs()
	if last_tocs ~= self.tocs then
		self:update_p(self.tocs)
	end

	local last_fundnum = self.fundnum
	self.fundnum = countMgr:get_type_count(countMgr.type.fund)
	if last_fundnum ~= self.fundnum then
		self:update_fundnum(self.fundnum)
	end

end

function _M:on_level_up()
	self:init()
end

function _M:on_vip_up()
	--self:refresh()
end
function _M:on_time_up()
	self:init()
end
function _M:update_p()
end
function _M:update_fundnum()
end

function _M:new_task(pid)
	return CTask:new(self.role,{p=pid,g=0,s=1},pid)
end

function _M:append(pid,ltime)
	self.max_id = self.max_id + 1
	local task = self:new_task(pid,ltime)
	_M.super.append(self,pid,task)
	local trigger_id = config:get_trigger_id(pid)
	self.triggerlist[trigger_id] = self.triggerlist[trigger_id] or {}
	table_insert(self.triggerlist[trigger_id],task)
	local chain_id = config:get_chain_id(pid)
	if chain_id and chain_id >0 then self.chains[chain_id] = pid end
	self.ids[pid] = 1
	task:trigger(0)
end

function _M:remove(id)
	local trigger_id = config:get_trigger_id(id)
	if self.triggerlist[trigger_id] then
		for k,v in ipairs(self.triggerlist[trigger_id]) do
			if v == id then  table_remove(self.triggerlist[trigger_id],k) end
		end
	end
	local chain_id = config:get_chain_id(id)
	if chain_id then self.chains[chain_id] = nil end
	self.ids[id] = nil
	_M.super.remove(self,id)
end

function _M:finish(id)
	local task = self:get(id)
	if not task then return false end
	local profit,newtask = task:finish()
	if self.role and profit then
		self.role:gain_resource(profit)
	end
	self:accept_next_task(task,id,newtask)
	return true,profit
end

function _M:accept_next_task(task,id,newtask)
	local set_newtask =false
	if not newtask then newtask = config:get_next_task(id,task.data.g) end
	if newtask and newtask > 0 and config:check_condition(self.role,config:get_active_condition(newtask)) then

		if newtask == id then
		else
			self:remove(id)
			if math_floor(newtask / 1000) == config.total_pay_day then self:append(newtask,timetool:get_hour_time(0))
			else self:append(newtask) end
		end
		set_newtask =true
	end
	return set_newtask
end

function _M:trigger(trigger_id,value,...)
	if not self.triggerlist[trigger_id] then return false end
	for id,task in ipairs(self.triggerlist[trigger_id]) do
		local rs = task:trigger(value,...)
--		ngx.log(ngx.ERR,"trigger_id:",trigger_id," id:",id, "task.p",task.data.p)
		local task_id = task.data.p
		if rs then self:accept_next_task(task,task_id,newtask)
		elseif config:is_send_mail(task_id) and task:can_finish() then self:send_mail(task_id,task)	end
	end
end

function _M:get_schedule(id)
	local task = self:get(id)
	if not task then return 0 end
	return task:get_schedule()
end

function _M:send_mail(id,task)
	local mail = {
		t = 1,
		s = 0,
		h = config:get_name(id) or "",
		c = config:get_des(id) or "",
		p = config:get_profit(id) or {},
	}
	self.role:receive_mail(CMail:new(nil,mail))
	local profit,newtask = task:finish()
	self:accept_next_task(task,id,newtask)

	if math_floor(id  / 1000) == config.total_pay_day then self:trigger(config.trigger_type.pay_daynum,1) end
end

return _M