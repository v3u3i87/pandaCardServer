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

_M.data = {
	activity ={},
}

_M.type={
	fund = 1,
}

_M.funs={
	[1] = {	model = "fund",	count = {30,100,300}},
}


function _M:init(db_config)
	self.data.stage ={}
	self.db = CDb:new(db_config)
	local result = self.db:get_all_record()
	if not result then return false end
	local find_hid = false
	for i=1,#result do
		local v = result[i]
		if v and v.id >0 then
			local activity = {}
			activity.typ = v.id
			activity.count = v.count or 1
			activity.endtime = v.endtime
			self.data.activity[v.id] = activity
		end
	end

	return true
end

function _M:get_type_data(typ)
	return self.data.activity[typ]
end

function _M:get_type_count(typ)
	if not self.data.activity[typ] then return  0 end 
	return self.data.activity[typ].count
end


function _M:set_type_count(typ,num)
	self:add_type_data(typ,num,0,true)
end

function _M:add_type_data(typ,num,endtime,set)
	if not num then num = 1 end
	local append =false
	if not self.data.activity[typ] then
		local activity = {}
		activity.typ = typ
		activity.count = num
		activity.endtime = endtime
		self.data.activity[typ] = activity
		append =true
	else
		if set then self.data.activity[typ].count = num
		else self.data.activity[typ].count = (self.data.activity[typ].count or 0) + num
		end
	end
	local rec = {
		id = self.data.activity[typ].typ,
		count = self.data.activity[typ].count,
		endtime = self.data.activity[typ].endtime
	}
	if append then 	self.db:append(rec)
	else self.db:update(rec) end
	self.db:save()

	if typ == self.type.fund then
		local refresh =false
		for i=1,#self.funs[typ].count do
			if self.data.activity[typ].count == self.funs[typ].count[i] then	
				refresh =true	
				break
			end
		end
		if refresh then
			for k,role in pairs(roleMgr.roles) do
				if role and role.base and role.base:is_fund() then role.activitylist:refresh() end
			end
		end
	end
end

function _M:send()
	local ct = timetool:now()
	local activity = {}
	local change = false
	for i,v in pairs(self.data.activity) do
		if (v.endtime >0 and v.endtime > ct ) or v.endtime == 0 then activity[i] = v end
	end
	self.data.activity = activity
end

function _M:get_all_activity_id_info(id)
	return self.data.activity[id] or  {}
end
return _M