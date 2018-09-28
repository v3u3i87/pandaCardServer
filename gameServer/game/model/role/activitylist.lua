-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local CTask = require "game.model.role.task"
local CActivityTask = CTask:extends()

--CActivityTask.class = "task"
CActivityTask.push_name  = "activitylist"
CActivityTask.changed_name_in_role = "activitylist"

local CTasklist = require "game.model.role.tasklist"
local config = require "game.template.task"

local cjson = require "include.cjson"

local table_insert =table.insert
local _M = CTasklist:extends()
_M.class = "role.activitylist"
_M.push_name  = "activitylist"
_M.changed_name_in_role = "activitylist"

_M.child_model = CActivityTask
local math_floor = math.floor
local timetool = require "include.timetool"

function _M:__up_version()
end

function _M:add_tasks()
	local ids = config:get_ids(self.chains,self.ids,true)
	--ngx.log(ngx.ERR,"ids:",cjson.encode(ids))
	for i,id in ipairs(ids) do
		if not self.data[id] and config:check_condition(self.role,config:get_active_condition(id),id) then
			self:append(id)
		end
	end
end

function _M:new_task(pid,ltime)
	if ltime and ltime >0 then CActivityTask:new(self.role,{p=pid,g=0,s=1},pid) end
	return CActivityTask:new(self.role,{p=pid,g=0,s=1,lt = ltime},pid)
end

--[[function _M:update()
	self:refresh()
end]]--

function _M:on_level_up()
	self:init()
end
function _M:on_vip_up()
	self:init()
end

function _M:init_tocs()
	return config:init_tocs(self.role,0,0,self:get_display_ids())
end

function _M:update_p(p)
	local data ={}
	data.key="activitylist"
	data.data = {}
	data.data.p = p
	self.role:push("data.update",data)
end

function _M:update_fundnum(fundnum)
	local data ={}
	data.key="activitylist"
	data.data = {}
	data.data.fundnum = fundnum
	self.role:push("data.update",data)
end

function _M:get_display_ids()
	local ids = {}
	for id,v in pairs(self.ids) do
		local task =self.data[id]
		if task and (task.data.s == 1 or task.data.s ==2 ) then ids[id] = 1 end
	end
	return ids
end

function _M:finish(id,pos,num)
	local task = self:get(id)
	if not task then return false end
	local profit,newtask = task:finish(pos,num)
	if self.role and profit then
		self.role:gain_resource(profit)
	end
	if math_floor(id  / 1000) == config.open_online_time then self.role.base:set_open_online_time()
	end

	if not self:accept_next_task(task,id,newtask) then 
		local pass,p = config:check_p(self.tocs,id,self.role,self:get_display_ids())
		if not pass then 
			self:update_p(p) 
		end
	end
	if config:is_act_opet(id) then
		if newtask and newtask >0 then	self.role.base:add_act_opet(id) 
		else self.role.base:add_act_opet(id,0) end 
	 end

	return true,profit
end

function _M:get_activity_open_day(id)
	return config:get_activity_open_day(id)
end

function _M:get_activity_Interval_day(id)

	if not self.data[id] or not self.data[id].data.lt then return 0 end
	return math_floor( (timetool:now() - self.data[id].data.lt)/timetool.one_day )
end

return _M