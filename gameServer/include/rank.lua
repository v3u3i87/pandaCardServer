local class = require "include.class"
local cjson = require "include.cjson"
local timetool = require "include.timetool"
local s_format = string.format
local t_insert = table.insert
local t_concat = table.concat
local t_remove = table.remove

local logerr = function(err)
	ngx.log(ngx.ERR,err)
end

local _M = class()

--[[
name---名称
asc---true:升序==false:降序
sub_len---nil:不分段==number:分段长度
sub_num---nil:不限分段个数==number:分段个数
pt 排序比较的值，如：战斗力
sn 排序名次　　　1 ...
data 数据     {"lev":1,"name":"test","id":3}
--]]
function _M:__init(name,asc,sub_len,sub_num)
    self.name = name
    self.asc = asc
    self.obj_list = {}
    self.sn = 0
    self.sub_len = sub_len or 500
    self.sub_index = {}
    if sub_num then
        self.sub_num = sub_num
        self.out_last_pt = 999999999
        if asc then self.out_last_pt = -999999999 end
        self.out_count = 0
    end
    self:new_sub_sortlist()
end

function _M:get_new_sn()
    self.sn = self.sn + 1
    return self.sn
end

function _M:load(con)
    local tn = "Rank_"..self.name
    local sql = s_format("SHOW TABLES LIKE '%s'",tn)
	local ret = con:query(sql)
	if not ret then return false end
	if #ret == 0 then return false end

    sql = s_format("SELECT * FROM `%s`",tn)
	ret = con:query(sql)
	if not ret then return false end
    for i=1,#ret do
		local item = ret[i]
        item.data = cjson.decode(item.data)
        if self.sn < item.sn then self.sn = item.sn end
        self:update(item)
    end
    
    sql = s_format("DROP TABLE IF EXISTS `%s`;",tn)
	con:query(sql)
    return true
end

