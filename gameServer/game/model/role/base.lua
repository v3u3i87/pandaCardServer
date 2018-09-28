-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.config"
local baseConfig = require "game.template.base"
local stageConfig = require "game.template.stage"
local timetool = require "include.timetool"
local rankmgr = require "manager.rankMgr"
local task_config = require "game.template.task"
local countMgr = require "game.model.countMgr"
local vip_config = require "game.template.vip"
local fund_config = require "game.template.fund"
local pay_config =  require "game.template.pay"
local math_floor = math.floor


local s_gub = ngx.re.gsub

local _M = model:extends()
_M.class = "role.base"
_M.push_name  = "base"
_M.changed_name_in_role = "base"
_M.attrs = {
	exp = 0,
	lev = 1,
	money = 20000,
	diamond = 50,
	stage = "STAGE001",
	wins = 0,
	vip = 0,
	vipexp = 0,
	fast = 0,
	give = 0,		--当日已赠送次数
	receive = 0, 	--今日已领取次数
	cn	= 0,	--改名次数
	gt  = 0,  	--0点时间
	--mchange = 5,--vip_config:get_fun_itmes(self.role:get_vip_level(),3),--baseConfig.change_money_count_max,
	msign = 0, 	--	月签到 已签到次数
	mreward= 0, --	月签到 每日已领奖次数
	cln = 0, --	创角色累计登录天数
	mln = 0, --	每月累计登录天数
	onlinetime = 0,
	o_onlinetime = 0, --开服在线时间，领取任务后清除
	vipitem = {},
	act_opt={},
	pay_day = 0,
	m_card_time =0, --月卡到期时间
	m_card_count =0, --月卡次数
	h_card_count =0,    --高级卡
	count ={},--钻石秒cd次数
	fight =0,--战斗力
}

function _M:__up_version()
	_M.super.__up_version(self)
	local vipitem = {}
	for i,v in pairs(self.data.vipitem) do
		vipitem[tonumber(i)] = v
	end
	self.data.vipitem = vipitem
	if not self.data.fund then self.data.fund = 0 end
	if not self.data.fundreward then self.data.fundreward = {} end
	if not self.data.pay_day then self.data.pay_day = 0 end
	if not self.data.consumer_day then self.data.consumer_day = 0 end
	if not self.data.m_card_time then self.data.m_card_time =0 end
	if not self.data.m_card_count then self.data.m_card_count =0 end
	if not self.data.h_card_count then self.data.h_card_count =0 end
	if not self.data.count then self.data.count = {} end
	if not self.data.fight then self.data.fight = 0 end
	
	local ns = {}
	for i,v in pairs(self.data.act_opt) do
		ns[tonumber(i)] = v
	end
	self.data.act_opt = ns
end

function _M:init()
	if not self.data.mchange then self.data.mchange = vip_config:get_fun_itmes(self.role,vip_config.type.buygold_num) end
end

function  _M:is_time_updata(hour)
	if timetool:now() - self.data.gt <= timetool.one_day then return false end
	if not hour then hour =0 end
	local last_mon = timetool:get_month(self.data.gt)
	local g_day = timetool:get_day(self.data.gt)

	self.data.gt = timetool:get_hour_time(hour)

	self.data.give = 0
	self.data.receive = 0
	self.data.mchange = vip_config:get_fun_itmes(self.role,vip_config.type.buygold_num)
	self.data.cln = self.data.cln +1
	self.data.mreward = 0
	self:changed("gt")
	self:changed("give")
	self:changed("receive")
	self:changed("mchange")
	self:changed("cln")
	self:changed("mreward")
	self.data.onlinetime = 0
	self:changed("onlinetime")
	self.data.pay_day = 0
	self:changed("pay_day")
	self.data.consumer_day = 0
	self:changed("consumer_day")

	self.day = timetool:get_day()
	if self.day < g_day then 
		self.data.msign = 0
		self:changed("msign")
	end
	self.mon = timetool:get_month()
	if last_mon ~= self.mon then self.data.mln = 1 
	else self.data.mln = self.data.mln +1 end
	self:changed("mln")
	self.role.tasklist:trigger(task_config.trigger_type.login,1)
	self.role.activitylist:trigger(task_config.trigger_type.login,1)
	self.data.count = {}
	self:changed("count")
	return true
