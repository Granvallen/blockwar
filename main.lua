local toybox = require "toybox"
local tween = require 'tween'

-- 创建并初始化数组
function arrays(r, c, d)
    local table = {}
    if r == 1 then
        for j = 1, c do
            table[j] = d
        end
    else
        for i = 1, r do
            table[i] = {}
            for j = 1, c do
                table[i][j] = d
            end
        end
    end
    return table
end

-- 点阵 表的索引坐标转换为像素真实坐标
function idx2axis(index)
    return points[index[1]][index[2]]
end

-- 计算点阵坐标
function getPoints(r, c, l, board)
    local lp = 4*l / (5*(r - 1))  -- 点与点之间的距离
    local p0 = {board[1] + l/10, board[2] + l/10} -- 左上角第一个点的位置
    local points = {}

    for i = 1, r do
        points[i] = {}
        for j = 1, c do
            points[i][j] = {p0[1] + lp*(j - 1), p0[2] + lp*(i - 1)}
        end
    end

    return points
end

-- 判断 索引 是否对于t越界 
function isInRange(index, t)
    local dim = #index

    for i = 1, dim do
        if t[index[i]] == nil then
            return false
        end
        t = t[index[i]]
    end

    return true
end

-- 判断两表是否相同
function tablecmp(t1, t2)
    if type(t1) == "table" and type(t2) == "table" then
        if #t1 == 0 and #t2 == 0 then
            return true
        end

        if #t1 ~= #t2 then
            return false
        end

        for i, v in ipairs(t1) do
            if type(v) == "table" and type(t2[i]) == "table" and tablecmp(v, t2[i]) then
            else
                if v ~= t2[i] then
                    return false
                end
            end
        end
        return true
    else
        return t1 == t2
    end
end

-- 玩家轮流
function playerturn()
    player = player + 1
    if player > player_num then
        player = 1
    end
end

-- 判断该点能不能选中 并 返回能与之连线的点(包括已选中的点)
function getSltpoints(sltpoint) -- 接受选中点的 索引
    local sltpoints = {points[sltpoint[1]][sltpoint[2]]} -- 可选点的 真实坐标
    local sltpointsindex = {sltpoint} -- 可选点的索引
    local isselectable = false
    local p

    -- 左
    p = {sltpoint[1], sltpoint[2] - 1}--左边那条边映射到ht的 索引 同时也是左边那个点的 索引
    if isInRange(p, ht) then -- 边是否存在
        if  not ht[p[1]][p[2]] then -- 且没有被画过
            table.insert(sltpoints, points[p[1]][p[2]])
            table.insert(sltpointsindex, p)
            isselectable = true
            -- print(p[1], p[2])
        end
    end

    -- 上
    p = {sltpoint[1] - 1, sltpoint[2]}
    if isInRange(p, vt) then -- 边是否存在
        if  not vt[p[1]][p[2]] then -- 且没有被画过
            table.insert(sltpoints, points[p[1]][p[2]])
            table.insert(sltpointsindex, p)
            isselectable = true
            -- print(p[1], p[2])
        end
    end

    -- 右
    p = {sltpoint[1], sltpoint[2]}
    if isInRange(p, ht) then -- 边是否存在
        if  not ht[p[1]][p[2]] then -- 且没有被画过
            table.insert(sltpoints, points[p[1]][p[2] + 1])
            table.insert(sltpointsindex, {p[1], p[2] + 1})
            isselectable = true
            -- print(p[1], p[2] + 1)
        end
    end

    -- 下
    p = {sltpoint[1], sltpoint[2]}
    if isInRange(p, vt) then -- 边是否存在
        if  not vt[p[1]][p[2]] then -- 且没有被画过
            table.insert(sltpoints, points[p[1] + 1][p[2]])
            table.insert(sltpointsindex, {p[1] + 1, p[2]})
            isselectable = true
            -- print(p[1] + 1, p[2])
        end
    end

    return isselectable, sltpoints, sltpointsindex

end

-- 判断某位置是否在一点的可点击范围内
function isInPointRegion(x, y)
    local d = 0

    for i = 1, r do
        for j = 1, c do
            d = math.pow(x - points[i][j][1], 2) + math.pow(y - points[i][j][2], 2)
            if d <= 400 then
                return true, i, j -- 返回结果 与 i j(坐标)!
            end
        end
    end
    return false, nil, nil
end

-- 改变能选择点的样式
function setPointsStyle(pointsindex, style)
    for i, v in ipairs(pointsindex) do
        pointsstyle[v[1]][v[2]] = style
    end