function _M:save(con)
    local tn = "Rank_"..self.name
    local sql = s_format("DROP TABLE IF EXISTS `%s`;",tn)
    local ret = con:query(sql)
    if not ret then return false end
    sql = s_format([[
        CREATE TABLE `%s` (
        `idx`  int NOT NULL AUTO_INCREMENT ,
        `id`  int NULL ,
        `pt`  int NULL ,
        `sn`  int NULL ,
        `data`  longtext NULL ,
        PRIMARY KEY (`idx`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;]],
        tn
    )
    ret = con:query(sql)
    if not ret then return false end
    
    local insert_cmd = {};
    for i,v in pairs(self.obj_list) do
        local out = "{}"
        if v.data then out = cjson.encode(v.data) end
        local command_str = s_format("('%s','%s','%s','%s')",i,v.pt,v.sn,out)
        t_insert(insert_cmd,command_str)
        if #insert_cmd == 1000 then
            sql = s_format("INSERT INTO `%s` (`id`,`pt`,`sn`,`data`) VALUES " , tn)
            sql = sql .. t_concat(insert_cmd,",")
            ret = con:query(sql)
			if not ret then return false end
            insert_cmd = {}
        end
    end
    
    if #insert_cmd > 0 then
        sql = s_format("INSERT INTO `%s` (`id`,`pt`,`sn`,`data`) VALUES " , tn)
        sql = sql .. t_concat(insert_cmd,",")
        ret = con:query(sql)
		if not ret then return false end
    end

    return true
end

function _M:new_sub_sortlist(idx)
    local sub_num = #self.sub_index
    if idx and (idx < 2 or idx > sub_num) then idx = nil end
    
    if idx then
        local pt = self.sub_index[idx-1].pt
        local sn = self.sub_index[idx-1].sn
        t_insert(self.sub_index,idx,{pt=pt,sn=sn,sl={}})
    else
        --添加一组初始索引
        local pt = -9999999999
        local sn = 0
        if sub_num > 0 then
            pt = self.sub_index[sub_num].pt
            sn = self.sub_index[sub_num].sn
        elseif self.asc then 
            pt = 999999999
        end
        t_insert(self.sub_index,{pt=pt,sn=sn,sl={}})
    end
end

function _M:clean()
    local now = timetool:now()
    self.clean_time = self.clean_time or now
    if now - self.clean_time < 600 then return false end
    self.clean_time = now
    --为提高效率，每次clean仅清除一个垃圾点
    local idx_num = #self.sub_index
    if self.sub_num then
        --清理多余的数据
        if idx_num > self.sub_num and idx_num > 1 and self.sub_index[idx_num-1].sn > self.sub_len * self.sub_num then
            local sub = self.sub_index[idx_num]
            local n = #sub.sl
            if n > 0 then
                if asc and sl[n][2] > self.out_last_pt then self.out_last_pt = sl[n][2] end
                if not asc and sl[n][2] < self.out_last_pt then self.out_last_pt = sl[n][2] end
                self.out_count = self.out_count + n
            end
            t_remove(self.sub_index)
            return true
        end
    end
    
    local limit = math.floor(self.sub_len/2)
    for i=1,idx_num-1 do
        local sub1 = self.sub_index[i]
        if #sub1.sl == 0 then
            t_remove(self.sub_index,i)
            return true
        end
        local sub2 = self.sub_index[i+1]
        if #sub2.sl == 0 then
            t_remove(self.sub_index,i+1)
            return true
        end
        if #sub1.sl + #sub2.sl < limit then
            local sl = {}
            for k,r in ipairs(sub1.sl) do
                t_insert(sl,r)
            end
            for k,r in ipairs(sub2.sl) do
                t_insert(sl,r)
            end
            t_insert(self.sub_index,i,{pt=sub2.pt,sn=sub2.sn,sl=sl})
            t_remove(self.sub_index,i+2)
            t_remove(self.sub_index,i+1)
            return true
        end
    end
    return false
end

function _M:move_sub_sortlist(idx)
    local tn = #self.sub_index
    if idx > tn then return end
    local num = #self.sub_index[idx].sl - self.sub_len
    if num < 10 then return end
    if num > 20 then num = 20 end
    local next_idx = idx + 1
    if next_idx > tn then
        if not self.sub_num or next_idx <= self.sub_num 
            or self.sub_index[tn].sn < self.sub_len * self.sub_num then
            self:new_sub_sortlist()
        end
    elseif #self.sub_index[next_idx].sl > self.sub_len then
        self:new_sub_sortlist(next_idx)
    end
    
    --移动数据
    local from = self.sub_index[idx].sl
    local to = self.sub_index[next_idx]
    if to then to = to.sl end
    if to then
        for i = 1,num do
            local p = t_remove(from)
            t_insert(to,1,p)
        end
    else
        local nf = #from
        if asc and from[nf][2] > self.out_last_pt then self.out_last_pt = from[nf][2] end
        if not asc and from[nf][2] < self.out_last_pt then self.out_last_pt = from[nf][2] end
        self.out_count = self.out_count + num
        for i = 1,num do
            t_remove(from)
        end
    end
    
    --更新分组索引
    self.sub_index[idx].pt = from[#from][2]
    self.sub_index[idx].sn = self.sub_index[idx].sn - num
    if self.sub_index[next_idx] and to then
        self.sub_index[next_idx].pt = to[#to][2]
    end
end

function _M:find_sortlist_by_pt(pt,first)
    local sub_num = #self.sub_index
    local idx = self:get_index(self.sub_index,"pt",pt,1,sub_num,self.asc)
    if idx > sub_num then idx = idx - 1 end
    --此时idx为point最后一次出现的位置
    --需要向前找到第一次出现的位置
    while first do
        if idx > 1 then
            local pre = self.sub_index[idx-1]
            if pre.pt == pt then
                idx = idx - 1
            else
                break
            end
        else
            break
        end
    end
    return self.sub_index[idx].sl,self.sub_index[idx].sn,idx
end

--获取某值在指定队列范围中的序号 
---little:true:升序  false：降序
--获取到的是v值在指定队列范围中最后一次出现的序号
--如果v值排在指定队列范围之前，返回指定队列第一个序号
--如果v值排在指定队列范围之后，返回指定队列最后一个序号+1
--如果v值没有出现，则返回排在v值后一个值的序号
function _M:get_index(ranking_list,k, v, s, e, little)
    if v == ranking_list[e][k] then return e end
    if little then
        if v < ranking_list[s][k] then return s end
        if v > ranking_list[e][k] then return e + 1 end
    else
        if v > ranking_list[s][k] then return s end
        if v < ranking_list[e][k] then return e + 1 end
    end
    
    --到此处，e必定大于s
    while (e - s) > 1 do
        local idx = math.ceil((s + e)/2)
        local pt = ranking_list[idx][k]
        if v == pt then
            --如果下个序号中的值与v值不等，则表明该序号是v值出现的最后一个
            if not ranking_list[idx+1] then return idx end
            if ranking_list[idx+1][k] ~= v then return idx end
        end
        
        if little then
            if v >= pt then
                s = idx
            else
                e = idx
            end
        else
            if v <= pt then
                s = idx
            else
                e = idx
            end
        end
    end
    
    --缩到最后，必定两个元素，并且ranking_list[e][k]必定不等于v
    if v == ranking_list[s][k] then return s end
    return e
end

--获取排序值对应的具体位置
function _M:get_ranking_by_pt_sn(pt, sn)
    local idx_num = #self.sub_index
    if idx_num == 0 then return 1 end
    local sort_list,last_ranking,idx = self:find_sortlist_by_pt(pt,true);
    ::Find::
    local sub_num = #sort_list
    local first = last_ranking - sub_num
    local r = 1
    if sub_num > 0 then
        local point_pre = pt + 1
        if self.asc then point_pre = pt - 1 end
        r = self:get_index(sort_list, 2, point_pre, 1, sub_num, self.asc);
        if r <= sub_num then
            local e = self:get_index(sort_list, 2, pt, r, sub_num, self.asc);
            if r < e then
                if sort_list[r][2] == pt then
                    r = self:get_index(sort_list, 3, sn, r, e, true);
                else
                    if r + 1 < e then
                        r = self:get_index(sort_list, 3, sn, r+1, e, true);
                    else
                        r = e
                    end
                end
            end
        end
        if r > sub_num and idx < idx_num then
            local next_first = self.sub_index[idx+1].sl[1];
            if next_first[2] == pt then
                sort_list = self.sub_index[idx+1].sl
                last_ranking = self.sub_index[idx+1].sn
                idx = idx + 1
                goto Find
            end
        end
    end
    return (first + r),sort_list,idx
end

function _M:insert(info)
    self.obj_list[info.id] = {
        sn = info.sn,
        pt = info.pt,
        data = info.data,
    };
    local ranking,sort_list,idx = self:get_ranking_by_pt_sn(info.pt,info.sn);
    local real = ranking
    if idx > 1 then
        ranking = ranking - self.sub_index[idx-1].sn
    end
    
    if sort_list[ranking] and sort_list[ranking][2] == info.pt and sort_list[ranking][3] < info.sn then
        ranking = ranking + 1
        real = real + 1
    end
    t_insert(sort_list, ranking, {info.id,info.pt,info.sn});
    self.sub_index[idx].pt = sort_list[#sort_list][2];
    for i=idx,#self.sub_index do
        self.sub_index[i].sn = self.sub_index[i].sn + 1
    end
    self:move_sub_sortlist(idx);
    return real,info.sn
end

function _M:remove(id)
    if not self.obj_list[id] then return end
    local info = self.obj_list[id];
    local ranking,sort_list,idx = self:get_ranking_by_pt_sn(info.pt,info.sn);
    
    self.obj_list[id] = nil
    if ranking > self.sub_index[idx].sn and self.out_count then
        self.out_count = self.out_count -1
    else
        if self.sub_index[idx-1] then ranking = ranking - self.sub_index[idx-1].sn end
        if ranking > #sort_list or sort_list[ranking][1] ~= id then
            --查找出错
			logerr("remove===>排行榜查询目标数据错误",self.type)
            ranking = nil
            for i,v in ipairs(sort_list) do
                if v[1] == id then 
                    ranking = i 
                    break
                end
            end
            if not ranking then
                for i,v in ipairs(self.sub_index) do
                    for k,p in ipairs(v.sl) do
                        if p[1] == id then
                            idx = i
                            sort_list = v.sl
                            ranking = k
                            break
                        end
                    end
                    if ranking then break end
                end
            end
            if not ranking then return end
        end
        
        t_remove(sort_list,ranking);
        for i=idx,#self.sub_index do
            self.sub_index[i].sn = self.sub_index[i].sn - 1
        end
        
        local n = #sort_list
        if n == 0 then
            if #self.sub_index > 1 then
                t_remove(self.sub_index,idx);
            end
        else
            self.sub_index[idx].pt = sort_list[n][2];
        end
    end
end

function _M:update(info)
    if not info or not info.id or not info.pt   then return end 
    
    if self.obj_list[info.id] then
        self:remove(info.id);
        info.sn = self:get_new_sn();
    end
    if not info.sn then
        info.sn = self:get_new_sn();
    end

    return self:insert(info);
end

function _M:reset_point()
    local sn = 0
    for i,p in ipairs(self.sub_index) do
        for k,v in ipairs(p.sl) do
            sn = sn + 1
            v[2] = 0
            v[3] = sn
            local info = self.obj_list[v[1]];
            if info then
                info.pt = 0
                info.sn = sn
                if info.data then
                    if info.data.arena_point then info.data.arena_point = 0 end
                    if info.data.p then info.data.p = 0 end
                end
            end
        end
        p.pt = 0
    end
    
    if self.out_count and self.out_count > 0 then
        for i,v in pairs(self.obj_list) do
            if v.pt ~= 0 then
                sn = sn + 1
                v.pt = 0
                v.sn = sn
                if v.data then
                    if v.data.arena_point then v.data.arena_point = 0 end
                    if v.data.p then v.data.p = 0 end
                end
            end
        end
    end
end

function _M:get_last_ranking_by_pt(pt)
    local idx_num = #self.sub_index
    if idx_num == 0 then return 1 end
    local sort_list,last_ranking,idx = self:find_sortlist_by_pt(pt,false);
    local sub_num = #sort_list
    local first = last_ranking - sub_num
    local r = 1
    if sub_num > 0 then
        r = self:get_index(sort_list, 2, pt, 1, sub_num, self.asc);
    end
    
    return (first + r);
end

function _M:get_obj_ranking(id,getinfo)
    if getinfo then 
        if not self.obj_list[id] then return 0 end
    else
        if not self.obj_list[id] then return self.sub_index[#self.sub_index].sn + (self.out_count or 0) + 1 end
    end
    
    local pt = self.obj_list[id].pt
    local sn = self.obj_list[id].sn
    local ranking,sort_list,idx = self:get_ranking_by_pt_sn(pt,sn);
    local real = ranking
    
    if idx > 1 then
        ranking = ranking - self.sub_index[idx-1].sn
    end
    
    if ranking > #sort_list then
        if self.sub_num and real > self.sub_len * self.sub_num then
            local last = self.sub_index[#self.sub_index];
            local off = 0
            if (self.asc and pt < last.pt) or (not self.asc and pt > last.pt) then
                self:update({id=id,pt=pt,data=self.obj_list[id].data});
                return self:get_obj_ranking(id);
            end

            off = math.ceil(self.out_count * (pt - last.pt)/(self.out_last_pt - last.pt));
            real = last.sn + off
        end
    else
        if sort_list[ranking][1] ~= id then
            --数据出错
            logerr("get_obj_ranking===>排行榜查询目标数据错误",self.name)
            ranking = nil
            for i,v in ipairs(sort_list) do
                if v[1] == id then 
                    ranking = i 
                    break
                end
            end
            if not ranking then
                for i,v in ipairs(self.sub_index) do
                    for k,p in ipairs(v.sl) do
                        if p[1] == id then
                            idx = i
                            sort_list = v.sl
                            ranking = k
                            break
                        end
                    end
                    if ranking then break end
                end
            end
            if ranking then
                if self.sub_index[idx - 1] then
                    real = self.sub_index[idx - 1].sn + ranking
                else
                    real = ranking
                end
            else
                logerr("===Ranking Error==type:",self.name,"==id:",id)
			end
        end
    end

    return real
end

function _M:get_obj_pt(id)
    if not self.obj_list[id] then return end
    return self.obj_list[id].pt
end

function _M:get_obj_sn(id)
    if not self.obj_list[id] then return end
    return self.obj_list[id].sn
end

function _M:get_obj_data(id)
    if not self.obj_list[id] then return end
    return self.obj_list[id].data
end

function _M:get_sortlist_by_ranking(ranking)
    for i,v in ipairs(self.sub_index) do
        if v.sn >= ranking then return self.sub_index[i].sl,i end
    end
end

--s,e在self.out_count中的范围无效
function _M:get_range_data(s,e)
    local total_len = 0
    local sub_num = #self.sub_index
    if sub_num > 0 then total_len = self.sub_index[sub_num].sn end
    
    s = s or 1
    e = e or total_len
    if s < 1 then s = 1 end
    if e > total_len then e = total_len end
    if total_len == 0 or s > total_len or e < s then return end
    
    local gets = {};
    local cur = s
    while cur <= e do
        local sort_list,idx = self:get_sortlist_by_ranking(cur);
        local to = self.sub_index[idx].sn
        local from = 0
        if idx > 1 then from = self.sub_index[idx-1].sn end
        if to > e then to = e end
        t_insert(gets,{s=cur-from,e=to-from,sort_list=sort_list});
        cur = to + 1
    end
    
    return gets
end

function _M:get_range_objs(s,e)
    local obj_list = {};
    local gets = self:get_range_data(s,e);
    if not gets then return obj_list end

    for k,v in ipairs(gets) do
        for i=v.s,v.e do
            if v.sort_list[i] then
				local id = v.sort_list[i][1];
				if self.obj_list[id] then
					local rd = self.obj_list[id].data or {};
                    rd.pt = self.obj_list[id].pt
					rd.ranking = i
					t_insert(obj_list,rd);
				end
			end
        end
    end
    return obj_list
end

function _M:get_range_ids(s,e)
    local id_list = {};
    local gets = self:get_range_data(s,e);
    if not gets then return id_list end
    
    for k,v in ipairs(gets) do
        for i=v.s,v.e do
            if v.sort_list[i] then
				local id = v.sort_list[i][1];
				if self.obj_list[id] then 
					t_insert(id_list,id);
				end
			end
        end
    end
    return id_list
end

function _M:get_range_pts(s,e)
    local obj_list = {};
    local gets = self:get_range_data(s,e);
    if not gets then return obj_list end

    for k,v in ipairs(gets) do
        for i=v.s,v.e do
            if v.sort_list[i] then
				local id = v.sort_list[i][1];
				if self.obj_list[id] then
					t_insert(obj_list,{id=id,pt=self.obj_list[id].pt});
				end
			end
        end
    end
    return obj_list
end

function _M:get_range_from_pt_range(pt1,pt2)
    if self.asc then 
        if pt1 > pt2 then pt1,pt2 = pt2,pt1 end
        pt1 = pt1 - 1
    else 
        if pt1 < pt2 then pt1,pt2 = pt2,pt1 end
        pt1 = pt1 + 1
    end
    local s = self:get_ranking_by_pt_sn(pt1,1)
    local e = self:get_ranking_by_pt_sn(pt2,99999999)
    local last = self:get_range_pts(e,e)
    if last.pt ~= pt2 then e = e - 1 end
    return s,e
end

function _M:get_ids_from_pt_range(pt1,pt2)
    local s,e = self:get_range_from_pt_range(pt1,pt2)
    return self:get_range_ids(s,e)
end

function _M:get_objs_from_pt_range(pt1,pt2)
    local s,e = self:get_range_from_pt_range(pt1,pt2)
    return self:get_range_objs(s,e)
end

return _M