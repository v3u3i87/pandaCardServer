-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local CDb = require "include.db"
local timetool = require "include.timetool"
local swapHashKV = require "include.swaphashkv"
local config = require "game.config"
local mailMgr = require "manager.mailMgr"
local rankMgr = require "manager.rankMgr"
local cjson = require "include.cjson"

local _M = {}
_M.reward = {}

function _M:init(db_config)
	self.db = CDb:new(db_config)
	for key,value in pairs(config.reward) do
		local rs = self.db:get_max_value("time","type",value.type)
		if rs == 0 then rs = timetool:now() end
		self.reward[value.type] = {}
		self.reward[value.type].last = rs
		self.reward[value.type].update_time = value.update_time
		self.reward[value.type].next = timetool:get_next_time(self.reward[value.type].last,self.reward[value.type].update_time)
	end
end

function _M:send()
	for key,value in pairs(config.reward) do
		if self.reward[value.type].next <= timetool:now() then 
			local rank = rankMgr:get(value.rank_type)
			if rank then
				local reward = require ("game.template." .. (value.template or key))
				local get_ids_func = rank.get_range_ids
				if value.get_ids_func then get_ids_func = rank[value.get_ids_func] end
				local range,profit
				if reward then
					range,profit = reward:get_range_reward()
					for k,v in ipairs(range) do
						local ids = get_ids_func(rank,v[1],v[2])
						if ids and #ids > 0 then 
							local content = value.content
							if value.content2 then content= content .. v[1] .. "-" .. v[2] .. value.content2   end
							mailMgr:send_mails(0,value.type,value.title,content,profit[k],ids)
						end
					end
				end
				
				local rec ={}
				rec.type = value.type
				rec.time = self.reward[value.type].next
				rec.sendtime = timetool:now()
				rec.data = cjson.encode({type=value.type,rank_type=value.rank_type,range=range,profit=profit})
				self:append(rec)
				self.reward[value.type].last = self.reward[value.type].next
				self.reward[value.type].next = timetool:get_next_time(self.reward[value.type].last,self.reward[value.type].update_time)
				if value.clear then rankMgr:del_rank(value.rank_type) end
			end
		end
	end
end

function _M:append(rec)
	self.db:append(rec)
	self.db:clean(true)
end

return _M