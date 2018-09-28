-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.both"
local timetool = require "include.timetool"
local bconfig = require "game.config"
local rankmgr = require "manager.rankMgr"
local roleMgr = require "manager.roleMgr"
local task_config = require "game.template.task"
local vip_config = require "game.template.vip"
local open_config = require "game.template.open"

local max= math.max
local min= math.min
local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove

local _M = model:extends()
_M.class = "role.both"
_M.push_name  = "both"
_M.changed_name_in_role = "both"
_M.attrs = {
	list ={},
	record={},
	esy	= 0,  --当前额外收益
	nq =0, --怒气值
	nt =0, --下次对战次数增加时间
	--num = vip_config:get_fun_itmes(self.role:get_vip_level(),4),	--config.both_stage_max, --当前剩余对战次数
	np =config.both_defind_points,--积分
	ap = config.both_defind_profit_pro, --收益率20~100(奖励 * ap/100)
	nq_time =0,--上次怒气减少的时间
}

function _M:__up_version()
	_M.super.__up_version(self)
	if not self.vip then self.vip = 0	end
	if not self.fail_count then self.fail_count = 0 end
	if not self.data.num then self.data.num = vip_config:get_fun_itmes(self.role,vip_config.type.battle_max) end
	if not self.data.nq_time then self.data.nq_time = timetool:get_last_hour_time(ltime) + 3600 end

end

function _M:init()
	if open_config:check_level(self.role,open_config.need_level.both)  and #self.data.list  <= 0 then
		rankmgr:update(bconfig.rank_type.both,self.role)
	end
end

function _M:on_time_up()
	self.data.np =  config.both_defind_points
	rankmgr:update(bconfig.rank_type.both,self.role)
	self.data.ap = config.both_defind_profit_pro
	self.data.num =  vip_config:get_fun_itmes(self.role,vip_config.type.battle_max)--config.both_stage_max
	self:changed("ap")
	self:changed("np")
	self:changed("num")
end

function _M:on_vip_up()
	local last = self.vip or 0
	self.data.num  = self.data.num  + vip_config:get_fun_itmes(self.role,vip_config.type.battle_max) - 
			vip_config:get_fun_itmes_vip(last,vip_config.type.battle_max)
	self:changed("num")
	self.vip = self.role:get_vip_level()
end

function _M:on_level_up()
	self:check_refresh_list()
end


function _M:update()
	local ltime = timetool:now() 
	local max_c = vip_config:get_fun_itmes(self.role,vip_config.type.battle_max)
	if self.data.num < max_c and ltime - self.data.nt >= 0 then 
		self.data.num =  min( max_c,self.data.num +  math_floor( 1+ ((ltime - self.data.nt) / config.both_add_stage_interval) ) )
		if self.data.num < max_c then self.data.nt = ltime + config.both_add_stage_interval 
		else self.data.nt = 0 end

		self:changed("nt")
		self:changed("num")
	end
	if self.data.nq >0 and ltime - self.data.nq_time >=config.both_cost_anger_time then
		self.data.nq = max(self.data.nq - config.both_cost_anger_count *  math_floor((ltime - self.data.nq_time) /config.both_cost_anger_time ) , 0)
		self.data.nq_time = ltime
		if self.data.nq <=0 then self.data.nq_time = 0 end
		self:changed("nq")
		self:changed("nq_time")
	end
end

function _M:check_refresh_list()
	if open_config:check_level(self.role,open_config.need_level.both)  then
		if #self.data.list <=0 then
			rankmgr:update(bconfig.rank_type.both,self.role)
		end
		if 	#self.data.list  < 3 or not self.data.list[1] or not self.data.list[1].id then self:refresh_list() end
	end
end


function _M:get_both_ap()
	return self.data.ap
end

function _M:set_both_ap(value)
	self.data.ap = self.data.ap + value * 20
	self.data.ap = max(config.both_min_profit_pro,   min(self.data.ap , config.both_defind_profit_pro) )
	self:changed("ap")
end

function _M:refresh_list()
	self.data.list = config:refresh_list(self.role:get_id())
	if #self.data.list < 3 then self.data.list = config:refresh_list(self.role:get_id()) end
	self:changed("list")
	return self.data.list
