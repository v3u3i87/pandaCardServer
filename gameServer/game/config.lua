-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = require "include.config"
local cjson = require "include.cjson"

local t_link = function(t1,t2)
	local t = {}
	for i,v in ipairs(t1) do
		table.insert(t,v)
	end
	for i,v in ipairs(t2) do
		table.insert(t,v)
	end
	return t
end

_M.acc_address = "http://127.0.0.1:8089/login"
_M.server_id = 1

_M.db.base = {
	--ip = "192.168.1.5",
	--ip = "192.168.1.139",
	ip = "127.0.0.1",
	port = 3306,
	user = "root",
	pw = "123456",
	db = "ace_account",
}

--[[
_M.db.base = {
	ip = "192.168.1.5",
	port = 3306,
	user = "sothink",
	pw = "src8351",
	db = "ace_db",
}
--]]

_M.role.attributes = {"base","commanders","soldiers","depot","knapsack","army","tasklist","friends","research","extend","arsenal","boss","virtual","explore","mailbox","arena","replica","alliancegirl","both","resource","shop","activitylist","guid"}
_M.role.model = "game.model.role"
_M.mail.model = "game.model.role.mail"

_M.db.tables.role = {
	table = "role",
	cols = t_link({"uid","rname","logouttime"},_M.role.attributes),
	colsdef = {"INT NOT NULL","CHAR(64) DEFAULT ''","INT DEFAULT 0"},
}

_M.rank_type = {
	fight_point = 1,
	stage = 2,
	level = 3,
	damage = 4,
	exploit = 5,
	arena = 6,
	both = 7,
}

_M.rank = {
	fight_point = {
		type = _M.rank_type.fight_point,
		asc = false,
	},
	stage = {
		type = _M.rank_type.stage,
		asc = false,
	},
	level = {
		type = _M.rank_type.level,
		asc = false,
	},
	damage = {
		type = _M.rank_type.damage,
		asc = false,
	},
	exploit = {
		type = _M.rank_type.exploit,
		asc = false,
	},
	arena = {
		type = _M.rank_type.arena,
		asc = true,
	},
	both = {
		type = _M.rank_type.both,
		asc = false,
	},
}

_M.reward = {
	boss = {
		type = 1,
		rank_type = 5,
		title = "敌将来袭功勋排行奖励",
		content = "您的功勋举世瞩目，感谢你为盟军做出的卓越贡献，以下给予您的奖励，司令部见证您的表现！",
		template = "boss",
		update_time = {y=0,M=0,w=0,d=-1,h=3,m=0,s=0},
		clear = 1,
	},
	arena = {
		type = 2,
		rank_type = 6,
		title = "竞技场排名奖励",
		content = "恭喜您在竞技场中获得第",
		content2 = "名，您获得以下奖励：",
		template = "arena",
		update_time = {y=0,M=0,w=0,d=-1,h=21,m=0,s=0},
		get_ids_func = "get_ids_from_pt_range",
	},
	both = {
		type = 3,
		rank_type = 7,
		title = "军神争霸排名奖励",
		content = "恭喜您在军神争霸中积分排名获得第",
		content2 = "名，您获得以下奖励：",
		template = "both",
		update_time = {y=0,M=0,w=0,d=-1,h=22,m=0,s=0},
	},
	boss_d = {
		type = 4,
		rank_type = 4,
		title = "敌将来袭伤害排行奖励",
		content = "您的战绩威震四方，感谢你为盟军战局增添筹码，以下给予您的奖励，司令部瞩目您的表现！",
		update_time = {y=0,M=0,w=0,d=-1,h=3,m=0,s=0},
		template = "boss",
		clear = 1,
	},
}

_M.db.tables.reward = {
	table = "reward",
	cols = {"type","time","sendtime","data"},
	colsdef = {"INT","INT","INT","LONGTEXT"},
}

_M.db.tables.general = {
	table = "general",
	cols = {"soldier_id","first_record","second_record","third_record"},
	colsdef = {"INT","INT","INT","INT"},
}

_M.db.tables.resource = {
	table = "resource",
	cols = {"pid","hid","state"},
	colsdef = {"INT","INT","INT"},
}

_M.db.tables.count = {
	table = "count",
	cols = {"count","endtime"},
	colsdef = {"INT","INT"},
}


--[[
_M.db.tables.user = {
	table = "user",
	cols = {"uid","hlist"},
	colsdef = {"INT","VARCHAR"},
}
--]]
_M.update_obj = {
	cmb_reset = {data="commanders",fun="reset_mrank_bless",ut={d=-1,h=5,m=0,s=0},once=true},
	fast_reset = {data="base",fun="reset_fast_fight",ut={d=-1,h=3,m=0,s=0},once=true},
	girl_special = {data="alliancegirl",fun="reset_special",ut={d=-1,h=3,m=0,s=0},once=true},
	girl_tryst = {data="alliancegirl",fun="reply_tryst_num",dt=0,ut={h=-12},once=true},
}

