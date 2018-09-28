-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local s_sub = string.sub

local _M = {}
_M.data = config.template.stage
_M.stagetype  =2

function _M:get(id)
	return self.data[id]
end

function _M:exist_level(id,isboss)
	local stage = self:get(id)
	--local lv = isboss and 2 or 1
	if stage and stage[_M.stagetype] then return true end
	return false
end

function _M:get_next(id)
	local nid = tonumber(s_sub(id,6)) + 1
	if nid < 10 then return "STAGE00" .. nid end
	if nid < 100 then return "STAGE0" .. nid end
	return "STAGE" .. nid
end

function _M:get_fightpoint(id,lev)
	return 100
end

function _M:get_profit(id,isboss,wins)
	local stage = self:get(id)
	--local lev = isboss and 2 or 1
	local lev =_M.stagetype
	if not stage or not stage[lev] then return end
	local profit = {}
	if stage[lev].expreward then profit[config.resource.exp] = stage[lev].expreward end
	if stage[lev].goldreward then profit[config.resource.money] = stage[lev].goldreward end
	if stage[lev].firstexp or stage[lev].firstgold then
		if isboss then 
			profit[config.resource.exp] = (profit[config.resource.exp] or 0) + (stage[lev].firstexp or 0)
			profit[config.resource.money] = (profit[config.resource.money] or 0) + (stage[lev].firstgold or 0)
		end
	--[[	if stage[lev].stagetype == 1 then
			if wins+1 == lev then
				profit[config.resource.exp] = (profit[config.resource.exp] or 0) + (stage[lev].firstexp or 0)
				profit[config.resource.money] = (profit[config.resource.money] or 0) + (stage[lev].firstgold or 0)
			end
		else
			profit[config.resource.exp] = (profit[config.resource.exp] or 0) + (stage[lev].firstexp or 0)
			profit[config.resource.money] = (profit[config.resource.money] or 0) + (stage[lev].firstgold or 0)
		end]]--
	end
	return profit
end

function _M:get_offline_profit(id,num)
	local stage = self:get(id)
	if not stage then return end
	local profit = {}
	profit[config.resource.exp] = (stage[_M.stagetype].offlineexp or 0) * num
	profit[config.resource.money] = (stage[_M.stagetype].offlinegold or 0) * num
	
	return profit
end

function _M:get_offline_money(id,num)
	local stage = self:get(id)
	if not stage then return end
	local profit = {}
	profit[config.resource.money] = (stage[_M.stagetype].offlinegold or 0) * num * 60
	
	return profit
end

return _M