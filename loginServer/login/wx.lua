-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "login.config"
local cjson = require "include.cjson"
local geturl = require "include.geturl"
local function check_string(str)
	if not str then return "" end
	return ngx.quote_sql_str(tostring(str))
end

local _M = function(args)
	if not args or not args.code or type(args.code) ~= 'string' then return false,"no params" end
	local ok,res = geturl("https://api.weixin.qq.com/sns/oauth2/access_token",{
		appid = config.wx.appid,
		secret = config.wx.secret,
		code = args.code,
		grant_type = 'authorization_code'
	})
	if not ok then return false,res end
	
	ok,res = pcall(cjson.decode,res)
	if not ok then return false,"http return errror" end
	if res.errcode ~= 0 then return false,res.errmsg end
	
	ok,res = geturl("https://api.weixin.qq.com/sns/userinfo",{
		access_token = res.access_token,
		lang = "zh_CN",
		openid = "1111"
	})
	if not ok then return false,res end
	ok,res = pcall(cjson.decode,res)
	if not ok then return false,"http return errror" end
	if res.errcode ~= 0 then return false,res.errmsg end
	
	return false,res.body
end

return _M