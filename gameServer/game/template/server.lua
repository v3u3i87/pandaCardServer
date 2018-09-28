-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local timetool = require "include.timetool"
local table_insert = table.insert

local _M = {}
_M.data = {
	serverlist = config.template.serverlist,
}

function _M:check_data(name,val1)
	if not self.data[name] then 
		config:init_config(name,val1)
		self.data[name] = config.template.serverlist
	end
end

function _M:get_serlist()
	self:check_data("serverlist","id")
	local serverlist = {}
	local ltime = timetool:now()
	for i,v in pairs(self.data.serverlist) do
		local t = timetool:format_time(v.begintime)
		if ltime >= t then table_insert(serverlist,v) end
	end
	return serverlist
end

function _M:get_notify()
	--self:check_data("notify","id")
	return "你懂的"
end

return _M