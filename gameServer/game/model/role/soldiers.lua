-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local CSoldier = require "game.model.role.soldier"
local config = require "game.template.soldier"
local bconfig = require "game.config"
local taskConfig = require "game.template.task"

local _M = model:extends()
_M.class = "role.soldiers"
_M.push_name  = "soldiers"
_M.changed_name_in_role = "soldiers"
_M.is_list = true
_M.child_model = CSoldier
_M.is_key_num = true

function _M:__up_version()
	_M.super.__up_version(self)	
end

function _M:init()

end

function _M:conscripts(id,num)
	local soldier = self.data[id]
	local tn = num
	if not soldier then
		soldier = CSoldier:new(self.role,nil,id)
		_M.super.append(self,id,soldier)
		num = num - 1
	end
	if num > 0 then	soldier:append(num) end
	return id
end

function _M:retire(id,num)
	if not self.data[id] then return false end
	local soldier = self.data[id]
	if not soldier:consume(num) then return false end
	if soldier:is_empty() then
		_M.super.remove(self,id)
	end
	return soldier
end

function _M:get(id)
	local pid = config:get_initid(id)
	local soldier = self.data[pid]
	if not soldier then return nil end

	if pid ~= id then
		local hero_type = config:get_herotype(id)
		if hero_type == config.hero_type.mbreak and soldier:get_mrank() == 0 then return nil 
		elseif hero_type == config.hero_type.gz and soldier:get_superquality() < 10 then return nil end
	end
	return soldier
end

function _M:gain_more(profit)
	for id,num in pairs(profit) do
		self:conscripts(id,num)
	end
end

function _M:consume_more(cost)
	for id,num in pairs(cost) do
		self:retire(id,num)
	end
end

function _M:reborn(id)
	local soldier = self:get(id)
	if not soldier then return false end
	local profit = soldier:reborn()
	if self.role and profit then
		self.role:gain_resource(profit)
	end
	return profit
end

function _M:reclaim(id,me,num)
	local soldier = self:get(id)
	if not soldier then return false end
	local profit = soldier:reclaim(me,num)
	if self.role and profit then
		self.role:gain_resource(profit)
	end
	if soldier:is_empty() then
		_M.super.remove(self,id)
	end

	return profit
end

function _M:reset_quality_bless()
	for i,v in pairs(self.data) do
		v:reset_quality_bless()
	end
end

function _M:get_quality(id)
	local soldier = self:get(id)
	if not soldier then return 0 end
	return soldier:get_quality()
end

function _M:get_num(params)
	if not params or #params == 0 then return self.child_num end
	local n = 0
	for i,v in pairs(self.data) do
		if taskConfig:check_condition(self.role,params,i) then n = n + 1 end
	end
	return n
end

function _M:get_max_level()
	local ms = 0
	for id,soldier in pairs(self.data) do
		local s = soldier:get_level()
		if s > ms then ms = s end
	end
	return ms
end

function _M:push_update()
	if self.changed_attrs and self.role and self.role.tasklist then
		self.role.tasklist:trigger(taskConfig.trigger_type.soldier_num)
	end
	_M.super.push_update(self)
end

return _M