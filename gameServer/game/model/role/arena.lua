-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.arena"
local timetool = require "include.timetool"
local bconfig = require "game.config"
local rankmgr = require "manager.rankMgr"
local roleMgr = require "manager.roleMgr"
local vip_config = require "game.template.vip"
local open_config = require "game.template.open"
local task_config = require "game.template.task"


local _M = model:extends()
_M.class = "role.arena"
_M.push_name  = "arena"
_M.changed_name_in_role = "arena"
_M.attrs = {
	my = 20001,
	num = config.arena_stage_max,
	nt = timetool:now(),
	list ={},
	bt = 0, --开始攻击时间
	at = 0, --被攻击时间
}
--[[
id	数字	玩家id
name	字符串	名字
lv	数字	等级
atk	数字	战力
pos	数字	排名
typ	数字	typ:1机器人
--]]

function _M:__up_version()
	_M.super.__up_version(self)
	if not self.vip then self.vip = 0	end
	if not self.bt then self.bt = 0 end
	if not self.data.rnum then self.data.rnum = vip_config:get_fun_itmes(self.role,vip_config.type.arena_num) end
end

function _M:on_time_up()
	self.data.rnum = vip_config:get_fun_itmes(self.role,vip_config.type.arena_num)
	self.data.num = config.arena_stage_max
	self.data.nt = timetool:now()
	self:changed("num")
	self:changed("rnum")
	self:changed("nt")
end

function _M:on_vip_up()
	local last = self.vip or 0
	self.data.rnum  = self.data.rnum  + vip_config:get_fun_itmes(self.role,vip_config.type.arena_num) - 
			vip_config:get_fun_itmes_vip(last,vip_config.type.arena_num)
	self:changed("rnum")
	self.vip = self.role:get_vip_level()
end

function _M:init()
	if open_config:check_level(self.role,open_config.need_level.arena) and	#self.data.list  == 0 then
		self:refresh()
	end
end

function _M:on_level_up()
	self:init()
end

function _M:update()
	local ltime = timetool:now() 
	if self.data.num < config.arena_stage_max and ltime - self.data.nt >= config.arena_add_stage_interval_time then 
			self.data.nt = ltime
			self.data.num = self.data.num + 1
			self:changed("nt")
			self:changed("num")
	end

	if ltime -	self.data.bt > config.arena_stage_time_max then self.data.bt = 0 end
	if ltime -	self.data.at > config.arena_stage_time_max then self.data.at = 0 end
end

function _M:get_arena()
	return self.data.my
end

function _M:check_refresh( )
	if not self.refresh_time  then self.refresh_time = timetool:now() - 2 end
	return timetool:now()  - self.refresh_time >= 1
end

function _M:check_stage()
	if timetool:now()  -  self.data.at >= config.arena_stage_time_max then  self.data.at = 0 end
	return self.data.at == 0
end

function _M:set_stage_begin()
	self.data.at = timetool:now()
	self:changed("at")
end
function _M:set_stage_end()
	self.data.at = 0
	self:changed("at")
end

function _M:refresh( )
	self.data.list = config:refresh(self.data.my,self.role:get_id())
	self:changed("list")
	return self.data.list
end

function _M:find_list_index(pos)
	local find  = false
	local index = 0
	for i,v in ipairs(self.data.list) do
		if v.pos == pos then 
			find =true
			index = i
			break
		end
	end
	return index
end

function _M:set_pos(pos)
	self.data.my = pos
	self:changed("pos")
	rankmgr:update(bconfig.rank_type.arena,self.role)
end

function _M:can_begin_stage(pos)
	local index = self:find_list_index(pos)
	if index == 0 then return false end
	if self.data.list[index].id <= 0 then return true end
	local frole = roleMgr:get_role(self.data.list[index].id)
	if frole then return frole.arena:check_stage()
	else return true end
	return false	
end

function _M:beign_stage(pos)
	local index = self:find_list_index(pos)
	local frole = roleMgr:get_role(self.data.list[index].id)
	if frole then  frole.arena:set_stage_begin() end
	self.data.num = self.data.num -1
	self:changed("num")
	self.data.bt = timetool:now()
	self:changed("bt")
end


function _M:can_stage(pos,num,typ)
	local index = self:find_list_index(pos)
	if index == 0 then return false end
	if typ ~= 1 and  timetool:now() -	self.data.bt > config.arena_stage_time_max then return false end
	if typ == 1 and self.data.num < num then return false end
	return true
end

function _M:stage(pos,num,win,typ)
	local index = self:find_list_index(pos)
	self.role.tasklist:trigger(task_config.trigger_type.arena_num,num)
	self.role.activitylist:trigger(task_config.trigger_type.arena_num,num)


	local frole = roleMgr:get_role(self.data.list[index].id)
	if num == 1 and win == 1 then
		--config:beign_stage(self.role:get_id(),self.data.my, self.data.list[index].id,self.data.list[index].pos,self.data.list[index].typ)
		local lastmy = self.data.my
		self.data.my = self.data.list[index].pos
		--self.data.my = 1
		rankmgr:update(bconfig.rank_type.arena,self.role)
		if self.data.list[index].typ ~= 1 then
			if frole then frole.arena:set_pos(lastmy) end
		end
		self:changed("my")
	end

	if typ == 1 then
		self.data.num = self.data.num -num
		self:changed("num")
	end
	self.data.bt = 0
	self:changed("bt")
	if frole then frole.arena:set_stage_end() end

	return config:stage_profit(win,num)
end

function _M:can_buycount()
	if self.data.rnum <= 0 then return false end
	return self.data.num <= 0
end

function _M:get_buycount_cost()
	return {[bconfig.resource.diamond] = config.arena_refresh_need_diamond}
end

function _M:add_count()
	self.data.rnum = self.data.rnum -1
	self.data.num = config.arena_stage_max
	self:changed("num")
	self:changed("rnum")
end

return _M