end

function _M:on_vip_up()
	local last = self.vip or 0
	self.data.mchange  = self.data.mchange  + vip_config:get_fun_itmes(self.role,vip_config.type.buygold_num) - 
			vip_config:get_fun_itmes_vip(last,vip_config.type.buygold_num)
	self:changed("mchange")
	self.vip = self.role:get_vip_level()
end


function _M:get_change_name_num()
	return self.data.cn
end
function _M:add_change_name_num()
	self.data.cn = self.data.cn + 1
	self:changed("cn")
end

function _M:get_level()
	return self.data.lev
end

function _M:get_money()
	return self.data.money
end

function _M:get_diamond()
	return self.data.diamond
end

function _M:get_give_count()
	return self.data.give
end

function _M:get_receive_count()
	return self.data.receive
end

function _M:add_give_count(value)
	self.data.give = self.data.give +value
	self:changed("give")
end

function _M:add_receive_count(value)
	self.data.receive = self.data.receive +value
	self:changed("receive")
end

function _M:add_exp(addexp)
	if self.data.lev >= baseConfig:get_max_level() then return false end
	self.data.exp = self.data.exp + addexp
	local up = baseConfig:get_level_exp(self:get_level())
	local bup = false
	while self.data.exp >= up do
		self.data.exp = self.data.exp - up
		self.data.lev = self.data.lev + 1
		if self.data.lev >= baseConfig:get_max_level() then self.data.exp = 0 end
		bup = true
		up = baseConfig:get_level_exp(self:get_level())
	end
	if bup then 
		self.role:on_level_up()
		self:changed("lev")
		self.role.commanders:check_weapon()
		self:push("role.levelup",self.data.lev)
		rankmgr:update(config.rank_type.level,self.role)
		self.role.tasklist:trigger(task_config.trigger_type.commander_maxlev,self.data.lev)	end
	self:changed("exp")
	return true
end

function _M:add_money(money)
	self.data.money = self.data.money + money
	self:changed("money")
end

function _M:add_diamond(diamond)
	self.data.diamond = self.data.diamond + diamond
	self:changed("diamond")
end

function _M:get_stage()
	return self.data.stage
end

function _M:get_stage_int()
	local buf,cout = s_gub(self.data.stage,"STAGE","0")
	if cout >0 then return tonumber(buf) end
	return 1
end

function _M:get_wins()
	return self.data.wins
end

function _M:get_vip_level()
	return self.data.vip or 0
end

function _M:has_month_card()
	return self.data.m_card_time > timetool:now()
end

function _M:has_life_card()
	return self.data.h_card_count == 1
end

function _M:cross_stage()
	self.data.stage = stageConfig:get_next(self.data.stage)
	self.data.wins = 0
	self.role.commanders:check_weapon()
	self:changed("stage")
	self:changed("wins")
	rankmgr:update(config.rank_type.stage,self.role)
end

function _M:win_stage_fight()
	self.data.wins = self.data.wins + 1
	self:changed("wins")
	self.role.commanders:check_weapon()
end

function _M:append_vip_exp(ve)
	if ve <= 0 then ve =0 end
	local last_vip_lv = self.data.vip
	self.data.vipexp = self.data.vipexp + ve
	self:changed("vipexp")
	self.data.vip = vip_config:get_vip_lv(self.data.vipexp)	
	if self.data.vip > last_vip_lv then 
		self.role:on_vip_up() 
		self:changed("vip")
	end
	self.data.pay_day = self.data.pay_day + ve
	self.pay_one = ve
	self:changed("pay_day")
	self.role.activitylist:trigger(task_config.trigger_type.pay_ac_all,ve)

	local profit ={[config.resource.diamond] = ve}
	self.role:gain_resource(profit)
	self.role.alliancegirl:charge(ve)
end


function _M:get_fast_fight_count()
	return self.data.fast
end

function _M:can_fight_fast()
	local need = baseConfig:get_fast_fight_vip_need(self.data.fast+1)
	return self.data.vip >= need
end

