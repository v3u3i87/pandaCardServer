-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local timetool = require "include.timetool"
local s_split = require "include.stringsplit"
local t_insert = table.insert
local cjson = require "include.cjson"
local math_random = math.random
local math_floor = math.floor

local _M = {}
_M.data ={
	daily =  config.template.missionday,
	grown = config.template.missionach,
	missionvita = config.template.missionvita,
	all = {},
	trigger = config.template.missiontype,
	activity = config.template.activity,
	activitycontrol = config.template.activitycontrol,
	reward = {}
}

_M.task_activity_id 	= 22
_M.activity_begin_main_type = 4
_M.open_online_time = 5
_M.total_pay_day= 16

_M.trigger_tally_type = {
	additive = 1,
	reached = 2,
}

_M.act_opt_id = 16
_M.act_equals_subtype_id = 17		--条件相等的subtype_id
_M.act_soldier_pos_condition_op	= 14	--士兵位置

_M.trigger_fun = {
	[4] = {	model = "depot",	fun = "get_num"},
	[6] = {	model = "depot",	fun = "get_max_strengthen"},
	[8] = {	model = "depot",	fun = "get_max_refine"},
	[9] = {	model = "soldiers",	fun = "get_num"},
	[11] = {model = "soldiers",	fun = "get_max_level"},
	[22] = {model = "replica",	fun = "get_all_str"},
	[25] = {model = "base",		fun = "get_level"},
	[26] = {model = "virtual",	fun = "get_num" ,params=_M.task_activity_id},
	[27] = {model = "base",		fun = "get_online_time"},


	[33] = {model = "commanders",fun = "get_base_skill_level"},
	[34] = {model = "army",fun = "get_depot_strengthen_great_lev"},
	[35] = {model = "army",fun = "get_depot_refine_great_lev"},
	[36]= {model = "base",fun = "get_pay_all"},

	[37] = {model = "shop",fun = "get_shop_refresh"},
	[38] = {model = "base",fun = "get_stage_int"},
	[40] = {model = "base",		fun = "get_open_online_time"},
}

_M.check_fun = {
	[1] = {	model = "tasklist",	fun = "get_schedule"},
	[2] = {	model = "base",		fun = "get_level"},
	[3] = {	model = "base",		fun = "get_vip_level"},
	[4] = {	model = "soldiers",	fun = "get_quality"},
	[5] = {model = "base",	fun = "get_stage_int"},
	[6] = {	model = "base",		fun = "create_login_num"},
	[7] = {	model = "base",		fun = "month_login_num"},
	[8] = {	model = "base",		fun = "get_online_time"},
	[9] = {	model = "base",		fun = "pay"},
	[10] = { model = "base",		fun = "consumer"},
	[11] = { model = "base",		fun = "buy_num"},
	[12] = {model = "army",	fun = "get_all_min_strengthen"},
	[13] = {model = "army",	fun = "get_all_min_refine"},
	[14] = {model = "depot",	fun = "get_soldiers_pos"},
	[15] = {model = "army",	fun = "get_item_num"},
	[16] = {model = "base",fun = "get_act_opet"},
	[17] = {model = "base",		fun = "get_open_online_time"},
	[18] = {model = "activitylist",		fun = "get_activity_open_day"},
	[19] = {model = "base",		fun = "get_pay_one"},
	[20] = {model = "activitylist",		fun = "get_activity_Interval_day"},
	[21] = {model = "base",		fun = "is_month_card"},
	[22] = {model = "base",		fun = "is_high_card"},

	[100] = {model = "activitylist",	fun = "get_schedule"},
}

_M.update_time = {
	{d=-1,h=0,m=0,s=0},
	{w=-1,h=0,m=0,s=0},
	{M=-1,h=0,m=0,s=0},
}

function _M:format_time(t)
	local s = s_split(t,"[/ :]",true)
	local tt = {}
	tt.year = tonumber(s[1]) or 1970
	tt.month = tonumber(s[2]) or 1
	tt.day = tonumber(s[3]) or 1
	tt.hour = tonumber(s[4]) or 0
	tt.min = tonumber(s[5]) or 0
	tt.sec = tonumber(s[6]) or 0
	t = timetool:time(tt)
	return t
end

