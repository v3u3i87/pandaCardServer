-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.replica"
local timetool = require "include.timetool"
local bconfig = require "game.config"
local task_config = require "game.template.task"
local vip_config = require "game.template.vip"
local open_config = require "game.template.open"

local max = math.max

local _M = model:extends()
_M.class = "role.replica"
_M.push_name  = "replica"
_M.changed_name_in_role = "replica"
_M.virtual_id = 24

_M.attrs = {
	llist ={},
	hlist={},
	bl={0,0,0,0},
	bls ={0,0,0,0},
	at = 0,
	en = config.replica_energy_max,
	n = config.replica_l_cout_max,
	rn = 0,
	bpost = 0,
	rf =0,
}


function _M:__up_version()
	_M.super.__up_version(self)
	if not self.vip then
		self.vip = 0
	 end
	 if not self.data.bl then self.data.bl ={0,0,0,0}end
	 if not self.data.bls then self.data.bls ={0,0,0,0}end
	 if not self.data.bpost then self.data.bpost = 0 end
	 if not self.data.rf then self.data.rf = 0 end

	 self:get_llist_post()
end

function _M:on_time_up()
	self.data.en =  config.replica_energy_max
	self.data.at = timetool:now() -1
	self:changed("en")
	self:changed("at")
	self.data.n = config.replica_l_cout_max
	self:changed("n")
	self.data.rn =0
	self:changed("rn")
	self.data.rf =0
	self:changed("rn")
	if self.data.bl[1] > 0 then
		self.data.bpost = self.data.bpost -3
		self.data.bpost = max(self.data.bpost,0)
		self.data.bl[1] = 0
	end

	self.data.bls[1]  = 0
	self.refresh_llist = false
	--[[for i,v in ipairs(self.data.llist) do
		v.fs = {0,0,0,0}
		v.ps = {0,0,0,0}
		v.g =0
	end]]--
	for i,v in ipairs(self.data.hlist) do
		--v.fs = {0,0,0,0}
		--v.ps = {0,0,0,0}
		v.ns = {config.replica_l_cout_max,config.replica_l_cout_max,config.replica_l_cout_max,config.replica_l_cout_max}
		--v.ss ={0,0,0,0}
		--v.gl = 0
		v.rn ={0,0,0,0}
	end
	self:changed("llist")
	self:changed("hlist")
	self:changed("bl")
	self:changed("bls")
end

function _M:update()
	local ltime = timetool:now() 
	if self.data.en < config.replica_energy_max and ltime - self.data.at >= config.replica_add_energy_interval then 
			self.data.at = ltime + config.replica_add_energy_interval
			self.data.en = self.data.en + 1
			self:changed("en")
			self:changed("at")
	end

	self:is_boss_refresh(ltime)
end

function _M:init()
	if #self.data.llist == 0 and not self.get_llist and open_config:check_level(self.role,open_config.need_level.replica)   then 
		self.data.llist = config:create_l_list() 
		self:changed("llist")
		self.get_llist = true
	end
	if #self.data.hlist == 0 and not self.get_hlist and open_config:check_level(self.role,open_config.need_level.replica) then
		self.data.hlist = config:create_h_list()
		self:changed("hlist")
		self.get_hlist = true
	end
end

function _M:virtula_add_count(num)
	self.data.en = self.data.en + num
	self:changed("en")
end

function _M:on_level_up()
	self:init()
end

function _M:on_vip_up()
	--self:refresh()
end

function _M:is_boss_refresh(ltime)
	local hour = timetool:get_hour(ltime)
	local lv = self.role:get_level()
	local send = false

	if hour >= 6 and self.data.bls[1] == 0 and lv >= config.replica_l_need_lv and not self.refresh_llist then
		local id =self:get_max_llist_id()
		if self:boss_refresh_stage(id) then send = true end
		self.refresh_llist = true
	elseif hour >= 6 and self.data.bls[2] == 0 and lv >= config.replica_h_need_lv then
		self.data.bl[2] = config:boss_refresh(2)
		self.data.bls[2]  = 1
		send = true
	elseif hour >= 12 and self.data.bls[3] == 0 and lv >= config.replica_h_need_lv then
		self.data.bl[3] = config:boss_refresh(2)
		self.data.bls[3]  = 1
		send = true
	elseif hour >= 18 and self.data.bls[4] == 0 and lv >= config.replica_h_need_lv then
		self.data.bl[4] = config:boss_refresh(2)
		self.data.bls[4]  = 1
		send = true
	end
	if hour == 3 and self.data.bl[1] >0 then
		self.data.bl={0,0,0,0}
		self.data.bls={0,0,0,0}
		send = true
	end	
	if send then
		self:changed("bl")
		self:changed("bls")
	end
end

function _M:get_max_llist_id()
	local id  =1 
	for i,v in ipairs(self.data.llist) do
		if v.fs[1] <= 0 then break end
		id = v.id
	end
	return id
end


function _M:check_stage(id,stage,num)
	if id > 100 then
		id = id % 100
		if not self.data.hlist[id] or not self.data.hlist[id].ns[stage] or self.data.hlist[id].ns[stage] - num < 0 then return false end
		if self.data.en - config.replica_stage_cost_energy * num < 0 then return false end
		if stage >1 and self.data.hlist[id].fs[stage-1] == 0 then return false end
		if id > 1 and self.data.hlist[id-1].fs[4] == 0 then return false end
	else
		if not self.data.llist[id] or self.data.n - num < 0 then return false end
		if stage >1 and self.data.llist[id].fs[stage-1] == 0 then return false end
		if id > 1 and self.data.llist[id-1].fs[4] == 0 then return false end
	end
	return true