function _M:fast_fight()
	if not self:can_fight_fast() then return false end
	
	local profit = stageConfig:get_offline_profit(self:get_stage(),baseConfig.fast_fight.time)
	self.role:gain_resource(profit)
	self.data.fast = self.data.fast + 1
	local items = baseConfig:get_fast_fight_profit(self.data.fast)
	self.role:gain_resource(items)
	for k,v in pairs(items) do
		profit[k] = (profit[k] or 0 ) + v
	end

	self:changed("fast")
	self.role.tasklist:trigger(task_config.trigger_type.battle_fast,1)
	return profit
end

function _M:reset_fast_fight()
	self.data.fast = 0
	self:changed("fast")
end

function _M:can_change_money(typ,num)
	return self.data.mchange >= num
end

function _M:get_change_money_cost(typ,num)
	local cost = {}
	if typ == 1 then cost[baseConfig.change_money_need_prop_id] = num
	elseif typ == 2 then cost[config.resource.diamond] = num  * baseConfig.change_money_need_diamond end
	return cost
end

function _M:get_change_money_profit(num)
	self.data.mchange = self.data.mchange - num
	self:changed("mchange")
	self.role.tasklist:trigger(task_config.trigger_type.exchange,num)
	self.role.activitylist:trigger(task_config.trigger_type.exchange,num)

	return stageConfig:get_offline_money(self:get_stage(),num * 2)
end

function _M:get_num(t)
	local n =0
	if t ==1 then n = baseConfig.change_money_count_max - self.data.mchange
	end
	return n
end

function _M:can_month_reward()
	if not self.day then self.day = timetool:get_day() end
	return self.data.msign < self.day
end

function _M:get_month_reward_cost()
	return {[config.resource.diamond] = self.data.mreward * 30 }
end

function _M:get_month_reward_profit()
	return baseConfig:get_month_reward_profit(self.data.msign + 1)
end

function _M:add_month_reward()
	self.data.mreward = self.data.mreward +1
	self.data.msign = self.data.msign +1
	self:changed("mreward")
	self:changed("msign")
end


function _M:get_month_sign_num()
	return self.data.msign
end

function _M:get_month_reward_num()
	return self.data.mreward
end

function _M:create_login_num()
	return self.data.cln or 0
end

function _M:month_login_num()
	return self.data.mln or 0
end

function _M:add_online_time(value)
	if timetool:now() - self.data.gt > timetool.one_day then self.data.onlinetime = 0 end

	if not value then value = 0	end
	self.data.onlinetime = (self.data.onlinetime or 0)  + value
	self.data.o_onlinetime = (self.data.o_onlinetime or 0) + value
	--self:changed("onlinetime")
	--self.role.activitylist:trigger(task_config.trigger_type.Online_time,self.data.onlinetime)
end

function _M:get_online_time( )
	return self.data.onlinetime or 0
end

function _M:get_open_online_time( )
	return self.data.o_onlinetime or 0
end
function _M:set_open_online_time(value)
	if not value then value = 0 end
	self.data.o_onlinetime = value
end

function _M:buy_num(id)
	if not id then id = 1 end
	return countMgr:get_type_count(id)
end

function _M:check_buy_vip_item(id)
	if id > self.data.vip then return false end
	return not self.data.vipitem[id]
end
function _M:set_buy_vip_item(id)
	self.data.vipitem[id] = 1
	self:changed("vipitem")
end

function _M:get_pay_all()
	return 0
end

function _M:add_act_opet(in_id,num)
	--ngx.log(ngx.ERR,"111id:",in_id," num:",num," role.id:",self.role:get_id())
	local id = math_floor(in_id / 100 )*100 +1
	if not num then num = 1 end
	if num == 0 then self.data.act_opt[id] = 0
	else self.data.act_opt[id] = (self.data.act_opt[id] or 0 ) + num end
	if in_id == id then self.data.act_opt[id] = num end
	--ngx.log(ngx.ERR,"222id:",id," self.data.act_opt[id]:",self.data.act_opt[id] )
end

