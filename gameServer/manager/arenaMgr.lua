-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local CRole = require "game.model.role"
local CDb = require "include.db"
local timetool = require "include.timetool"
local config = require "game.config"
local t_insert = table.insert

local _M = {}
_M.ids = {}
_M.arena ={}
_M.arena_pos ={}
_M.arena_pos_typ ={}

function _M:init_arenas(dead_time)
	local result = self.db:get_all_record({"uid","logouttime","arena"})
	if not result then return false	end
	
	local ct = timetool:now() - (dead_time or 0)
	for i=1,#result do
		self.ids[result[i].uid] = result[i].uid
		if result[i].logouttime == 0 or result[i].logouttime > ct then
			if result[i].arena and result[i].arena.my < config.arena_pos_max then
				self.arena[result[i].uid] = result[i].arena
				self.arena_pos[result[i].uid] = result[i].arena.my
				self.arena_pos_typ[result[i].uid] = 2
			end
		end
	end
	return true	
end

function _M:init(db_config,dead_time)
	self.db = CDb:new(db_config)
	if self:init_arenas(dead_time) then
		self.binit = true
	end
end

function _M:add_arenas(rid,arena)
	if not rid then return false end
	if not arena or type(arena) ~= "table" then return false end
	if arena.my > config.arena_pos_max then return false end
	if not self.ids[rid] then
		self.ids[rid] = rid
		self.arena[rid] = arena
		self.arena_pos[rid] = arena.my
		self.arena_pos_typ[rid] = 2
	end
end

function _M:arenas_changed(rid1,pos1,rid2,pos2)
	if not self.ids[rid1]  or not self.ids[rid2] then return false end
	self.arena_pos[rid1] = pos2
	self.arena_pos[rid2] = pos1
end

function _M:get_arenas_pos(rid)
	return self.arena_pos[rid]
end

function _M:is_palyer(rid)
	if not self.arena_pos_typ[rid] then return false end
	return self.arena_pos_typ[rid]  == 2
end


return _M