-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.soldier"
local itemConfig = require "game.template.item"
local mergeProfit = require "game.model.merge_profit"
local task_config = require "game.template.task"
local rankMgr = require "manager.rankMgr"
local int = math.floor

local _M = model:extends()
_M.class = "soldier"
_M.push_name  = "soldiers"
_M.changed_name_in_role = "soldiers"
_M.attrs = {
	p = 1,
	j = 0,
	l = 1,
	q = 0,  --进阶等级
	w = 0,  --觉醒等级
	m = 0,
	n = 1,
	cost = {},
	sq = 0,    --改造等级
	eq = {0,0,0,0},  --装备列表
	badge = 0,
}

function _M:__up_version()
	_M.super.__up_version(self)
	self.data.p = self.id

	if not config:is_breakid(self.data.p) and  self.data.m == 1 then self.data.m=0 end
end

function _M:changed(id)
	_M.super.changed(self,id)
	if self.role then
		if self.role.army then
			self.role.army:fight_point_changed()
		end
		rankMgr:update("soldier_" .. self.data.p,self.role)
	end
end

function _M:get_pid()
	return self.data.p
end

function _M:get_level()
	return self.data.l
end

function _M:get_quality()
	return self.data.q
end

function _M:get_quality_upcount()
	return self.data.qn
end

function _M:get_superquality()
	return self.data.sq
end


function _M:get_mrank()
	return self.data.m
end

function _M:get_num()
	return self.data.n - self.data.j
end

function _M:append(n)
	self.data.n = self.data.n + n
	self:changed("n")
end

function _M:consume(n)
	if self:get_num() < n then return false end
	self.data.n = self.data.n - n
	self:changed("n")
	return true
end

function _M:is_empty()
	if self.data.n < 1 then return true end
	return false
end

function _M:go_battle()
	self.data.j = 1
	self:changed("j")
end

function _M:out_battle()
	self.data.j = 0
	self:changed("j")
end

function _M:level_up(cost)
	self.data.l = self.data.l + 1
	self:append_cost(cost)
	self:changed("l")
	self.role.tasklist:trigger(task_config.trigger_type.soldier_levup,1)
	self.role.tasklist:trigger(task_config.trigger_type.soldier_maxlev,self.data.l)
end

function can_evolve()
	return self.data.m == 0
end

function _M:mrank_up(cost)
	self.data.m = 1
	self:append_cost(cost)
	self:changed("m")
end

function _M:qrank_up(cost)
	self.data.q = self.data.q + 1
	self:append_cost(cost)
	self:changed("q")
end

function _M:sq_up(cost)
	self.data.sq = self.data.sq + 1
	self:append_cost(cost)
	self:changed("sq")
end

function _M:get_awaken_level( )
	return self.data.w
end

function _M:get_pos_equip(pos)
	return self.data.eq[pos]
end

function _M:reborn()
	self.data.l = 1
	self.data.q = 1
	self.data.qb = 0
	self.data.m = 0
	--self.data.n = 1
	self:changed()
	local cost = self:get_all_cost()
	self.data.cost = {}
	return cost
end

function _M:reclaim(me,num)
	--if self.data.q > 4 then return false end
	if num > self.data.n-1 then num = self.data.n end
	local cost = {}
	if me and self.data.q <= 4 then
		self.data.l = 1
		self.data.q = 1
		self.data.qb = 0
		self.data.m = 1
		cost = self:get_all_cost()
		self.data.cost = {}
--		num = num + 1
	end

	local reclaim_profit = config:get_reclaim_profit(self.data.p,num) or {}
	self.data.n = self.data.n - num
	self:changed()
	return mergeProfit(cost,reclaim_profit)
end

function _M:reset_quality_bless()
	self.data.qb = 0
	self.data.qn = 0
	self:changed("qb")
	self:changed("qn")
end

function _M:wear(pos,eqid)
	self.data.eq[pos] = eqid
	self:changed("eq")
end

function _M:can_awaken()
	for i,v in ipairs(self.data.eq) do
		if v == 0 then return false end
	end
	return true
end

function _M:awaken_up(cost)
	self.data.w = self.data.w + 1
	for i,v in ipairs(self.data.eq) do
	   self.data.eq[i]  = 0 
	end
	self:changed("w")
	self:changed("eq")
	self:append_cost(cost)
end

function _M:get_badge(t)
	self.data.badge = t + config.badge_time
end

function _M:get_fight_point()
	local attrs = {}
	if self.data.j and self.role then
		local army = self.role.army:get_full_army()
		if army then attrs = army[self.id] end
	end
	if not attrs then
		attrs = self:get_full_attributes()
		for k = 4,6 do
			if attrs[k] then attrs[k-3] = (attrs[k-3] or 0) + attrs[k] end
		end
	end
	return int((attrs[1] or 0)/8 + (attrs[2] or 0)*2 + (attrs[3] or 0))
end

function _M:inuse()
	return self.data.j ~= 0
end

function _M:get_full_attributes()
	return config:get_full_attributes(self:get_pid(),self.data)
end

return _M