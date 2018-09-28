-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local CDb = require "include.db"
local config = require "game.config"
local timetool = require "include.timetool"
local rankMgr = require "manager.rankMgr"
local roleMgr = require "manager.roleMgr"

local _M = {}
_M.soldiers = {}
_M.update_time = {d=-1,h=21,m=0,s=0}

function _M:init(db_config)
	self.db = CDb:new(db_config)
	local result = self.db:get_all_record()
	if not result then return false	end
	for i=1,#result do
		local v = result[i]
		self.soldiers[v.soldier_id] = v
	end
	
	for id,v in pairs(config.template.hero) do
		config.rank_type["soldier_"..id] = "soldier_"..id
		config.rank["soldier_"..id] = {
			type = "soldier_"..id,
			asc = false
		}
		config.reward["soldier_"..id] = {
			type = "soldier_"..id,
			rank_type = "soldier_"..id,
			title = "名将榜奖励",
			content = "你在士兵培养上有独到的见解，司令部特给予优秀的指挥官予以奖励！以资鼓励！",
			template = "general",
			update_time = self.update_time,
		}
		rankMgr:append_new_rank("soldier_"..id,false)
	end
	
	if not self.soldiers[0] then 
		self:append(0)
		self.soldiers[0].first_record = timetool:get_next_time(timetool:now(),self.update_time)
		self.db:update(self.soldiers[0])
	end
	
	return true
end

function _M:append(soldier_id)
	if not self.soldiers[soldier_id] then
		local v = {}
		v.soldier_id = soldier_id
		v.first_record = 0
		v.second_record = 0
		v.third_record = 0
		self.db:append(v)
		self.soldiers[soldier_id] = v
	end
end

function _M:record_first(soldier_id,role_id)
	self:append(soldier_id)
	if self.soldiers[soldier_id].first_record ~= 0 then return false end
	self.soldiers[soldier_id].first_record = role_id
	self.db:update(self.soldiers[soldier_id])
	return true
end

function _M:record_second(soldier_id,role_id)
	self:append(soldier_id)
	if self.soldiers[soldier_id].second_record ~= 0 then return false end
	self.soldiers[soldier_id].second_record = role_id
	self.db:update(self.soldiers[soldier_id])
	return true
end

function _M:record_third(soldier_id,role_id)
	self:append(soldier_id)
	if self.soldiers[soldier_id].third_record ~= 0 then return false end
	self.soldiers[soldier_id].third_record = role_id
	self.db:update(self.soldiers[soldier_id])
	return true
end

function _M:record(soldier_id,pos,role_id)
	if pos == 1 then return self:record_first(soldier_id,role_id)
	elseif pos == 2 then return self:record_second(soldier_id,role_id)
	elseif pos == 3 then return self:record_third(soldier_id,role_id)
	end
end

function _M:save()
	self.db:clean(true)
end

function _M:get_soldier_can_record_pos(soldier_id,role_id)
	self:append(soldier_id)
	local index = false
	if self.soldiers[soldier_id].first_record == 0 then index = 1
	elseif self.soldiers[soldier_id].second_record == 0 then index = 2
	elseif self.soldiers[soldier_id].third_record == 0 then index = 3
	end
	if index then
		if self.soldiers[soldier_id].first_record ~= role_id and self.soldiers[soldier_id].second_record ~= role_id and self.soldiers[soldier_id].third_record ~= role_id then
		return index end
	end
	return false
end

function _M:get_soldier_info(soldier_id)
	self:append(soldier_id)
	local info = {}
	info.id = soldier_id
	info.first = roleMgr:get_role_name(self.soldiers[soldier_id].first_record)
	info.second = roleMgr:get_role_name(self.soldiers[soldier_id].second_record)
	info.third = roleMgr:get_role_name(self.soldiers[soldier_id].third_record)
	return info
end

function _M:send()
	local ct = timetool:now()
	local nt = self.soldiers[0].first_record
	if nt < ct then
		for id,v in pairs(config.template.hero) do
			local rank_type = "soldier_" .. id
			local rank = rankMgr:get(rank_type)
			if rank then
				local ids = rank:get_range_ids(1,5)
				for i,rid in ipairs(ids) do
					local role = roleMgr:get_role(rid)
					if role then
						local soldier = role.soldiers:get(id)
						if soldier then soldier:get_badge(nt) end
					end
				end
			end
		end
		
		nt = timetool:get_next_time(nt,self.update_time)
		self.soldiers[0].first_record = nt
		self.db:update(self.soldiers[0])
	end
end

return _M