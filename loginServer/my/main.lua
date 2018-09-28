
local cjson = require "cjson"
cjson.encode_sparse_array(true,1,1)
local table_insert = table.insert
local math_floor = math.floor
local aa = "{\"t\":1,\"s\":0,\"r\":1482487658,\"h\":\"BOSS排行奖励\",\"c\":\"奖励内容查看附件\",\"p\":{\"12\":1000}}"
local b = cjson.decode(aa)
nginx.say(b,"===",type(b) )

local c = cjson.encode(aa)
nginx.say(c,"===",type(c) )