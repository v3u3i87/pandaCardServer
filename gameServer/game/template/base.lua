-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"

local math_floor = math.floor
local math_min = math.min
local timetool = require "include.timetool"
local math_random = require "include.random"


local _M = {}
_M.data = {
	upgrade = config.template.upgrade,
	quickcombat = config.template.quickcombat,
	monthsign = config.template.monthsign,
	consume = config.template.consume,
}
_M.fast_fight ={
	time = 180,
}
_M.change_money_count_max  = 4
_M.change_money_need_diamond  = 20
_M.change_money_need_prop_id = 108

function _M:get_max_level()
	return #self.data.upgrade
end

function _M:get_level_exp(lev)
	if not self.data.upgrade[lev] then return 999999 end
	return self.data.upgrade[lev].roleexp
end

function _M:get_fast_fight_vip_need(count)
	if not self.data.quickcombat[count] then return 9999 end
	return self.data.quickcombat[count].vip
end

function _M:get_fast_fight_cost(count)
	if not self.data.quickcombat[count] then return false end
	local cost = {}
	cost[self.data.quickcombat[count].cost] = 1
	return cost
end

function _M:get_fast_fight_profit(count)
	if not self.data.quickcombat[count] or not self.data.quickcombat[count].gailv  then return {} end
	local items = {}
	for i=1,3 do
		local n = math_random(1,10000)
		if n <= self.data.quickcombat[count].gailv[i][1] then
			local r = math_random(1,10000)
			for i,v in ipairs(self.data.quickcombat[count]["goods"..i]) do
				if v[2] >= r then 
					items[v[1]] = v[3]
					break;
				else
					r = r - v[2]
				end
			end
		end
	end
	return items
end


function _M:check_rename(num)
	local cost ={}
	if num >1 then cost[config.resource.diamond] = config.change_name_diamon end
	return cost
end

function _M:get_friends_max(role)
	--1.	初始为10次
	--2.	每提升5级，增加一次
	--3.	最大上线为30次
	return math_min(config.friends_def + math_floor(role.base:get_level() /5) ,config.friends_max )
end

function _M:get_friend_give_count(role)
	local friends_max = self:get_friends_max(role)
	local give_num = role.base:get_give_count()
	return friends_max - give_num
end

function _M:get_friend_receive_count(role)
	local receive_num = role.base:get_receive_count()
	return config.friends_max - receive_num
end

function _M:get_friend_append_count(role)
	local friends_max = self:get_friends_max(role)
	local friends_num = #role.friends.data
	return config.friends_max - friends_num
end

function _M:friend_comps(a,b)
	return a:get_level() > b:get_level()
end

function _M:get_month_reward_profit(pos)
	if not self.data.monthsign[pos] then return {} end
	local profit ={}
	for i=1,#self.data.monthsign[pos].reward,2 do
		local id = self.data.monthsign[pos].reward[i]
		local num = self.data.monthsign[pos].reward[i+1]
		profit[id] = (profit[id] or 0) + num
 	end
	return profit
end

function _M:check_cost_cd(typ,num)
	if not num then num = 0 end
	if not self.data.consume then return false end
	if not self.data.consume[typ][num+1] and not self.data.consume[typ][9999] then return false end
	return true
end
function _M:get_cost_cd(typ,num)
	if not num then num = 0 end
	if not self.data.consume then return false end
	if not self.data.consume[typ][num+1] and not self.data.consume[typ][9999] then return false end
	local diamond = self.data.consume[typ][num+1].price or self.data.consume[typ][9999].price
	return true,{[config.resource.diamond] = diamond}
end


return _M