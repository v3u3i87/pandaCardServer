-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local s_sub = string.sub
local cjson = require "include.cjson"

local _M = {}
_M.data = config.template.vip

_M.type = {
	spirit_max = 1,
	battle_max=2,
	buylegionboss_num=3,
	buyserbat_unm =4,
	quickbattle_num =5,
	buyspirit_num = 6,
	buygold_num =7,
	heroshop_max_r_num= 8,
	awakeshop_num =9,
	pokedexshop_num=10,
	dekaron_num=11,
	bw_num=12,
	arsen_max_b_mum=13,
	arena_num=14,
	dungeons_num=15,
	arsen_max_n_num=16,
}
_M.vip_fun = {
	[1] = "spirit_max",
	[2] = "battle_max",
	[3] = "buylegionboss_num",
	[4] = "buyserbat_unm",
	[5] = "quickbattle_num",
	[6] = "buyspirit_num",
	[7] = "buygold_num",
	[8] = "heroshop_max_r_num",
	[9] = "awakeshop_num",
	[10] = "pokedexshop_num",
	[11] = "dekaron_num",
	[12] = "bw_num",
	[13] = "arsen_max_b_mum",
	[14] = "arena_num",
	[15] = "dungeons_num",
	[16] = "arsen_max_n_num"
}

function _M:get(id)
	return self.data[id]
end

function _M:get_vip_lv(exp)
	local lv = 0 
	for i,v in pairs(self.data) do
		lv = v.level
		if exp <= v.gem then
			break
		end
	end
	return lv
end

function _M:get_fun_itmes(role,typ)
	local vip = role:get_vip_level()
	--ngx.log(ngx.ERR,"typ:",typ," self.vip_fun[typ]:",self.vip_fun[typ])
	if not self.data[vip] or not self.vip_fun[typ] then return 0 end
	return self.data[vip][ self.vip_fun[typ] ]
end

function _M:get_fun_itmes_vip(vip,typ)
	if not self.data[vip] or not self.vip_fun[typ] then return 0 end
	return self.data[vip][ self.vip_fun[typ] ]
end

function _M:get_buy_vip_item_cost(vip)
	if not self.data[vip] or not self.data[vip].price then return false end
	return true, { [ self.data[vip].price[1] ] = self.data[vip].price[2]}				 
end

function _M:get_vip_item(vip)
	if not self.data[vip] or not self.data[vip].goods then return false end
	return config:change_cost_num(self.data[vip].goods) or {}
end

return _M