_M.reward_check_interval = 600
_M.general_check_interval = 600
_M.general_save_interval = 600
_M.resource_check_interval =60 --10
_M.count_check_interval = 600

_M.change_name_diamond = 1000
_M.friends_max = 30
_M.friends_def = 10
_M.give_diamond = 20
_M.arena_pos_max = 20000
_M.pro_define = 10000

_M.supplybox = {
	start = 300,
	interval = {120,300},
	validity = 60,
}

_M.resource = {
	money = 1,
	diamond = 2,
	exp = 3,
}

_M.conf_names = {
	hero = {"armyid"},
	skill = {"skillid"},
	monster = {"masterid"},
	stage = {"stageid","stagetype"}, 
	attributeid = {"attributeid"},
	armypromote = {"armyid","promotelv"},
	armyrelation = {"armyid","relationorder"},
	armyrank = {"armyranklv"},
	commander = {"commanderid"},
	commanderskill = {"commanderskillid"},
	comderskillconsume = {"pos","lev"},
	commanderrank = {"armyranklv"},
	upgrade = {"lv"},
	accessory = {"accessoryid"},
	item = {"itemid"},
	armyfrag = {"fragid"},
	vehicle = {"vehicleid"},
	quickcombat = {"num"},
	string = {"strid"},
	card = {"id"},
	arsen = {"id"},
	armybreak = {"id"},
	vip = {"level"},
	armyreform = {"armyid","reformtimes"},
	armyawake = {"id"},
	combine	= {"id"},
	bossranklist = {"id"},
	bossawardlist = {"ID"},
	bossattribute = {"id"},
	shop = {"index"},
	explore = {"id"},
	exploreadven = {"id"},
	explorechest = {"id"},
	equipshuxing = {"id"},
	equipjinglian = {"level"},
	equipqianghua ={"lev"},
	equipduanzao={"id"},
	accjinglian={"accid","level"},
	accqianghua={"level"},
	arena ={"id"},
	counterboss = {"id"},
	counterstage = {"id"},
	alliancegirl = {"id"},
	duizhanjuntuan ={"id"},
	duizhanrank={"id"},
	duizhanreward={"id"},
	plunderstage={"id"},
	comcar ={"id"},
	comcarexp ={"lv"},
	comcarstar ={"star","quality"},
	comcarstrengthen ={"lv"},
	shopCar ={"index"},
	shopHero ={"index"},
	shopEqu ={"index"},
	shopCommon ={"index"},
	missionach = {"id"},
	missionday= {"id"},
	missionvita = {"id"},
	missiontype = {"id"},
	shopAre = {"index"},
	goodsfrag ={"purposeid"},
	monthsign ={"id"},
	activity = {"id"},
	activitycontrol = {"ID"},
	Interface = {"inid"},
	itemuse = {"itemid"},
	growthfund = {"id"},
	serverlist = {"id"},
	pay = {"id"},
	consume ={"type","count"},
	recordrank ={"id"},
}

function _M:change_cost(data)
	local destdata = {}
	if type(data) ~= "table" then data = cjson.decode(data) end
	--[[1,30000],[22015,60]]
	if #data >0 then
		for id,value in ipairs(data) do
			if type(value) == "table" then
				destdata[ value[1] ] = value[2]
			else
				destdata[id] = value
			end
		end
	end
	return destdata
end

function _M:change_cost_num(data,num)
	local destdata = {}
	if type(data) ~= "table" then data = cjson.decode(data) end
	if not num then num=1 end
	--[[1,30000],[22015,60]]
	if #data >0 then
		for id,value in ipairs(data) do
			if type(value) == "table" then
				destdata[ value[1] ] = value[2] * num
			else
				destdata[id] = value * num
			end
		end
	end
	return destdata
end

function _M:change_cost_arry(data,inum)
	if not inum then inum=1 end
	local profit = {}
	for i=1,#data,2 do
		local id = data[i]
		local num = data[i+1] * inum
		profit[id] = (profit[id] or 0) + num
 	end
	return profit
end


--pro .第几位为机率
function _M:get_rand_index(num,data,pro)
	local math_random = math.random
	local r1 = math_random(1,num)
	local idx = 0
	local index = pro or 1
	for i,v in ipairs(data) do
		if r1 < v[index] then
			idx = i
			break;
		end
		r1 = r1 - v[index]
	end
	return idx
end
return _M