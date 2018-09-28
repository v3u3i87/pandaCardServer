-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local CConnect = require "include.connect"
local myconnect = CConnect:new()
local global = require "game.global"
local config = require "game.config"
ngx.log(ngx.ERR,"begin start ws ----")
myconnect:run(global,config)
ngx.log(ngx.ERR,"end start ws ----")