end

function _M:get_stage_profit(id,stage,win,num)
	local f = 0
	if id > 100 and self.data.hlist[id - 100].fs[stage] == 0 then f =1 
	elseif id  >0 and id < 100 and self.data.llist[id].fs[stage] == 0 then f =1 end
	return config:get_stage_profit(f,id,stage,win,num)
end

function _M:get_all_str()
	self.all_str = 0
	for i,v in ipairs(self.data.hlist) do
		for i1,v1 in ipairs(v.ss) do
			if v1 >0 then self.all_str = self.all_str + v1 end
		end
	end
	return self.all_str
end

function _M:is_all_win(id)
	local pass = true
	for i,v in ipairs(self.data.hlist[id].ps) do
		if v ~= 1 then 
			pass =false
			break
		end
	end
	return pass
end


function _M:set_stage(id,stage,win,star,num,f)
	if id > 100 then
		id = id % 100
		self.data.hlist[id].ns[stage] = self.data.hlist[id].ns[stage] - num
		if win == 1 then
			local last_str = self.data.hlist[id].ss[stage]
			local last_ps = self.data.hlist[id].ps[stage]
			self.data.hlist[id].ss[stage] = max(self.data.hlist[id].ss[stage] , star )
			self.data.hlist[id].fs[stage] = 1
			self.data.hlist[id].ps[stage] = 1
			if last_str ~= star then 
				self:get_all_str() 
				self.role.tasklist:trigger(task_config.trigger_type.replica_high_starnum,self.all_str)
			end
			self.role.tasklist:trigger(task_config.trigger_type.replica_high_part_pass,num)
			if last_ps ==0 and self:is_all_win(id) then self.role.tasklist:trigger(task_config.trigger_type.replica_high_pass,1) end
		end
		self:changed("hlist")
		self.data.en = self.data.en - config.replica_stage_cost_energy * num
		self.data.at = timetool:now() + config.replica_add_energy_interval
		self:changed("en")
		self:use_virtaul(config.replica_stage_cost_energy * num)
	else
		self.data.n = self.data.n - num
		if win == 1 then 
			self.data.llist[id].fs[stage] = 1
			self.data.llist[id].ps[stage] = 1
		end
		self:changed("llist")
		self:changed("n")
		self:boss_refresh_stage(id)
	end
end

function _M:can_get_box(id,pos)
	if id > 100 then
		if not self.data.hlist[id-100]  or self.data.hlist[id-100].gl >= pos  then return false end
		return config:check_hlist_box(self.data.hlist[id-100],id,pos)
	else
		if not self.data.llist[id] or self.data.llist[id].g ~= 0 then return false end
		return config:check_llist_box(self.data.llist[id],id,pos)
	end
	return true
end

function _M:get_box_profit(id,pos)
	return config:get_box_profit(id,pos)
end

function _M:set_box(id,pos)
	if id > 100 then
		id = id % 100
		self.data.hlist[id].gl = pos
		self:changed("hlist")
	else
		self.data.llist[id].g = 1
		self:changed("llist")
	end
end

function _M:can_reset(id ,pos )
	if id < 100 then return false end
	if not self.data.hlist[id % 100] or not self.data.hlist[id % 100].rn[pos] then return false end
	if self.data.hlist[id % 100].rn[pos] + 1 > vip_config:get_fun_itmes(self.role,vip_config.type.bw_num) then return false end
	return true
end

function _M:get_reset_cost()
	return config:get_reset_cost()
end
function _M:set_reset(id,pos)
	self.data.hlist[id % 100].rn[pos] = self.data.hlist[id % 100].rn[pos] + 1
	self.data.hlist[id % 100].ns[pos] = config.replica_l_cout_max
	--self.data.rn  = self.data.rn  +1
	self:changed("hlist")
	self:changed("rn")
end

function _M:check_boss(pos)
	if not self.data.bl[pos] or self.data.bls[pos] ~= 1 then return false end
	if self.data.en - config:get_boss_consume(self.data.bl[pos])  < 0 then return false end
	return true
end

function _M:get_boss_profit(pos)
	return config:get_boss_profit(self.data.bl[pos])
end
function _M:set_boss(pos,win)
	if win == 1 then
		self.data.bls[pos] = 2
		self:changed("bls")
	end
	self.data.en = self.data.en - config:get_boss_consume(self.data.bl[pos])
	self.data.at = timetool:now() + config.replica_add_energy_interval
	self:changed("en")
	self:use_virtaul( config:get_boss_consume(self.data.bl[pos]))
	self:changed("at")
end

function _M:get_llist_post()
	self.lpost = 0
	for k,v in pairs(self.data.llist) do
		if v.ps and v.ps[1] == 1 and v.ps[4] ~= 1 then
			self.lpost = k
			break
		end
	end
end

function _M:boss_refresh_stage(id)
	if id > self.data.bpost + 3  and self.data.rf == 0 then
		self.data.bl[1] = config:boss_refresh(1)
		self.data.bls[1]  = 1
		self.data.rf = 1
		self.data.bpost = (self.data.bpost or 0 ) + 3
		self:changed("rf")
		self:changed("bl")
		self:changed("bls")
		self:changed("bpost")
		return true
	end
	return false
end
return _M