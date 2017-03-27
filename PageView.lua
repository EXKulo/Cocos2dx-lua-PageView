local PageView = {};
PageView = class("PageView");

local CHILD_NAME_INNER_VIEW = "childNameInner";
local AUTO_TURN_PAGE_DURATION = 0.3;

PageView.SCRIPT_DRAW_VIEW = 1;

--- view
-- @field [parent=#PageView] ScrollView#ScrollView view
PageView.view = nil;
--- pageSize
-- @field [parent=#PageView] Size#Size pageSize
PageView.pageSize = nil;
--- pageNodes
-- @field [parent=#PageView] #table pageNodes
PageView.pageNodes = nil;
--- pageCount
-- @field [parent=#PageView] #number pageCount
PageView.pageCount = nil;

function PageView:ctor(size)
    self.pageSize = size;
    self.view = cc.ScrollView:create(self.pageSize);
    self.view:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL);
    self:clearPages();
end

---@function [parent=#PageView] create
-- @param self
-- @param Size#Size
-- @return PageView#PageView
function PageView:create(size)
    return PageView.new(size);
end

--- description
-- @function [parent=#PageView] getView
-- @param self
function PageView:getView()
    return self.view;
end

--- @function [parent=#PageView] setPageCount
-- @param self
-- @param #number count
function PageView:setPageCount(count)
    if count == nil or count < 1 then
        count = 0;
    end
    self.pageCount = count;
    return self;
end

--- @function [parent=#PageView] clearPages
-- @param self
function PageView:clearPages()
    if self.pageNodes ~= nil then
        for _, pageNode in ipairs(self.pageNodes) do
            pageNode:removeFromParent();
        end
    end
    self.pageNodes = {};
    self.scripts = {};
end

--- @function [parent=#PageView] make
-- @param self
function PageView:make()
    for _, pageNode in ipairs(self.pageNodes) do
        pageNode:removeFromParent();
    end
    self.pageNodes = {};
    if self.pageCount < 1 then
        return;
    end
    self.view:setContentSize(cc.size(self.pageSize.width * self.pageCount, self.pageSize.height));
    for index = 1, self.pageCount do
        local pageNode = cc.Node:create();
        pageNode:setPosition((index - 0.5) * self.pageSize.width, self.pageSize.height / 2);
        table.insert(self.pageNodes, pageNode);
        self.view:addChild(pageNode);
        if index <= 2 then
            local innerView = self:gennerateInner(index);
            pageNode:addChild(innerView);
        end
    end
    self.view:setContentOffset(cc.p(0, 0));
    self:setAutoTurn();
end

--- @function [parent=#PageView] gennerateInner
-- @param self
function PageView:gennerateInner(index)
    local getViewFunc = self.scripts[PageView.SCRIPT_DRAW_VIEW] or function()
        return cc.Node:create();
    end
    local innerView = getViewFunc(index);
    innerView:setName(CHILD_NAME_INNER_VIEW);
    return innerView;
end

--- @function [parent=#PageView] registerScript
-- @param self
function PageView:registerScript(script, scriptId)
    self.scripts[scriptId] = script;
    return self;
end

--- @function [parent=#PageView] turnTo
-- @param self
-- @param #number pageNo
-- @param #boolean isSmooth
function PageView:turnTo(pageNo, isSmooth)
    if pageNo > self.pageCount then
        pageNo = self.pageCount;
    end
    if pageNo <= 0 then
        pageNo = 1;
    end
    local posX = (pageNo - 1) * self.pageSize.width;
    posX = -posX;
    if isSmooth then
        self.view:setContentOffsetInDuration(cc.p(posX, 0), AUTO_TURN_PAGE_DURATION);
        local delay = cc.DelayTime:create(AUTO_TURN_PAGE_DURATION + 0.1);
        local callFunc = cc.CallFunc:create(function()
            self:autoRecycle();
        end);
        local sequence = cc.Sequence:create(delay, callFunc);
        self.view:runAction(sequence)
    else
        self.view:setContentOffset(cc.p(posX, 0));
        self:autoRecycle();
    end
end

--- @function [parent=#PageView] getCurPageNo
-- @param self
function PageView:getCurPageNo()
    local truePosX = -self.view:getContentOffset().x;
    for i = 1, self.pageCount do
        if truePosX < i * self.pageSize.width then
            return i;
        end
    end
    return 0;
end

--- @function [parent=#PageView] autoRecycle
-- @param self
function PageView:autoRecycle()
    local curPageNo = self:getCurPageNo();
    local leftPageNo = curPageNo - 1;
    local rightPageNo = curPageNo + 1;
    for index = 1, self.pageCount do
        if index == curPageNo or index == leftPageNo or index == rightPageNo then
            self:checkAndMakeInner(index);
        else
            self:clearNode(index);
        end
    end
end

--- @function [parent=#PageView] clearNode
-- @param self
function PageView:clearNode(index)
    local pageNode = self.pageNodes[index];
    local innerNode = pageNode:getChildByName(CHILD_NAME_INNER_VIEW);
    if innerNode ~= nil then
        innerNode:removeFromParent();
    end
end

--- @function [parent=#PageView] checkAndMakeInner
-- @param self
function PageView:checkAndMakeInner(index)
    local pageNode = self.pageNodes[index];
    if pageNode:getChildByName(CHILD_NAME_INNER_VIEW) ~= nil then
        return;
    end
    local innerNode = self:gennerateInner(index);
    pageNode:addChild(innerNode);
end

--- @function [parent=#PageView] setAutoTurn
-- @param self
function PageView:setAutoTurn()
    self.view:setTouchEnabled(false);
    self.view:setBounceable(false);
    local beginPosX = 0;
    local beginContentOffsetX = 0;
    local onTouchEnd = function()
        local offset = self.view:getContentOffset();
        local trueOffsetX = -offset.x;
        for i = 0, self.pageCount do
            if trueOffsetX < i * self.pageSize.width then
                if trueOffsetX >= (i - 0.5) * self.pageSize.width then
                    self:turnTo(i+1, true);
                else
                    self:turnTo(i, true);
                end
                break;
            end
        end
    end
    local function onTouchBegan(touch, event)
        beginPosX = touch:getLocation().x;
        beginContentOffsetX = self.view:getContentOffset().x;
        return true;
    end
    local function onTouchMoved(touch, event)
        local curPosX = touch:getLocation().x;
        local offsetX = curPosX - beginPosX;
        if math.abs(offsetX) < self.pageSize.width then
            self.view:setContentOffset(cc.p(beginContentOffsetX + offsetX, 0));
        end
        return true;
    end
    local listener = cc.EventListenerTouchOneByOne:create();
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN);
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED );
    listener:registerScriptHandler(onTouchEnd,cc.Handler.EVENT_TOUCH_ENDED);
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self.view);
end

return PageView;
