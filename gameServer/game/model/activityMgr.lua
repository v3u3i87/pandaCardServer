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

function _M:init(db_config)
	self.data.stage ={}
	self.db = CDb:new(db_config)
	local result = self.db:get_all_record()
	if not result then return false end
	local find_hid = false
	for i=1,#result do
		local v = result[i]
		local activity = {}
		activity.typ = v.typ
		activity.count = v.count
		activity.endtime = v.endtime
		self.data.activity[v.typ] = activity
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


function _M:add_type_data(typ,count,endtime)
	if not self.data.activity[typ] then
		local activity = {}
		activity.typ = typ
		activity.count = count
		activity.endtime = endtime
		self.data.activity[typ] = activity
	else
		self.data.activity[typ].count = self.data.activity[typ].count + count
	end
end

function _M:send()
	local ct = timetool:now()
	local activity = {}
	local change = false
	for i,v in pairs(self.data.activity) do
		if v.endtime > ct then activity[i] = v 
		else 
			change = true
			v = nil
		end
	end
	self.data.activity = activity
end

function _M:get_all_activity_id_info(id)
	return self.data.activity[id] or  {}
end
return _M