function _M:get_act_opet(id)
	--ngx.log(ngx.ERR,"111id:",id,"role.id",self.role:get_id())
	id = math_floor(id / 100 )*100 +1
	--ngx.log(ngx.ERR,"222id:",id," self.data.act_opt[id]:",self.data.act_opt[id] )
	if not self.data.act_opt[id] then return 0 end
	return self.data.act_opt[id]
end

function _M:can_buy_fund()
	return self.data.fund == 0
end
function _M:set_fund()
	self.data.fund = 1
	self:changed("fund")
	countMgr:add_type_data(countMgr.type.fund)
end

function _M:can_fund_reward(id)
	if self.data.fundreward[id]  or self.data.fund < 1   then return false end
	local need= fund_config:get_need_num(id)
	local typ = fund_config:get_type(id)
	if typ == 2 then
		return self.data.lev >= need
	elseif typ == 3 then
		return countMgr:get_type_count(countMgr.type.fund) >= need
	end
	return false
end

function _M:add_fund_reward(id)
	self.data.fundreward[id] = 1
	self:changed("fundreward")
end

function _M:is_fund()
	return self.data.fund == 1
end

function _M:get_pay_one( )
	local pay_one = self.pay_one or 0
	self.pay_one = 0
	return pay_one
end

function _M:is_month_card()
	--ngx.log(ngx.ERR,"self.data.m_card_time:",self.data.m_card_time," time_b:",self.data.m_card_time > timetool:now())
	if self.data.m_card_time > timetool:now() then return 1 end
	return 0
end

function _M:is_high_card()
	--ngx.log(ngx.ERR,"self.data.h_card_count:",self.data.h_card_count)

	return self.data.h_card_count
end

function _M:pay_item(id)
	local pay_item_type = pay_config:get_pay_item_type(id)
	--ngx.log(ngx.ERR,"id:",id," pay_item_type:",pay_item_type," pay_config.pay_type.month_card:",pay_config.pay_type.month_card)

	local mail_reward = nil
	local c =""
	local h=""
	local b_refresh_task =false
	if pay_item_type == pay_config.pay_type.month_card then
		local ltime = timetool:now()
		if self.data.m_card_time > ltime then return false end
		self.data.m_card_time = ltime + timetool.one_month
		self.data.m_card_count = self.data.m_card_count +1
		self:changed("m_card_time")
		self:changed("m_card_count")
		if self.data.m_card_count <= pay_config.month_card_count_reward then
			mail_reward = pay_config:month_card_reward()
			c = "开通月卡成功，获得额外奖励！"
			h = "月卡"
		end
		b_refresh_task = true
	elseif pay_item_type == pay_config.pay_type.high_card then
		if self.data.h_card_count > 0 then return false end
		self.data.h_card_count = self.data.h_card_count +1
		self:changed("h_card_count")
		mail_reward = pay_config:high_card_reward()
		c = "恭喜您成功开通终身卡，每日登录享受额外福利！"
		h="终身卡"
		b_refresh_task = true
	end
	local cjson = require "include.cjson"
	ngx.log(ngx.ERR,"mail_reward:",cjson.encode(mail_reward) )
	if mail_reward then
		local CMail = require "game.model.role.mail"
		local mail = {
			t = 1,
			s = 0,
			h =  h,
			c =  c,
			p = mail_reward,
		}
		self.role:receive_mail(CMail:new(nil,mail))
	end
	if b_refresh_task then
		self.role.tasklist:refresh()
		self.role.tasklist:trigger(task_config.trigger_type.login,1)
	end

	local ve = pay_config:get_pay_reward(id)
	--self.role:gain_resource(profit)
	self:append_vip_exp(ve)
end

function _M:check_cost_cd(typ,pos)
	return baseConfig:check_cost_cd(typ,self.data.count[typ])
end

function _M:get_cost_cd(typ)
	return baseConfig:get_cost_cd(typ,self.data.count[typ])
end

function _M:add_cost_cd(typ,pos)
	self.data.count[typ] = (self.data.count[typ] or 0 ) +1
	self:changed("count")
	if typ == 1 then

	end
end

function _M:set_fight_point(num)
	if num <=0 then num = 1 end
	self.data.fight = num
	rankmgr:update(config.rank_type.fight_point,self.role)

end

function _M:get_fight_point()
	return self.data.fight or 0
end

return _M