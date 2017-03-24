# Cocos2dx-lua-PageView
A PageView for cocos2dx in Lua Language

SAMPLE:
    local pv = common.PageView:create(cc.size(300, 300));
    pv:setPageCount(5);
    -- create your view here
    pv:registerScript(function(index)
        print("index", index);
        local sp = cc.Node:create();
        return sp;
    end, common.PageView.SCRIPT_DRAW_VIEW);
    pv:getView():setPosition(400,400);
    pv:make();
    scene:addChild(pv:getView());
