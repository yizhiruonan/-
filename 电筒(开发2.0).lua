local C, V = {
["道具id"] = 12005,--把12005改成自己地图里的自定义道具id
["循环频率"] = 0.05,
["光照强度"] = 10,
["光照衰减强度"] = 20,
["照明距离"] = 100
}, {}

function 删除光源(uin, postab)
    if #postab == 0 then
        return
    end

    for k ,v in ipairs(postab) do
        World:setBlockLightEx(v.x, v.y, v.z, 0, WorldId)
    end
end

function 两点连线(postab, wz1, wz2, len)
    local kx, ky, kz = (wz2.x - wz1.x)/len, (wz2.y - wz1.y)/len, (wz2.z - wz1.z)/len
    for i = len, 0, -1 do
        table.insert(postab, {x=math.floor(wz1.x + i*kx), y=math.floor(wz1.y + i*ky), z=math.floor(wz1.z + i*kz)})
    end
end

function 创建光源(uin, postab, x, y, z, pitch, yaw)
    local l, 强度, 衰减 = C.照明距离, C.光照强度, C.光照衰减强度
    local cos_p, sin_p = math.cos(pitch), math.sin(pitch)
    local cos_y, sin_y = math.cos(yaw), math.sin(yaw)
    local 向量 = {
        x = -cos_p * sin_y,
        y = -sin_p,
        z = -cos_p * cos_y
    }
    local _, d = World:getRayLength(x, y, z, x+向量.x*l, y+向量.y*l, z+向量.z*l, 1)
    local len = math.min(l, d ~= -1 and d or l)
    local 位置 = d ~= -1 and {x =x + 向量.x*len, y = y + 向量.y*len, z = z + 向量.z * len} or {x=x, y=y, z=z}
    两点连线(postab, {x=x, y=y, z=z}, 位置, len)

    if 衰减 > 0 then
        for i, v in ipairs(postab) do
            local posFactor = i / #postab
            local factor = 1 - (1 - posFactor) * (衰减 / 100)
            World:setBlockLightEx(v.x, v.y, v.z, 强度 * factor)
        end
    else
        for k, v in ipairs(postab) do
            World:setBlockLightEx(v.x, v.y, v.z, 强度)
        end
    end
end

function 动态更新光源(uin, 老postab, 新postab)
    local del = {}
    local 哈希表 = {}
    for _, v in ipairs(新postab) do
        哈希表[v.x..","..v.y..","..v.z] = true
    end
    
    for _, v in ipairs(老postab) do
        if not 哈希表[v.x..","..v.y..","..v.z] then
            table.insert(del, v)
        end
    end
    
    if #del > 0 then
        删除光源(uin, del)
    end
    
    V.uin.位置表 = 新postab
end

function 开启电筒(uin)
    local Cpitch, Cyaw = 0, 0
    local Cx, Cy, Cz = 0, 0, 0
    local toolID = 0
    local postab = V.uin.位置表 or {}
    local T = C.循环频率

    while V.uin.循环开关 do
        _, toolID = Player:getCurToolID(uin)
        if toolID == C.道具id then
            local _, x, y, z = Actor:getPosition(uin)
            local _, pitch =Actor:getFacePitch(uin)
            local _, yaw = Actor:getFaceYaw(uin)
            if x ~= Cx or y ~= Cy or z ~= Cz or pitch ~= Cpitch or yaw ~= Cyaw then
                local 新postab = {}
                创建光源(uin, 新postab, x, y + 1.5, z, math.rad(pitch), math.rad(yaw))
                动态更新光源(uin, postab, 新postab)
                postab = 新postab
                Cx, Cy, Cz = x, y, z
                Cpitch, Cyaw = pitch, yaw
            end
        else
            删除光源(uin, postab)
            Cx, Cy, Cz = 0, 0, 0
        end
        threadpool:wait(T)
    end
    删除光源(uin, postab)
end

function 使用道具(e)
    local uin = e.eventobjid
    local 运行 = {}
    if e.itemid ~= C.道具id then
        return
    end

    V.uin.循环开关 = not (V.uin.循环开关 or false)
    V.uin.位置表 = V.uin.位置表 or {}

    if V.uin.循环开关 then
        开启电筒(uin)
        Player:playMusic(uin, 10650, 100, 1, false)
        Player:notifyGameInfo2Self(uin, "#G开启电筒")
    else
        Player:playMusic(uin, 10650, 100, 1, false)
        Player:notifyGameInfo2Self(uin, "#R关闭电筒")
    end
end

function 进入游戏(e)
    local uin = e.eventobjid
    V.uin = V.uin or {}
end

ScriptSupportEvent:registerEvent([=[Player.UseItem]=], 使用道具)
ScriptSupportEvent:registerEvent([=[Game.AnyPlayer.EnterGame]=], 进入游戏)