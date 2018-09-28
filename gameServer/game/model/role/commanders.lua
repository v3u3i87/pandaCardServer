-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local CCommander = require "game.model.role.commander"
local commander_config = require "game.template.commander"

local _M = model:extends()
_M.class = "role.commanders"
_M.push_name  = "commanders"
_M.changed_name_in_role = "commanders"

_M.is_list = true
_M.child_model = CCommander
_M.is_key_num = true

function _M:__up_version()
	_M.super.__up_version(self)
end

function _M:init()

end

function _M:choose_commander(id)
	if not id then id = 1 end
	local p,w= commander_config:get_choose_commander(id)
	if self.child_num == 0 then 
		local commander = CCommander:new(self.role,{p=p,w=w})
		commander:go_battle()
		self:conscripts(commander)
	end
end


function _M:get_commanders(pid,mrank)
	local commanders = {}
	local num = 0
	for id,commander in pairs(self.data) do
		if commander:get_pid() == pid then
			if not mrank or mrank == commander:get_mrank_lev() then
				num = num + 1
				commanders[id] = commander
			end
		end
	end
	
	return num,commanders
end

function _M:conscripts(commander)
	if not commander or commander.class ~= "commander" then return false end
	self.max_id = self.max_id + 1
	_M.super.append(self,self.max_id,commander)
	return self.max_id
end

function _M:retire(id)
	if not self.data[id] then return false end
	_M.super.remove(self,id)
	return commander
end

function _M:gain_more(profit)
	for id,commander in pairs(profit) do
		self:conscripts(commander)
	end
end

function _M:consume_more(cost)
	for id,commander in pairs(cost) do
		self:retire(id)
	end
end

function _M:check_weapon()
	for i,v in pairs(self.data) do
		v:check_weapon()
	end
end

function _M:reset_mrank_bless()
	for i,v in pairs(self.data) do
		v:reset_mrank_bless()
	end
end

function _M:get_p()
	local p = nil
	for i,commander in pairs(self.data) do
		if commander.data.j == 1 then
			p = commander.data.p
			break
		end
	end
	return p
end

function _M:get_base_skill_level()
	for i,commander in pairs(self.data) do
		if commander then
			return commander.data.s[101] or 0
		end
	end
end


return _M