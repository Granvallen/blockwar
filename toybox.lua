local toybox = {}

-- 画出游戏区域
function toybox.playboard(x, y, width, height)
    love.graphics.setColor(244/255, 190/255, 66/255)
    love.graphics.setLineWidth(20)
    love.graphics.line(x + 90, 0, x + 90, 2*y + height + 800)
    love.graphics.line(x + width - 90, 0, x + width - 90, 2*y + height + 800)
    love.graphics.rectangle("fill", x, y, width, height, width/10, height/10)
end

-- 画帮助页面的文字区域
function toybox.helpboard(x, y, width, height)
    love.graphics.setColor(244/255, 190/255, 66/255)
    love.graphics.rectangle("fill", x, y, width, height, width/10, height/10)
end

-- 画出点阵
function toybox.pointmat(points, pointsstyle)
    local radius = 12
    local pointstyle = "line"

    for i = 1, r do
        for j = 1, c do
            love.graphics.setColor(255/255, 140/255, 0/255)
            love.graphics.circle("fill", points[i][j][1], points[i][j][2], radius)
            if pointsstyle[i][j] then
                pointstyle = "fill"
            else
                pointstyle = "line"
            end
            love.graphics.setColor(255/255, 0/255, 0/255)
            love.graphics.setLineWidth(2)
            love.graphics.circle(pointstyle, points[i][j][1], points[i][j][2], radius - 3)
        end
    end
end



return toybox