end

-- 更新 ht vt bt
function updataTable(p1, p2) -- 接收所画两点的索引
    local p
    isGoal = false

    if p1[1] == p2[1] then -- 两点的一维索引相同 说明画横线 
        p = {p1[1], math.min(p1[2], p2[2])}
        -- 更新 ht
        ht[p[1]][p[2]] = true

        -- 更新 bt
        if isInRange({p[1] - 1, p[2]}, bt) then 
            bt[p[1] - 1][p[2]] = bt[p[1] - 1][p[2]] + 1
            if bt[p[1] - 1][p[2]] == 4 then
                player_score[player] = player_score[player] + 1
                isGoal = true
            end
        end
        if isInRange(p, bt) then
            bt[p[1]][p[2]] = bt[p[1]][p[2]] + 1
            if bt[p[1]][p[2]] == 4 then
                player_score[player] = player_score[player] + 1
                isGoal = true
            end
        end

    else -- 说明画竖线
        p = {math.min(p1[1], p2[1]), p1[2]}
        -- 更新 vt
        vt[p[1]][p[2]] = true

        -- 更新 bt
        if isInRange({p[1], p[2] - 1}, bt) then
            bt[p[1]][p[2] - 1] = bt[p[1]][p[2] - 1] + 1
            if bt[p[1]][p[2] - 1] == 4 then
                player_score[player] = player_score[player] + 1
                isGoal = true
            end
        end
        if isInRange(p, bt) then
            bt[p[1]][p[2]] = bt[p[1]][p[2]] + 1
            if bt[p[1]][p[2]] == 4 then
                player_score[player] = player_score[player] + 1
                isGoal = true
            end
        end
    end
    -- print(bt[1][1], bt[1][2], bt[2][1], bt[2][2])
end

-- 画线
function drawLine(lt) -- 接收 真实坐标
    if #lt == 0 then
        return
    end

    love.graphics.setLineWidth(8)

    for i, v in ipairs(lt) do
        love.graphics.setColor(color[v[3]][1], color[v[3]][2], color[v[3]][3]) -- 改颜色
        love.graphics.line(v[1][1], v[1][2], v[2][1], v[2][2])
        -- print(v[1][1], v[1][2], v[2][1], v[2][2])
    end
end

function printText(text, x, y, font, color)
    love.graphics.setFont(font)
    love.graphics.setColor(color)
    love.graphics.print(text, x, y)
end

-- 绘制游戏区域
function drawPlayboard()
    -- 棋盘
    toybox.playboard(board[1], board[2], l, l)

    -- 处理画线任务
    drawLine(lt)

    -- 点阵
    toybox.pointmat(points, pointsstyle)
end

-- 判断某位置是否在菜单按钮的可点击范围内
function isInMenuRegion(x, y)

    if x >= w - 150 and x <= w then
        if y >= 250 and y <= 250 + 80 then -- 游戏模式
            return true, 1
        elseif y >= 350 and y <= 350 + 80 then -- again!
            return true, 2
        elseif y >= 450 and y <= 450 + 80 then -- rule?
            return true, 3
        end
    end

    if x >= 30 and x <= 30 + 100 and y >= 30 and y <= 30 + 55 then -- 点阵尺寸
        return true, 4
    end

    return false, 0
end

-- 画出菜单按钮
function drawMenu()
    -- game mode
    love.graphics.setColor(menucolor[1])
    love.graphics.rectangle("fill", w - 150, 250, 150, 80, 200/4, 100/4)
    printText("  "..game_mode, w - 140, 270, font_m, red)

    -- again!
    love.graphics.setColor(menucolor[2])
    love.graphics.rectangle("fill", w - 150, 350, 150, 80, 200/4, 100/4)
    printText("Again!", w - 140, 370, font_m, red)

    -- rule?
    love.graphics.setColor(menucolor[3])
    love.graphics.rectangle("fill", w - 150, 450, 150, 80, 200/4, 100/4)
    printText(" Rule?", w - 140, 470, font_m, red)

    -- 点阵尺寸
    love.graphics.setColor(menucolor[4])
    love.graphics.rectangle("fill", 30, 30, 100, 55)
    printText(r .. "×" .. c, 40, 40, font_m, red)
end

