-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local class = require "include.class"
local config = require "game.config"
local timetool = require "include.timetool"
local stage_config = require "game.template.stage"
local math_random = math.random
local math_randomseed = math.randomseed
local math_floor = math.floor

local _M = class()

function _M:__init(role)
	self.role = role
end

function _M:login()
	self.start_time = timetool:now()
end

function _M:logout()
	self.start_time = nil
end

function _M:appear()
	local box = {}
	local stage_id = self.role.base:get_stage() 
	local stage = stage_config:get(stage_id)
	if not stage then box[config.resource.money] = 1000
	else box[config.resource.money] = math_floor(stage[2].offlinegold / 6 ) end
	return box
end

function _M:test()
	if not self.start_time then return end
	local ct = timetool:now()
	if ct - self.start_time < config.supplybox.start then return end
	local appear = false
	if not self.last_appear then
		appear = true
	else
		local dt = ct - self.last_appear
		if dt < config.supplybox.interval[1] then return end
		if dt > config.supplybox.interval[2] then
			appear = true
		end
		math_randomseed(timetool:get_random_seed())
		if math_random(1,100) > 50 then
			appear = true
		end
	end
	if appear then
		self.last_appear = ct
		self.box = self:appear()
		return self.box
	end
end

function _M:open()
	if not self.role or not self.box or not self.last_appear then return false end
	self.role:gain_resource(self.box)
	local box = self.box
	self.box = nil
	return box
end

return _M