function _M:calc_time(st,et)
	if st then
		if type(st) == "string" then 
			st = self:format_time(st)
		else
			st = -st
		end
	end
	if et then
		if type(et) == "string" then 
			et = self:format_time(et)
		else
			et = -et
		end
	end
	return st,et
end


function _M:check_interval_time(st,et,interval_time)
	if interval_time and interval_time >0 and st > 0 and et >0 then
		local ct = timetool:now()
		for i=0,100 do
			local add_time = interval_time  * i	
			if st > ct then break end
			if st + add_time <= ct and et +add_time > ct then 
				st,et = st + add_time,et + add_time
				break
			end
		end
	end
	return st,et
end


function _M:__init()
	for i,v in pairs(self.data.daily) do
		v.st,v.et = self:calc_time(v.st,v.et)
		self.data.all[i] = v
	end
	for i,v in pairs(self.data.grown) do
		v.st,v.et = self:calc_time(v.st,v.et)
		self.data.all[i] = v
	end
	for i,v in pairs(self.data.missionvita) do
		v.st,v.et = self:calc_time(v.st,v.et)
		self.data.all[i] = v
	end

	for i,v in pairs(self.data.activitycontrol) do
		v.st,v.et = self:calc_time(v.st,v.et)
		v.interval = v.interval or 0
		v.st,v.et = self:check_interval_time(v.st,v.et,v.interval)
		local subid = v.subid or {}
		if v.refreshtype == 5 then
			--ngx.log(ngx.ERR,"subid:",cjson.encode(subid))
			for k1,v1 in ipairs(subid) do
				for k2,id in ipairs(v1) do
					local data = self.data.activity[id]
					if data then
						data.st,data.et = v.st,v.et
						data.pos = k1
						data.max_pos = #subid
						data.refreshtype = v.refreshtype
						data.interval = v.interval
						self.data.all[id] = data
						--ngx.log(ngx.ERR,"id",id, " data:",cjson.encode(data))
					end
				end
			end
		else
			for k2,id in ipairs(subid) do
				local data = self.data.activity[id]
				if data then
					data.st,data.et = v.st,v.et
					data.refreshtype = v.refreshtype
					data.interval = v.interval
					self.data.all[id] = data
				end
			end
		end
	end

	self.trigger_type = {}
	for i,v in pairs(self.data.trigger) do
		self.trigger_type[v.Trigger] = i
	end
end

function _M:get(id)
	return self.data.all[id]
end

function _M:get_trigger_type(trigger_id)
	return self.data.trigger[trigger_id].type
end

function _M:get_reached_schedule(role,id)
	local task = self:get(id)
	if not task then return false end
	local tf = self.trigger_fun[task.trigger]
	if not role or not tf or not role[tf.model] or not role[tf.model][tf.fun] then return false end
	if tf.params then
		return role[tf.model][tf.fun](role[tf.model],tf.params,task.tc)
	else
		return role[tf.model][tf.fun](role[tf.model],task.tc,id)
	end
end

function _M:check_condition(role,codition,...)
	if not role then return false end
	local arg = {...}
	local id = 0
	local subtype_id =0
	if #arg > 0 then 
		id = arg[1] 
		if self.data.all[id] then subtype_id = self.data.all[id].subtype or 0 end
	end
	--ngx.log(ngx.ERR,"role.id:",role:get_id()," id:",id," codition:",cjson.encode(codition))
	if codition and type(codition) == "table" then
		for i,v in ipairs(codition) do
			--ngx.log(ngx.ERR,"i:",i," v:",cjson.encode(v))
			local cf = self.check_fun[v[1]]
			if cf and role[cf.model] and role[cf.model][cf.fun] then
				local value = role[cf.model][cf.fun](role[cf.model],...)
				--ngx.log(ngx.ERR," value:",value," v[1]:",v[1]," v[2]:",v[2])
				if v[1] == self.act_soldier_pos_condition_op then if value > v[2] then return false end
				elseif subtype_id > 0 and subtype_id == self.act_equals_subtype_id then if value ~= v[2] then return false end
				elseif value < v[2] then return false end
			end
		end
	end
	return true
end

function _M:check_finish(role,id)
	local task = self:get(id)
	if not task then return false end
	return self:check_condition(role,task.mb,task.id)
end