-- 打印得分
function printScore()
    -- player_score[1] = 10
    -- player_score[2] = 9
    local p1 = 55
    local p2 = 55
    if player_score[1] >= 10 then
        p1 = 0
    end
    if player_score[2] >= 10 then
        p2 = 0
    end
    printText(player_score[1], 70 + p1, h/2 - 110, font_l, red)
    printText("--",  70, h/2 - 50, font_l, red)
    printText(player_score[2], 70 + p2, h/2 + 10, font_l, red)

    printText("P1", 10, h/2 - 100, font_zh, red)
    printText("P2", 10, h/2 + 20, font_zh, red)
end

function showText()
    -- 得分
    printScore()

    -- 当前玩家
    love.graphics.setColor(orange_l)
    love.graphics.circle("fill", w/2 + 350, 60, 80)
    printText("P" .. player, w/2 + 300, 25, font_l, red)
end

-- 游戏重开初始化 一些变量的初始化
function gameInit()
    -- 全局变量
    -- 图像 尺寸 坐标
    r, c = pm[pm_i], pm[pm_i] -- 点阵尺寸
    w, h = love.graphics.getDimensions() -- 游戏窗口大小
    l = 2*w/4 -- 游戏区域大小
    crane = {height = 800}
    cranetween = tween.new(2, crane, {height = 0}, "outElastic")
    board = {(w - l)/2, (h - l)/2 + crane.height} -- 游戏区域左上坐标 in pixels
    l_help = {l, h - board[2]/2}
    board_help = {board[1], board[2]/8}
    points = getPoints(r, c, l, board) -- 点阵中点的 真实坐标


    player_num = 2 -- 玩家人数 
    player = 1 -- 当前玩家
    player_score = arrays(1, player_num, 0) -- 玩家得分
    color = {black, white, brown} -- 不同玩家 不同颜色 最后一种颜色用来标识上一次AI画的线
    menu_num = 4 -- 菜单数
    menucolor = arrays(1, menu_num, orange_l) -- 菜单键的背景色
    -- print(menucolor[3][1])

    -- 状态判断变量
    -- isInit = true -- 游戏初始化记录 这个变量暂时没有用到
    isFirst = true -- 是否点击的是一次连线选中的第一个点
    isselectable = false -- 某点是否可选中
    isGoal = false -- 是否发生得分
    isHelpPage = false -- 是否开启帮助页面

    -- 维护的表
    bt = arrays(r - 1, c - 1, 0) -- 记录每个方格的已画边数
    ht = arrays(r, c - 1, false) -- 横边的记录
    vt = arrays(r - 1, c, false) -- 竖边的记录
    lt = {} -- 画线的任务表 画线的两点坐标及画线的玩家
    pointsstyle = arrays(r, c, false) -- 点的样式 开与闭
    sltpoints = {} -- 选中一点后 下一个可选点的 真实坐标 in pixels
    sltpointsindex = {} -- 选中一点后 下一个可选点的 索引
end

-- 绘制帮助页面
function drawHelpPage()
    toybox.helpboard(board_help[1], board_help[2], l_help[1], l_help[2])
    printText("Dots and Boxes是数学家爱德华·卢卡\n\n斯在1891年发明的纸笔游戏.\n\n规则:非常简单,玩家双方轮流在两相邻\n\n格点画线,若4条线围成一方格,则该方格\n\n视为由添最后一笔围成方格的玩家所抢\n\n占,记1分.所有方格抢占完毕,分高者胜.\n\n·附加规则:成功抢占1方格的玩家必须\n\n  再进行一次画线.\n\n操作:左键选中,右键取消.\n\n说明:PvP-双人面战  PvA-与AI对战\n\nEnjoy;)", board_help[1] + 30, board_help[2] + 30, font_zh, black)
end

