--------------------------------------------------------------------------------
-- 2020/06/15 created, 2020/06/23 refactored
--[[----------------------------------------------------------------------------
점들 (x1,y1)-(x2,y2)- ... -(xn,yn)-(x1,y1) 을 연결한 폐곡면을 그린다.
(주의) 아래 pts에서는 x1,y1 부터 ** xn,yn 까지만 ** 저장되어 있어야 한다.
pts = {x1,y1, x2,y2, ..., xn,yn } 
opt = {
    sw -- (required) strokewidth
    sc -- (required) strokecolor
    fc -- (required) fillcolor
}
The anchor point is located at the origin (0,0) point.
------------------------------------------------------------------------------]]
if _Gideros then
    --------------------------------------------------------------------------------
        local GShape = _Gideros.Shape
    
        function _luasopia.mkshape(pts, opt)
    
            local xs, ys = pts[1], pts[2]
            local s = GShape.new()
    
            s:setLineStyle(opt.sw, opt.sc.hex, opt.sc.a) -- width, color, alpha
            s:setFillStyle(GShape.SOLID, opt.fc.hex, opt.fc.a)
            
            s:beginPath()
            s:moveTo(xs, ys) -- starting at upmost point
            for k=1,#pts,2 do s:lineTo(pts[k], pts[k+1]) end
            s:lineTo(xs, ys) -- ending at the (first) starting point
            s:endPath()
            -- gideros의 shape는 자동으로 원점(0,0)이 anchor point가 된다
            --s:setPosition(self.__apx or 0, self.__apy or 0)
            ------------------------------------------------------------------------
            return s
        end
        
    --------------------------------------------------------------------------------
    elseif _Corona then
    --------------------------------------------------------------------------------
        
        local newPoly = _Corona.display.newPolygon
        
        -- function Shp:init(pts, opt)
        function _luasopia.mkshape(pts, opt)
    
            local x, y = pts[1], pts[2]
            local xmin,ymin,  xmax,ymax = x,y,  x,y
            for k=3,#pts,2 do
                x, y = pts[k], pts[k+1]
                if x<xmin then xmin = x elseif x>xmax then xmax = x end
                if y<ymin then ymin = y elseif y>ymax then ymax = y end
            end
            
            local s = newPoly(0, 0, pts)
            -- solar2d의 폴리곤은 자동으로 중심점에 anchor가 위치한다.
            -- 그래서 아래와 같이 anchor point를 원점(0,0)으로 만든다.
            s.anchorX = -xmin/(xmax-xmin) --(0-xmin)/(xmax-xmin)
            s.anchorY = -ymin/(ymax-ymin) --(0-ymin)/(ymax-ymin)
            
            local sc = opt.sc
            local fc = opt.fc
            s.strokeWidth = opt.sw
            s:setStrokeColor(sc.r, sc.g, sc.b, sc.a)
            s:setFillColor(fc.r, fc.g, fc.b, fc.a)
            ------------------------------------------------------------------------
            return s
        end
        
    end -- elseif _Corona then
    
    
    --------------------------------------------------------------------------------
    -- 2020/06/15: first created
    -- 2021/05/07: added __redraw__() method 
    --------------------------------------------------------------------------------
    local Rawshape = _luasopia.Rawshape
    local WHITE = Color.WHITE -- default stroke/fill color
    local mkshp = _luasopia.mkshape
    local Disp = Display
    --------------------------------------------------------------------------------
    Shape = class(Disp)
    local newGrp
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    if _Gideros then
    
        newGrp = _Gideros.Sprite.new
    
        function Shape:__addshp__()
    
            local shp = mkshp(self.__pts, self.__sopt)
    
            self.__bd:addChild(shp)
    
            self.__shp = shp
            shp:setX( self.__xmn*(self.__apx-1) - self.__xmx*self.__apx )
            shp:setY( self.__ymn*(self.__apy-1) - self.__ymx*self.__apy )
    
            return self
    
        end
    
        -- 2021/05/07 : add clear and add in one method
        function Shape:__redraw__()
    
            --(1) (clear) 그룹 내의 모든 객체는 지운다
            if self.__bd:getNumChildren() == 1 then -- shape이 딱 하나일 경우
                self.__bd:getChildAt(1):removeFromParent()
            else
                for k = self.__bd:getNumChildren(),1,-1 do
                    self.__bd:getChildAt(k):removeFromParent() -- 모든 차일드 삭제
                end
            end
    
            -- (2) (add new)
            return self:__addshp__()
    
        end
    
        --2021/05/31 : Shpae객체의 anchor point를 변경하기 위한 메서드들
        -- self.__shp의 (parent group내에서의) 위치를 바꿔주는 방식으로 변경
        -- (Shape객체는) self.__xmn, __xmx, __ymn, __ymx값들이 반드시 필요하다.
        function Shape:setanchor(apx, apy)
    
            self.__apx, self.__apy = apx, apy
            self.__shp:setX( self.__xmn*(apx-1) - self.__xmx*apx )
            self.__shp:setY( self.__ymn*(apy-1) - self.__ymx*apy )
            return self
    
        end
    
        -- 2021/05/31: globalxy는 __bd가 아니라 __shp에서 구해야 한다
        function Display:getglobalxy(x,y)
    
            return self.__shp:localToGlobal(x or 0,y or 0)
    
        end
    
    --------------------------------------------------------------------------------
    elseif _Corona then
    --------------------------------------------------------------------------------
    
        newGrp = _Corona.display.newGroup
    
        function Shape:__addshp__()
    
            local shp = mkshp(self.__pts, self.__sopt)
            self.__bd:insert(shp)
    
            self.__shp = shp
            shp.x = self.__xmn*(self.__apx-1) - self.__xmx*self.__apx
            shp.y = self.__ymn*(self.__apy-1) - self.__ymx*self.__apy
    
            return self
    
        end
    
        -- 2021/05/07 : add clear and add in one method
        function Shape:__redraw__()
    
            --(1) 그룹 내의 모든 객체는 지운다(clear)\
            if self.__bd.numChildren == 1 then -- shape이 딱 하나일 경우
                self.__bd[1]:removeSelf()
            else
                for k = self.__bd.numChildren, 1, -1 do
                    self.__bd[k]:removeSelf() -- 차일드 각각의 소멸자 호출(즉시 삭제)
                end    
            end
    
            return self:__addshp__()
    
        end
    
    
        --2021/05/31 : Shpae객체의 anchor point를 변경하기 위한 메서드들
        -- self.__shp의 (parent group내에서의) 위치를 바꿔주는 방식으로 변경
        function Shape:setanchor(apx, apy)
    
            self.__apx, self.__apy = apx, apy
            self.__shp.x = self.__xmn*(apx-1) - self.__xmx*apx
            self.__shp.y = self.__ymn*(apy-1) - self.__ymx*apy
            return self
    
        end
    
    
        -- 2021/05/31: globalxy는 __bd가 아니라 __shp에서 구해야 한다
        function Display:getglobalxy(x,y)
    
            return self.__shp:localToContent(x or 0, y or 0)
    
        end
    
    
    end
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    function Shape:init(pts, opt)
    
        self.__apx, self.__apy = 0.5, 0.5 -- AnchorPointX, AnchorPointY
    
        self.__pts = pts
    
        if opt == nil then
            self.__sopt = {sw=0, sc=WHITE, fc=WHITE}
        else
            self.__sopt = {
                sw = opt.strokewidth or 0,
                sc = opt.strokecolor or WHITE,
                fc = opt.fill or opt.fillcolor or WHITE,
            }
        end
    
        self.__bd = newGrp()
        self:__addshp__()
    
        return Disp.init(self)
        
    end
    
    
    
    function Shape:fill(color)
    
        self.__sopt.fc = color
        return self:__redraw__()
    
    end
    
    
    function Shape:setstrokewidth(sw)
    
        self.__sopt.sw = sw
        return self:__redraw__()
    
    end
    
    
    function Shape:setstrokecolor(color)
    
        self.__sopt.sc = color
        return self:__redraw__()
    
    end
    
    
    function Shape:empty()
    
        self.__sopt.fc = Color(0,0,0,0)
        return self:__redraw__()
    
    end
    
    if _Gideros then
        
        
    
    elseif _Corona then
    
    
    
    end
    
    
    function Shape:getanchor()
    
        return self.__apx, self.__apy
    
    end
    
    
    -- 2021/05/04에 추가
    
    Shape.strokewidth = Shape.setstrokewidth
    Shape.strokecolor = Shape.setstrokecolor
    Shape.anchor = Shape.setanchor
    
    Shape.fillcolor = Shape.fill -- 삭제예정
    
    --------------------------------------------------------------------------------
    -- 2020/06/13 Rawshape 클래스는 lib.Tail 클래스에서 사용됨
    --------------------------------------------------------------------------------
    
    local mkshp = _luasopia.mkshape
    local Disp = Display
    
    _luasopia.Rawshape = class(Disp)
    
    function _luasopia.Rawshape:init(pts, opt)
        self.__bd = mkshp(pts, opt)
        return Disp.init(self)
    end