function _M:get_reward_data(id)
	if not self.data.reward[id] then
		self.data.reward[id] = {}
		self.data.reward[id].n = 0
		self.data.reward[id].rewards = self.data.activity[id].reward
		for i,v in pairs(self.data.reward[id].rewards) do
			self.data.reward[id].n = self.data.reward[id].n + v[2]
		end
	end
	return self.data.reward[id]

end


function _M:get_profit(id,pos,num)
	if not pos then pos = 0 end
	if not num then num = 1 end
	local task = self.data.all[id]
	if not task then return false end
	if task.stype == 3 then
		if pos == 0 or not task.reward[pos] then return false
		else return { [task.reward[pos][1]]	 = task.reward[pos][2] * num	} 
		end
	elseif task.stype == 4 then
		if  not task.reward[2] or not task.reward[2][2] then return false end
		local rand = math_random(task.reward[1][2],task.reward[2][2] )
		return { [task.reward[1][1]]	 = rand * num	} 
	end
	return config:change_cost_num(task.reward,num)
end

function _M:get_next_task(id,g)
	local task = self.data.all[id]
	if not task then return false end

	if task.num and task.num > 1 and g < task.num then
		return id
	end
	return task.hz
end

function _M:is_task_end(id)
	local task = self.data.all[id]
	if not task then return false end
	local last_id = task.hz
	if last_id >0 and self.data.all[last_id] then return false end
	return true
end

function _M:is_reached_trigger(id)
	local task = self.data.all[id]
	if not task then return false end
	return self:get_trigger_type(task.trigger) == self.trigger_tally_type.reached
end

function _M:get_trigger_id(id)
	local task = self.data.all[id]
	if not task then return false end
	return task.trigger or 0
end

function _M:get_mian_type(id)
	local task = self.data.all[id]
	if not task then return false end
	return task.type or 0
end

function _M:get_subtype(id)
	local task = self.data.all[id]
	if not task then return false end
	return task.subtype or 0
end


function _M:get_chain_id(id)
	local task = self.data.all[id]
	if not task then return false end
	return task.chain or false
end

function _M:get_active_condition(id)
	local task = self.data.all[id]
	if not task then return false end
	return task.cf
end

function _M:check_time(id)
	local task = self.data.all[id]
	if not task then return false end

	if not task.st and (not task.et or task.et == 0) then return true end
	--if id == 10001 or id == 11001 then ngx.log(ngx.ERR,"task.st:",task.st," task.et:",task.et," task.interval:",task.interval) end
	task.st,task.et = self:check_interval_time(task.st,task.et,task.interval)
	--if id == 10001 or id == 11001 then ngx.log(ngx.ERR,"task.st:",task.st," task.et:",task.et," task.interval:",task.interval) end

	--if id ==2001 or id == 9001 then
	--	ngx.log(ngx.ERR,"task.st:",task.st," task.et:",task.et," ct:",ct," ss:",ss)
	--end
	local ct = timetool:now()
	local ss = ct%timetool.one_day
	if task.st then
		if task.st > ct then return false end
		if ss + task.st < 0 then return false end
	end
	if task.et then
		if task.et > 0 and task.et < ct then return false end
		if task.et < 0 then
			local st = task.st
			if st <= 0 then st = ct - ss - st end
			if st - task.et < ct then return false end
		end
	end
	return true
end

function _M:check_control_time(id)
	local task = self.data.activitycontrol[id]
	if not task then return false end
	if not task.st and (not task.et or task.et == 0) then return true end
	local ct = timetool:now()
	local ss = ct%timetool.one_day
	task.st,task.et = self:check_interval_time(task.st,task.et,task.interval)


	if task.st then
		if task.st > ct then return false end
		if ss + task.st < 0 then return false end
	end
	if task.et then
		if task.et > 0 and task.et < ct then return false end
		if task.et < 0 then
			local st = task.st
			if st <= 0 then st = ct - ss - st end
			if st - task.et < ct then return false end
		end
	end
	return true
end

function _M:check_chains(id,ins)
	if self.data.all[id].chain >0 then
		for ins_id,v in pairs(ins) do
			if self.data.all[ins_id] and self.data.all[ins_id].chain > 0 and 
				self.data.all[ins_id].chain == self.data.all[id].chain then
				return true 
			end
		end
	end
	return false
