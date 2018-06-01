
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local net = require("app.models.net.gameNet"):new()



--MainScene.RESOURCE_FILENAME = "MainScene.csb"

function MainScene:onCreate()


    self.uiPage = require("MainScene").create(function (path, node, funcName)
        return function(...) 
            if self[funcName] and type(self[funcName]) == "function" then
                self[funcName](self, ...)
            else
                print(string.format("[%s -> %s]: %s方法未实现", path, node:getName(), funcName))
            end
        end
    end)
    self:addChild(self.uiPage.root)

    self.uiPage.root:setContentSize(cc.Director:getInstance():getVisibleSize())
    ccui.Helper:doLayout(self.uiPage.root)

    ----------------------------------------------------
    self.editBox = self:StudioTextFieldCreateEdit(self.uiPage.TextField, nil, "Default/Button_Disable.png")

    self.editBox_IP = self:StudioTextFieldCreateEdit(self.uiPage.TextField_IP, nil, "Default/Button_Disable.png")

    self.editBox_IP:setText("120.79.31.64")


    ----------------------------------------------------
    local listView = self.uiPage.ListView

    local t = listView:getChildByName("Text")
    t:retain()
    t:removeFromParent()
    t:setVisible(false)
    self:addChild(t)
    t:release()
    listView:removeAllItems()

    local count = 0

    local function pushListMsg(msg)
        count = count + 1

        if count >= 100 then
            listView:removeItem(0)
            count = count - 1
        end
        local l = t:clone()
        l:setString(msg)
        l:setVisible(true)
        listView:pushBackCustomItem(l)
        listView:jumpToBottom()
    end

    ----------------------------------------------------
    net:register("connect", function()
        pushListMsg("net: connect")
    end)
    net:register("net.speak", function(data)
        pushListMsg(data.content)
    end)
    net:register("disconnect", function()
        pushListMsg("net: disconnect")
    end)

    --self:initHero()
end

function MainScene:initHero()
    -- ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo("hero/hero_lanse_dao.ExportJson")
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("hero/hero_lanse_dao.ExportJson")
    
    local winSize = cc.Director:getInstance():getVisibleSize()

    local armature = ccs.Armature:create("hero_lanse_dao")
    armature:getAnimation():playWithIndex(0)
    armature:setPosition(cc.p(winSize.width * 0.5, winSize.height * 0.5))
    self:addChild(armature)

    local boneDic = armature:getBoneDic()
    for k,v in pairs(boneDic) do
        print(tostring(k), " = ",tostring(v))
    end

    local data = armature:getArmatureData()
    print("data = ", data)
    print(data.name)

    data = armature:getAnimation():getAnimationData()
    print("data = ", data)
    print(data:getMovementCount())

    self.animation = armature:getAnimation()
    self.movementCount = data:getMovementCount()
    self.curMovementCount = 0

--getMovementCount

--getArmatureData
    --getAnimationData
end


function MainScene:onClickSend(sender)

    self.curMovementCount = self.curMovementCount + 1
    if self.curMovementCount >= self.movementCount then
        self.curMovementCount = 0
    end
    self.animation:playWithIndex(self.curMovementCount)


    -- local str = self.editBox:getText()
    -- if str ~= "" then
    --     local m = { content = str }
    --     net:sendMsgToGame("net.speak", m)
    -- end
end

function MainScene:onClickConnect()
    
    local ip = self.editBox_IP:getText()

    net:connect(ip, 1234)
end

--根据依赖编辑器中编辑框某些属性创建编辑框
--1需要替换的节点 2代理表(事件来时代理表[callname](代理表,...)) 3编辑框背景图片 nil
function MainScene:StudioTextFieldCreateEdit(TextField,HandleTable,backImagePath)

    -- if type(TextField) ~= "userdata" or tolua.type(TextField) ~= "ccui.TextField" then
    --     printError("传入节点错误导致创建失败TextField = ",tolua.type(TextField).."ParentName = "..TextField:getParent():getName())
    --     return nil
    -- elseif type(HandleTable) ~= "table" and type(HandleTable) ~= "userdata" then
    --     printError("代理表错误,请传入一个table表")
    --     return nil
    -- end

    --dump({TextField,HandleTable,backImagePath,type(TextField),tolua.type(TextField)})
    local TextFieldSize = TextField:getContentSize()
    if TextFieldSize.height > TextField:getFontSize() * 1.5 then
    else
        TextFieldSize.height = TextFieldSize.height * 1.5
    end
    local Edit = ccui.EditBox:create(TextFieldSize,backImagePath or "")--创建编辑框

    --拷贝属性
    --Edit:setIgnoreAnchorPointForPosition(false)
    Edit:setAnchorPoint(TextField:getAnchorPoint())
    Edit:setPosition(TextField:getPosition())
    Edit:setTag(TextField:getTag())
    Edit:setName(TextField:getName())
    Edit:setText(TextField:getString())
    Edit.PlaceholderFontSize = TextField:getFontSize()
    Edit:setPlaceholderFontSize(Edit.PlaceholderFontSize)--自动设置默认值的字体大小

    Edit.getPlaceholderFontSize = function (edit) return edit.PlaceholderFontSize end
    Edit:setPlaceHolder(TextField:getPlaceHolder())
    Edit:setMaxLength(TextField:getMaxLength())
    Edit._setMaxLength = function (self,MaxLength)
        self.MaxLength = MaxLength or self:getMaxLength()
        self:setMaxLength(100000)
    end
    Edit._getMaxLength = function (self)
        return self.MaxLength
    end
    --Edit:setMaxLength(TextField:getMaxLength())
    Edit:setPlaceholderFontColor(TextField:getColor())
    Edit:setFontName(TextField:getFontName())
    Edit:setFontSize(Edit.PlaceholderFontSize - 2)
    Edit.callbackname = TextField:getCallbackName()
    Edit:setCallbackName(Edit.callbackname)
    local ParentNode = TextField:getParent()
    Edit:registerScriptEditBoxHandler(function (eventName, sender)
        return true
        -- Edit.Type = eventName
        -- if eventName == "began" then
        --     Edit.__StartInText = true
        -- elseif (eventName == "ended" or eventName == "return") then
        --      tools.IntervalCallback(ParentNode,2,function ( ... )
        --         Edit.__StartInText = nil
        --         return false
        --     end)

        -- end
        -- -- if Edit.callbackname and type(HandleTable[Edit.callbackname]) == "function" then
        -- --     HandleTable[Edit.callbackname](HandleTable,eventName, sender)
        -- -- else--if _MyG.debug == true then
        -- --     --没有设置回调处理事件，或者代理表没有实现回调处理函数
        -- --     print(Edit.callbackname)
        -- -- end
    end)
    TextField:removeFromParent()
    ParentNode:addChild(Edit)
    --设置默认值
    Edit:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    return Edit
end

return MainScene