-- 人工智障1号
function AIaction()

    -- 先调整画线表 lt 把上一次AI画的线变白 这次新画的线是棕色的
    if #lt > 1 and lt[#lt][3] ~= 3 then
        for i, v in ipairs(lt) do
            if v[3] == 3 then
                v[3] = 2
            end
        end
    end

    local p1 = {}
    local p2 = {}

    -- 1.先看有没有已经画了3条边的方格 有则先抢方格
    for i, v in ipairs(bt) do
        for j, vv in ipairs(v) do
            if vv == 3 then -- 有三条边的方格
                if not vt[i][j] then 
                    p1 = {i, j}
                    p2 = {i + 1, j}
                elseif not ht[i][j] then
                    p1 = {i, j}
                    p2 = {i, j + 1}
                elseif not vt[i][j + 1] then
                    p1 = {i, j + 1}
                    p2 = {i + 1, j + 1}
                elseif not ht[i + 1][j] then
                    p1 = {i + 1, j}
                    p2 = {i + 1, j + 1}
                end

                table.insert(lt, {idx2axis(p1), idx2axis(p2), 3})
                updataTable(p1, p2)
                AIaction()
                return             
            end 
        end
    end

    -- 2.若不能抢到方格则随机找一条安全的边画(某方格已画的边少于2条, 且画线后没有3条边的方格产生)
    local AIchoice = {} -- 安全的选择
    local AItricky = {} -- 已画两条边方格的选择
    local p1p2 = {}
    local p1p2_tricky = {}

    for i, v in ipairs(ht) do -- 看能不能画安全的横线
        for j, vv in ipairs(v) do
            if not vv then
                p1 = {i, j}
                p2 = {i, j + 1}

                if (isInRange({p1[1] - 1, p1[2]}, bt) and bt[p1[1] - 1][p1[2]] == 2) or (isInRange(p1, bt) and bt[p1[1]][p1[2]]  == 2) then 
                    -- 不安全的横线
                    table.insert(AItricky, {idx2axis(p1), idx2axis(p2), 3})
                    table.insert(p1p2_tricky, {p1, p2})
                else -- 安全的横线
                    table.insert(AIchoice, {idx2axis(p1), idx2axis(p2), 3})
                    table.insert(p1p2, {p1, p2})
                end
            end
        end
    end
    
    for i, v in ipairs(vt) do -- 看能不能画安全的竖线
        for j, vv in ipairs(v) do
            if not vv then 
                p1 = {i, j}
                p2 = {i + 1, j}

                if (isInRange({p1[1], p1[2] - 1}, bt) and bt[p1[1]][p1[2] - 1] == 2) or (isInRange(p1, bt) and bt[p1[1]][p1[2]] == 2) then
                    -- 不安全的竖线
                    table.insert(AItricky, {idx2axis(p1), idx2axis(p2), 3})
                    table.insert(p1p2_tricky, {p1, p2})
                else -- 安全的竖线
                    table.insert(AIchoice, {idx2axis(p1), idx2axis(p2), 3})
                    table.insert(p1p2, {p1, p2})
                end
            end
        end
    end

    if #AIchoice ~= 0 then
        math.randomseed(tostring(os.time()):reverse():sub(1, 7)) -- 设置时间种子
        local rand = math.random(#AIchoice)

        table.insert(lt, AIchoice[rand])
        updataTable(p1p2[rand][1], p1p2[rand][2])
        if not isGoal then
            playerturn()
        end
        return
    end

    -- 3.必须要给某个方格添第三笔的情况 随机画线(太没策略了, 果然智障)
    if #AItricky ~= 0 then
        math.randomseed(tostring(os.time()):reverse():sub(1, 7)) -- 设置时间种子
        local rand = math.random(#AItricky)

        table.insert(lt, AItricky[rand])
        updataTable(p1p2_tricky[rand][1], p1p2_tricky[rand][2])
        if not isGoal then
            playerturn()
        end
        return
    end

    -- 到这里应该游戏结束了
end

function love.mousepressed(x, y, button, istouch)
    
    if button == 1 then -- 左键选中
        local isInRegion, i, j = isInPointRegion(x, y) -- 判断是否按下某个点
        if isInRegion and not isHelpPage then
            local isselectable, sltpoints_temp, sltpointsindex_temp = getSltpoints({i, j})--判断是否可选中

            if isselectable and isFirst then -- 第一次选中
                love.audio.play(onoff)
                isFirst = false
                sltpoints = sltpoints_temp -- 记录一下 第一次选中后能选的下一个点
                sltpointsindex = sltpointsindex_temp
                setPointsStyle(sltpointsindex, true) -- 改变能选点的样式
            elseif isselectable and not tablecmp({i, j}, sltpointsindex[1]) then -- 第二次选中且不是已经选中的 
                for k, v in ipairs(sltpointsindex) do
                    -- print(i, j, v[1], v[2])
                    if tablecmp({i, j}, v) then -- 选中的在备选名单 完成连线
                        love.audio.play(onoff)
                        isFirst = true
                        table.insert(lt, {sltpoints[1], sltpoints[k], player})
                        updataTable(sltpointsindex[1], v) -- 更新 ht vt bt
                        setPointsStyle(sltpointsindex, false)
                        if not isGoal then
                            playerturn()
                            if game_mode == "PvA" then
                                AIaction()
                            end
                        end
                        break
                    end

                end
            else
                -- print("error")
            end
        end

        local isOnMenu, menu_index = isInMenuRegion(x, y) -- 判断是否按下菜单键
        if isOnMenu then
            if menu_index == 1 then -- 模式切换
                if game_mode == "PvP" then
                    game_mode = "PvA"
                else
                    game_mode = "PvP"
                end
                gameInit()
                again:play()
                bgm:play()
            elseif menu_index == 2 then -- again!
                gameInit()
                again:play()
                bgm:play()
            elseif menu_index == 3 then -- rule?

                if isHelpPage then
                    isHelpPage = false
                    close:play()
                    bgm:play()
                else
                    isHelpPage = true
                    open:play()
                    bgm:pause()
                end
            elseif menu_index == 4 then -- 改变点阵尺寸
                pm_i = pm_i + 1
                if pm_i > #pm then
                    pm_i = 1
                end
                gameInit()
                again:play()
                bgm:play()
            end
        end
    elseif button == 2 then -- 右键取消
        if not isFirst and not isHelpPage then
            onoff:play()
            isFirst = true
            setPointsStyle(sltpointsindex, false)
        end

        if isHelpPage then
            isHelpPage = false
            close:play()
            bgm:play()
        end
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    local isOnMenu, menu_index = isInMenuRegion(x, y)
    local cursor
    if isOnMenu then
        menucolor[menu_index] = orange_h
        cursor = love.mouse.getSystemCursor("hand")
        love.mouse.setCursor(cursor)
    else
        menucolor = arrays(1, menu_num, orange_l)
        cursor = love.mouse.getSystemCursor("arrow")
        love.mouse.setCursor(cursor)
    end
end

function love.load()

    pm = {4, 5, 7, 9} -- 可选择的尺寸
    pm_i = 2 -- 当前尺寸的索引
    r, c = pm[pm_i], pm[pm_i] -- 点阵尺寸
    game_mode = "PvP" -- 游戏模式 目前只支持 PvP 与 PvA

    -- 常量 颜色
    red = {1, 0, 0}
    green = {40/255, 188/255, 30/255}
    orange_l = {244/255, 190/255, 66/255}
    orange_h = {255/255, 140/255, 0/255}
    brown = {186/255, 102/255, 0/255}
    black = {0, 0, 0}
    white = {1, 1, 1}
    bgc = {244/255, 212/255, 66/255} -- 界面背景色

    gameInit()

    -- 字体
    font = "font"
    font_l = love.graphics.newFont("Zpix.ttf", 90)
    font_m = love.graphics.newFont(font .. ".ttf", 40)
    font_s = love.graphics.newFont(font .. ".ttf", 15)
    font_zh = love.graphics.newFont("Zpix.ttf", 24)


    -- bgm
    bgm_name = "This World"
    bgm = love.audio.newSource("This World.mp3", "stream")
    bgm:setVolume(0.3)
    bgm:setLooping(true)
    love.audio.play(bgm)

    -- sound
    onoff = love.audio.newSource("onoff.wav", "static")
    close = love.audio.newSource("open.mp3", "static")
    open = love.audio.newSource("close.mp3", "static")
    again = love.audio.newSource("again.mp3", "static")

    -- pic
    Ed = love.graphics.newImage("Ed.png");
    -- Ed = love.graphics.newImage("v.jpg");
end

function love.update(dt)
    if crane.height ~= 0 then
        cranetween:update(dt)
        board = {(w - l)/2, (h - l)/2 + crane.height} -- 游戏区域左上坐标 in pixels
        l_help = {l, h - board[2]/2}
        board_help = {board[1], board[2]/4}
        points = getPoints(r, c, l, board) -- 点阵中点的 真实坐标
    end

end

function love.draw()
    -- 背景
    love.graphics.setBackgroundColor(bgc[1], bgc[2], bgc[3])


    if not isHelpPage then -- 没有打开帮助页面

        if game_mode == "PvA" then
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", w/2 - 130, h - 200, 256, 144)
            love.graphics.draw(Ed, w/2 - 130, h - 200)
        end

        -- 绘制游戏界面
        drawPlayboard()

        -- 对战信息文本
        showText()
    else -- 打开帮助页面
        drawHelpPage()
    end

    -- 绘制菜单
    drawMenu()

    -- 其他信息
    printText("BGM : " .. bgm_name, 30, h - 30, font_s, brown)
    printText("by Granvallen", w - 150, h - 30, font_s, brown)


end