end

function _M:get_ids(chains,ins,is_activity)
	local ids = {}
	local lyday = timetool:get_yday()
	for id,v in pairs(self.data.all) do
		local main_type = v.type or 0
		if (is_activity and main_type >0 and main_type >= self.activity_begin_main_type) or 
			(not is_activity and main_type <self.activity_begin_main_type) then
			local chain_id = v.chain
			--if id == 10001 or id == 11001 or id == 12001 or id == 13001 then
			--	ngx.log(ngx.ERR,"id:",id," chain_id:",chain_id," chains[chain_id]:",chains[chain_id],"  ins[id]:", ins[id], " self:check_chains(id,ins):",self:check_chains(id,ins), " self:check_time(id):",self:check_time(id))
			--	ngx.log(ngx.ERR,"v:",cjson.encode(v))
			--end
			if not chains[chain_id] and not ins[id] and not self:check_chains(id,ins)  then
				if chain_id == 0 or v.qz == 0 then
					if self:check_time(id) then
	
						if v.pos and v.pos > 0 then
							local sday = timetool:get_yday(v.st)
							local pos = (lyday - sday + 1) % v.max_pos
							if pos == 0 then pos = v.max_pos end
							--ngx.log(ngx.ERR,"id:",id," pos:",pos," v.pos:",v.pos)
							if v.pos == pos then 
								t_insert(ids,id)
							end
						else
							t_insert(ids,id) 
						end
					end
				end
			end
		end
	end
	return ids
end

function _M:get_end_time(id)
	local task = self.data.all[id]
	if not task then return 0 end
	local et = 0
	if task.time and task.time > 0  then
		et = timetool:now() + task.time
	else
		if tonumber(task.refreshtype) == 1 or tonumber(task.refreshtype) == 5 then
			et = timetool:get_next_time(timetool:now(),self.update_time[1])
		elseif tonumber(task.refreshtype) == 2 then
			et = timetool:get_next_time(timetool:now(),self.update_time[2])
		elseif tonumber(task.refreshtype) == 3 then
			et = timetool:get_next_time(timetool:now(),self.update_time[3])
		elseif tonumber(task.refreshtype) == 4 then
			et = 0
		elseif task.et then
			if task.et >= 0 then 
				et = task.et 
			else
				local st = 0
				if not task.st then
					st = timetool:now()
				else
					if task.st > 0 then
						st = task.st
					else
						st = timetool:get_hour_time(0) - task.st
					end
				end
				et = st - task.et
			end
		end
	end
	return et
end

function _M:get_continued_time(id)
	local task = self.data.all[id]
	if not task or not task.time or task.time <=0  then return 0 end
	return timetool:now()  + task.time
end

function _M:check_arry(data,value)
	if not data then return false end
	local find =false
	for i,id in ipairs(data) do
		if id == value then 
			find = true
			break
		end
	end
	return find
end

function _M:load_main_type( )
	local ids = {}
	for id,v in pairs(self.data.all) do
		local main_type = v.type or 0
		if main_type >= self.activity_begin_main_type then
			local sub_type = v.subtype or 0
			ids[main_type] = ids[main_type] or {}
			if self:check_time(id) and not self:check_arry(ids[main_type],sub_type)  then t_insert(ids[main_type],sub_type) end
		end
	end
	return ids
end

function _M:check_subid_time(data,role)
	local ids ={}
	for k,v in pairs(data) do
		local task = role.activitylist.data[v]	
		if not task then t_insert(ids,v)
		elseif self:check_time(v) and task and task.data.s ~= 3   then
			 t_insert(ids,v) end
	end
	if #ids >0 then return true end
	return false
end

