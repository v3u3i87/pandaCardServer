-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = {}

_M.account_db = {
	ip = "127.0.0.1",
	port = 3306,
	user = "root",
	pw = "123456",
	db = "ace_account",
	table = "account",
}

_M.user_db = {
	ip = "127.0.0.1",
	port = 3306,
	user = "root",
	pw = "123456",
	db = "ace_account",
	table = "user",
	cols = {"cid","cn","info"},
	colsdef = {"INT","CHAR(256) DEFAULT ''","LONGTEXT DEFAULT NULL"},
	keys = {uid='INT NOT NULL AUTO_INCREMENT'},--默认key为id
	upk = "uid",
}
_M.wx = {
	appid = "wxcf34bce47d995270",
	secret = "50bf127108d53ab39ce13a90794f5382",
}
return _M