end

function _M:add_both_fail_count()
	self.fail_count = self.fail_count + 1
end

function _M:get_both_fail_count()
	return self.fail_count
end

function _M:get_both_np()
	if self.role:get_level() < config.both_need_level   then return nil end -- or #self.data.record <= 0
	return self.data.np
end

function _M:set_both_np(value)
	self.data.np = self.data.np + value
	self.data.np = max(self.data.np, 0)
	self:changed("np")
end

function _M:set_both_nq()
	self.data.nq = self.data.nq + config.both_stage_win_add_anger
	self.data.nq = min(self.data.nq,config.both_max_anger)

	if self.data.nq_time <= 0 then self.data.nq_time = timetool:now() end
	self:changed("nq")
end

function _M:find_list_index(id)
	local find  = false
	local index = 0
	for i,v in ipairs(self.data.list) do
		if v.id == id then 
			find =true
			index = i
			break
		end
	end
	return index
end

function _M:can_stage(id,is_stage)
	if is_stage then
		if self.to_id == 0 then return false end
	else
		local hour = timetool:get_hour()
		if hour < config.both_begin_hour or hour > config.both_end_hour then return false end
		if self.data.num < 1 then return false end
		self.to_id = id
	end
	local index = self:find_list_index(id)
	if index == 0 then return false end
	local frole = roleMgr:get_role(id)
	if not frole then return false end
	return true
end

function _M:set_begin_stage(id)
	self.data.num = self.data.num -1
	--self.data.nt = timetool:now() + config.both_add_stage_interval
	self:changed("num")
	if self.data.num + 1 == vip_config:get_fun_itmes(self.role,vip_config.type.battle_max) then
		self.data.nt = timetool:now() + config.both_add_stage_interval
		self:changed("nt")
	end
end

function _M:stage(id,win)
	local index = self:find_list_index(id)
	local frole = roleMgr:get_role(self.data.list[index].id)
	local money,exp,profit = config:stage_profit(win,frole:get_level(),self.data.list[index].ap)
	self.role.tasklist:trigger(task_config.trigger_type.both,1)
	self.role.activitylist:trigger(task_config.trigger_type.both,1)
	self.to_id = 0
	if win == 1 then
		self:set_both_nq()
		self:set_both_np(config.both_stage_add_points)
		frole.both:set_both_np(-config.both_stage_add_points)
		rankmgr:update(bconfig.rank_type.both,self.role)
		rankmgr:update(bconfig.rank_type.both,frole)
		self:add_stage_info(1,id,money,exp)
		frole.both:add_stage_info(4,id)
		self:set_both_ap(1)
		frole.both:set_both_ap(-1)
		self.role.tasklist:trigger(task_config.trigger_type.both_win,1)
	else
		self:add_stage_info(2,id,money,exp)
		frole.both:add_stage_info(3,id)
		self:add_both_fail_count()
	end

	return profit
end

function _M:add_stage_info(typ,id,money,exp)
--[[
	record
	id	数字	玩家id
	name	字符串	名字
	type	数字	类型（1表示挑战成功，2表示挑战失败，3表示防守成功，4表示防守失败）
	gold	数字	获得金币(没有传0)
	exp	数字	获得经验(没有传0)
	ts	数字	战斗的时间
]]
	local record={}
	record.id = id
	local frole = roleMgr:get_role(id)
	record.name = frole:get_name()
	record.type = typ
	record.gold = money
	record.exp = exp
	record.ts =timetool:now()
	table_insert(self.data.record, record)
	if #self.data.record > config.both_record_count then
		table_remove(self.data.record,1)
	end
	self:changed("recode")
end

function _M:can_buycount()
	return self.data.num < vip_config:get_fun_itmes(self.role,vip_config.type.battle_max)
end

function _M:get_buycount_cost()
	return {[bconfig.resource.diamond] = config.both_add_stage_need_diamond}
end

function _M:add_count()
	self.data.num = self.data.num + 1
	self:changed("num")
end

function _M:clear_data()
end

function _M:stage_list()
	return self.data.record
end

return _M