function _M:init_tocs(role,remove_id,chain,ids)
	local tocs = {}
	local ct = timetool:now()
	for i,v in pairs(self.data.activitycontrol) do

		if self:check_control_time(i) and v.open == 1 then
			if v.display and v.display == 1 then
				t_insert(tocs,v.ID)
			else
				local subid = v.subid or {}
				if v.refreshtype ==  5 then
					local day_num = self:get_activitycontrol_open_day(i)
					local leng = #v.subid or 1
					local pos = day_num - math_floor(day_num /leng) * leng
					if pos == 0 then pos = leng end
					subid = v.subid[pos] or v.subid[1]
					--ngx.log(ngx.ERR,"day_num:",day_num," leng:",leng," pos:",pos, " subid:",cjson.encode(subid))
				end
				if(subid and role and self:check_subid_time(subid,role) ) or not subid   then
					if subid and remove_id and remove_id >0  then
						local ID = 0
						local find = false
						if chain and chain >0  then
							for k1,v1 in pairs(subid) do
								if remove_id == v1 then
									find = true
									break
								end
							end
							if not find then t_insert(tocs,v.ID) end
						else
							for k1,v1 in pairs(subid) do
								if remove_id ~= v1 then	
									t_insert(tocs,v.ID) 
									break
								end
							end
						end
					else t_insert(tocs,v.ID) end
				end
			end
		end
	end
	if ids then
		--ngx.log(ngx.ERR,"ids:",cjson.encode(ids))
		--ngx.log(ngx.ERR,"111tocs:",cjson.encode(tocs))
		local tcosbuf ={}
		for i,ID in ipairs(tocs) do
			local   activitycontrol =  self.data.activitycontrol[ID]
			if activitycontrol and activitycontrol.display == 1 then
				t_insert(tcosbuf,ID)
			else
				local subid = activitycontrol.subid or {}
				if activitycontrol.refreshtype ==  5 then
					local day_num = self:get_activitycontrol_open_day(i)
					local leng = #activitycontrol.subid or 1
					local pos = day_num - math_floor(day_num /leng) * leng
					if pos == 0 then pos = leng end
					subid = activitycontrol.subid[pos] or activitycontrol.subid[1]
				end
				local find = false
				for i,id1 in ipairs(subid) do
					for id,v in pairs(ids) do
						local task = self.data.all[id]
						if task and id1 == id then
							find = true
							break
						end
					end
					if find then break end
				end
				if find then t_insert(tcosbuf,ID) end
			end
		end
		tocs = tcosbuf
		--ngx.log(ngx.ERR,"111tocs:",cjson.encode(tocs))
	end

	return tocs
end

function _M:get_cost(id,num)
	if not self.data.all[id] or  not self.data.all[id].cost then return false end
	return true,{[ self.data.all[id].cost[1]   ] = self.data.all[id].cost[2] * num}
end

function _M:check_p(data,remove_id,role,ids)
	if not remove_id then return true end
	local chain = self.data.all[remove_id].chain
	local tocs = self:init_tocs(role,remove_id,chain,ids)
	if data ~= tocs then return false,tocs end
	return true
end

function _M:is_act_opet(id)
	
	if not self.data.all[id] or not self.data.all[id].tc or  #self.data.all[id].tc <=0 then return false end
	local find = false
	for i,v in pairs(self.data.all[id].tc) do
		if v[1] == self.act_opt_id then 
			find =true
			break
		end
	end

	return find

end

function _M:get_activitycontrol_open_day(id)
	if not self.data.activitycontrol[id] then return 0 end
	local lyday = timetool:get_yday()
	local byday = timetool:get_yday(self.data.activitycontrol[id].st)
	return lyday - byday + 1 
end

function _M:get_activity_open_day(id)
	if not self.data.all[id] then return 0 end
	local lyday = timetool:get_yday()
	local byday = timetool:get_yday(self.data.all[id].st)
	return lyday - byday + 1 
end

function _M:is_end(id,g)
	if not self.data.all[id] then return false end
	if not self.data.all[id].num or self.data.all[id].num == 1 then return false end
	return self.data.all[id].num < g
end

function _M:check_tc(role,id,value)
	local task = self.data.all[id]
	--ngx.log(ngx.ERR,"id:",id)
	if not task then return 0 end
	return self:check_condition(role,task.tc,id)
end

function _M:is_send_mail(id)
	local task = self.data.all[id]
	if not task or not task.email or task.email ~=1 then return false end
	return true
end

function _M:get_name(id)
	local task = self.data.all[id]
	if not task or not task.name then return "" end
	return task.name
end

function _M:get_des(id)
	local task = self.data.all[id]
	if not task or not task.des then return "" end
	return task.des
end

function _M:get_num(id)
	local task = self.data.all[id]
	if not task or not task.num then return 0 end
	return task.num 
end

return _M