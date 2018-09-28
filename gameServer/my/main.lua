-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602

    local cidMgr = require "manager.cidMgr"
    local key = cidMgr:login_key(24)
    ngx.say(" key:",key)
    ngx.say(" check:",cidMgr:check_verify(24,key))






