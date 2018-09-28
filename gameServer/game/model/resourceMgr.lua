-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local timetool = require "include.timetool"
local roleMgr = require "manager.roleMgr"
local mailMgr = require "manager.mailMgr"
local CDb = require "include.db"
local table_insert = table.insert
local cjson = require "include.cjson"

local _M = {}
_M.resource_stage_time = 60
_M.resource_begin_time = 10 *3600
_M.resource_end_time = 23 *3600
_M.update_time = {
	{h=13,m=5,s=0},
	{h=18,m=25,s=0},
	{d=-1,h=13,m=5,s=0},
}
_M.data = {
	reward = config.template.plunderstage,
	stage ={},
	rewardtime =0,
}

function _M:init(db_config)
	self.data.stage ={}
	self.db = CDb:new(db_config)
	local result = self.db:get_all_record()
	if not result then return false end
	if #result <= 0 then result = self:cretat_table() end
	local find_hid = false
	for i=1,#result do
		local v = result[i]
		local stageone = {}
		stageone.pid = v.pid
		stageone.hid = v.hid
		stageone.state = v.state
		stageone.id = i
		if self.data.reward[v.pid] then
			stageone.reward = config:change_cost(self.data.reward[v.pid].reward)
			stageone.need_stage = self.data.reward[v.pid].start
		end
		self.data.stage[v.pid] = stageone
		if stageone.hid > 0 then find_hid = true end
	end

	self:set_rewared_time(nil,find_hid)
	self:create_all_stage_info()
	return true
end

function _M:cretat_table()
	local result ={}
	for i,v in ipairs(self.data.reward) do
		if v.type == 2 then
			local rec = {
				pid = v.id,
				hid = 0,
				state = 0,
			}
			self.db:append(rec)
			table_insert(result,rec)
		end
	end
	self.db:save()
	return result
end
function _M:set_rewared_time(ltime,is_init)
	if not ltime then ltime = timetool:now() end
	local reward1 = timetool:get_next_time(ltime,self.update_time[1])
	local reward2 = timetool:get_next_time(ltime,self.update_time[2])
	if is_init then
		if ltime < reward1 then 
			self:clear_data()
			self.data.rewardtime = reward1 
		elseif ltime > reward1 and ltime < reward2 then self.data.rewardtime = reward1
		elseif ltime >= reward2 then self.data.rewardtime = reward2
		end
	else
		if ltime < reward1 then self.data.rewardtime = reward1 
		elseif ltime >= reward1 and ltime < reward2 then self.data.rewardtime = reward2
		else self.data.rewardtime = timetool:get_next_time(ltime,self.update_time[3])
		end
	end
end

function _M:get_stage_data(pos)
	return self.data.stage[pos]
end

function _M:set_stage_hid(pos,hid)
	self.data.stage[pos].hid = hid
	self:create_all_stage_info()
end
function _M:get_stage_hid(pos)
	return self.data.stage[pos].hid
end

function _M:clear_hid(pos,hid)
	for i,v in pairs(self.data.stage) do
		if i ~= pos and v.hid == hid then v.hid = 0 end
	end
end


function _M:set_stage_state(pos,value,hid)
	if not self.data.stage[pos] then return false end
	self.data.stage[pos].state = value
	self.data.stage[pos].state_time = timetool:now()
	if hid and hid >0 then 	
		self.data.stage[pos].hid= hid 
		self.data.stage[pos].t= timetool:now() 
		self:clear_hid(pos,hid)
	end
	local rs ={
		id = self.data.stage[pos].id,
		pid = pos,
		hid = self.data.stage[pos].hid,
		state = self.data.stage[pos].state,
		t = self.data.stage[pos].state_time
	}

	self.db:update(rs)
	self.db:save()
	self:create_all_stage_info()
end

function _M:clear_data()
	for i,v in pairs(self.data.stage) do
		local rs ={
			id = v.id,
			pid = v.pid,
			hid = 0,
			state = 0,
		}
		self.db:update(rs)
	end
	self.db:save()
	self:create_all_stage_info()
end

function _M:is_stage(pos)
	return self.data.stage[pos].state == 0
end

function _M:send()
	local ct = timetool:now()
	if self.data.rewardtime < ct then
		local title = "城镇占领奖励"
		local content = "你成功占领了敌方的根据地，为盟军辎重做出了重大贡献，司令部特予以奖励，以资鼓励！"

		for id,v in pairs(self.data.stage) do
			if v.hid >0 then
				local role = roleMgr:get_role(v.hid)
				if role then
					mailMgr:send_mails(0,4,title,content,v.reward,{[1]=v.hid})
				end
			end
		end
		self:set_rewared_time(ct)
		self:clear_data()
	end
	local ctime = ct - timetool:get_hour(0)
	if ctime >=self.resource_begin_time and ctime <self.resource_end_time then
		for id,v in pairs(self.data.stage) do
			if v.state >0 and ct - v.state_time > self.resource_stage_time  then v.state =0 end
		end
	end
end

function _M:create_all_stage_info( )
	self.all_info ={}
	for i,v in pairs(self.data.stage) do
		local one_data ={}
		one_data.id = v.pid
		one_data.hid =v.hid
		one_data.t = v.t or 0
		self.all_info[one_data.id] = one_data
	end
	return self.all_info
end

function _M:get_all_stage_info()
	--self:create_all_stage_info()
	local data = self.all_info or {}
	for k,v in pairs(data) do
		local role = roleMgr:get_role(v.hid)
		if role then
			v.name = role.name
			v.inc = role.resource:get_inc()

		end
	end
	return data
end
return _M