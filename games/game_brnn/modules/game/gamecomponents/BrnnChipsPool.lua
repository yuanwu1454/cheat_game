local BrnnChipsPool = class("BrnnChipsPool",function(paras)
    return paras.node
end)

local Card = import("..components.cards.Card")  
local IButton = import("..components.IButton")  
local Gameanimation = import("..components.animation.Gameanimation")
local GameAnimationConfig = import("..components.animation.AnimationConfig")
import(".BrnnChips")

BrnnChipsPool.TAG = "BrnnChipsPool"

function BrnnChipsPool:ctor(paras)
    self.winSize = cc.Director:getInstance():getWinSize()
    self.index = paras.index
    self.parent = paras.parent
    self.isBetTime = false
    self:init()
    BrnnChipManager:init()
end

function BrnnChipsPool:init()
    self.chips = {}
    self.recordChipsIndex = {}
    self:initTxt()
    self:initCards()
    self.img_jackpot = self:getChildByName("img_jackpot")
    self:initTouch()
    self:ready()
end

function BrnnChipsPool:initTouch()
    self:setTouchEnabled(true)
    self.clickMask = self:getChildByName("addChipsMask")
    addButtonEvent(self,function()
        self.clickMask:setVisible(false)

        if self.isBetTime == false and Cache.BrniuniuDesk.be_delaring == false then --自己是庄 不要提示
            qf.event:dispatchEvent(ET.GLOBAL_TOAST,{txt = BrniuniuTXT.br_bet_error3,time = 2})
        else
			if self.isBetTime == false then --非下注时间 禁止下注
				return
			end

            local leastMoney = Cache.BrniuniuDesk.min_bet_carry
            if  leastMoney > Cache.BrniuniuDesk.br_user[Cache.user.uin].chips then
                if not Cache.packetInfo:isShangjiaBao() then
                    qf.event:dispatchEvent(ET.GLOBAL_TOAST,{txt = string.format(BrniuniuTXT.LEASTTIP, Util:getFormatString(Cache.packetInfo:getProMoney(leastMoney)), Cache.packetInfo:getShowUnit())})
                    qf.event:dispatchEvent(ET.SHOP)
                else
                    qf.event:dispatchEvent(ET.NO_GOLD_TO_RECHARGE, {tipTxt = string.format(Util:getReviewStatus() and GameTxt.string_room_limit_5 or GameTxt.string_room_limit_4, Util:getFormatString(Cache.packetInfo:getProMoney(leastMoney)), Cache.packetInfo:getShowUnit()), confirmCallBack = function ( ... )
                        -- 发送退桌
                        if Util:getReviewStatus() then
                            qf.event:dispatchEvent(ET.SHOP)
                        else
                            qf.event:dispatchEvent(BRNN_ET.GAME_BRNN_EXIT_EVENT, {guidetochat = true})
                        end
                    end})
                end
                return
            end

            if Cache.BrniuniuDesk.brAddChooice == 0 then
                qf.event:dispatchEvent(ET.GLOBAL_TOAST,{txt = BrniuniuTXT.brnn_choose_bet_error})
                return
            end

            qf.event:dispatchEvent(BRNN_ET.BR_CLICK_POOL,{value = Cache.BrniuniuDesk.brAddChooice,index = self.index})
        end
    end,function ()
        self.clickMask:setVisible(self.isBetTime)
    end,nil,function ()
        self.clickMask:setVisible(false)
    end)
end

function BrnnChipsPool:setChipsCount(value,myself)
    if value == nil then return end
    self.chips_count = self.chips_count or 0
    self.myself_count = self.myself_count or 0
    self.chips_count = self.chips_count + value
    self:setChipsNum(self.chips_count)
    if myself == true then
        self.myself_count = self.myself_count + value
        self:setMyselfChips(self.myself_count)
    end
    Cache.BrniuniuDesk.br_all_chips[self.index] = self.chips_count --百人场下注的总数
    Cache.BrniuniuDesk.br_my_chips[self.index] = self.myself_count--自己下的注
end


function BrnnChipsPool:clearChipsCount()
    self.recordChipsIndex = {}
    local txt = self:getChildByName("chips_num")
    self.chips_count = 0
    txt:setString(" ")
end

function BrnnChipsPool:setMyselfChips(value)
    if value == nil then return end
    self.myself_count = value
    local txt = self:getChildByName("my_chips")
    txt:setString(value > 0 and Util:getOldFormatString(value) or " ")
end
function BrnnChipsPool:clearMyselfChips()
    local txt = self:getChildByName("my_chips")
    self.myself_count = 0
    txt:setString(" ")
end

function BrnnChipsPool:setChipsNum(value)
    if value == nil then return end
    local txt = self:getChildByName("chips_num")
    if Cache.packetInfo:isRealGold() then
        txt:setString(value <= 0 and " " or Util:getOldFormatString(tonumber(Util:NoRoundedOff(value, 0))))
    else
        txt:setString(value <= 0 and " " or Util:getOldFormatString(value))
    end
end

function BrnnChipsPool:chipsToPool(paras)
    if paras == nil then return end
    if paras.notadd ~= true then  self:setChipsCount(paras.value,paras.myself)  end
    local chips = BrnnChipManager:createT(paras.value)
    for k, chip in pairs(chips) do
        local x = self:getContentSize().width*(math.random(200,800)*0.001)
        local y = self:getContentSize().height*(math.random(300,750)*0.001) + 35
        local to = cc.p(self:getPositionX() + x,self:getPositionY() + y)
        local from = self.parent:convertToNodeSpace(paras.from)
        self.parent:addChild(chip)
        local chip2 = BrnnChipManager:getChip(chip.value)
        chip2:setPosition(cc.p(x,y))
        self:addChild(chip2,2)
        
        chip2:setVisible(false)
        local delay = (k - 1 ) * 0.02 >= 1 and 1 or (k - 1 ) * 0.02
        delay = delay > 0.15 and 0.15 or delay
        local index = #self.chips+1
        self.chips[index] = chip2
        
        if paras.noanimation then
            chip2:setVisible(true)
            BrnnChipManager:putChip(chip)
            return 
        end
        if paras.myself == true then
            self.recordChipsIndex[chip.value] = self.recordChipsIndex[chip.value] or {} 
            self.recordChipsIndex[chip.value][#self.recordChipsIndex[chip.value] + 1] = index 
        end
        BrnnChipManager:flyWithFixedTime(delay,chip,from,to, 0.3, function() 
            local c = chip2
            c:setVisible(true)
            -- local c = self.chips[index]
            -- if c ~= nil then 
            --     c:setVisible(c.isBeSign ~= true) 
            --     c.isBeSign = false
            -- end
        end)
    end
end

--给筹码池里面的筹码排序
function BrnnChipsPool:sortPoolChips()
    table.sort(self.chips, function (a,b)
            return a.value > b.value
    end)
end

function BrnnChipsPool:chipsFallBack(value)
    if not self.recordChipsIndex then return end
    local index = self.recordChipsIndex[value][#self.recordChipsIndex[value]]
    self.recordChipsIndex[value][#self.recordChipsIndex[value]] = nil
    if index == nil then return end
    local chip = self.chips[index]
    if chip == nil then return end
    self:setChipsCount(-chip.value,true)
    chip.isBeSign = true
    chip:setVisible(false)
end

function BrnnChipsPool:chipsToUser(paras) 
    if paras == nil then return end
    self:clearChipsCount()
    local value = paras.value
    local to = paras.to

    -- ADD-BEGIN by dantezhu, linke in 2015-12-15 18:36:57
    -- 之前的chips是没有从大到小排序的，而底下获取筹码的代码，是找到一个满足要求的就用，所以最后筹码分的有人分不到
    -- 所以我们对chips做了排序
    -- 而因为之前chips其实一直是当做字典来用得，直接排序是做不了的，所以先转为数组，再排序
    -- 之所以在这里来做排序，而不是在加注结束的位置，原因如下:
    -- 1. 因为chips这样排序之后是个数组，而底下还在用pairs和t[k]=nil来删除，而一旦这样做了，再用ipairs遍历就会中断
    -- 2. 下注结束的位置不好确定，因为jackpot又会有新的chips引入
    --
    -- 缺点就是，性能比较差，要排序 人数 * 区域数 次，先看看，不行再优化
    local chips_tab = {}
    for k,v in pairs(self.chips) do
        chips_tab[#chips_tab + 1] = v
    end
    table.sort(chips_tab, function (a,b)
            return a.value > b.value
    end)
    self.chips = chips_tab
    -- ADD-END

    if paras.all then
        local count = 1
        for k,v in pairs(self.chips) do
            if v.isBeSign ~= true then
                local from = cc.p(self:getPositionX()+v:getPositionX(),self:getPositionY()+v:getPositionY())
                local to = self.parent:convertToNodeSpace(to)
                local chip = BrnnChipManager:getChip(v.value)
                self.parent:addChild(chip)
                local delay = (count - 1 ) * 0.02 
                delay = delay > 0.15 and 0.15 or delay
                BrnnChipManager:fly(delay,chip,from,to, paras.cb)
                count = count + 1
            end
            BrnnChipManager:putChip(v)
            self.chips[k] = nil
        end
    end
    if value == nil or value == 0 or to == nil then return end
        local count = 1
        for k,v in pairs(self.chips) do
            if value < 1 then break end
            if value >= v.value then
                value = value - v.value
                local from = cc.p(self:getPositionX()+v:getPositionX(),self:getPositionY()+v:getPositionY())
                local to = self.parent:convertToNodeSpace(to)
                local chip = BrnnChipManager:getChip(v.value)
                BrnnChipManager:putChip(v)
                self.chips[k] = nil
                self.parent:addChild(chip)
                local delay = (count - 1 ) * 0.02 
                delay = delay > 0.15 and 0.15 or delay
                BrnnChipManager:fly(delay,chip,from,to, paras.cb)
                count = count + 1
            end
    end
end

function BrnnChipsPool:clearAllChips()
    self:clearChipsCount()
    if self.chips == nil or #self.chips == 0 then self.chips = {} return end
    for k , v in pairs(self.chips) do
        v:removeFromParent(true)
    end
    self.chips = {}
end

function BrnnChipsPool:showVictory()
    self:_addWinAnimation()
    self.isWinner = true
end

function BrnnChipsPool:_addWinAnimation ()
    self.winGameanimation     =  Gameanimation.new({view=self})  --初始化动画
    local face = self.winGameanimation:play({
        anim = GameAnimationConfig.WIN,
        scale = 2, 
        create = true,
        index = GameAnimationConfig.WIN.index, 
        layerOrder = 11,
        forever = true,
        position = {x = self:getContentSize().width/2, y = self:getContentSize().height/2 + 45}
    })
    local ani = face:getAnimation()
    ani:setMovementEventCallFunc(function ()
        ani:gotoAndPlay(55)
    end)

    self._winAni = face
    MusicPlayer:playMyEffectGames(BrniuniuRes,"WIN_MONEY")
end

function BrnnChipsPool:removeWinAni()
    if self._winAni == nil or tolua.isnull(self._winAni) == true then
        return
    end
    --由于winani是挂在一个新建的layer上面所以还要删除对应的winani
    local node = self._winAni:getParent()
    node:removeFromParent(true)
end


function BrnnChipsPool:initCards()
    for i = 1 ,5 do
        self["c"..i] = self:getChildByName("delar_card_"..i)
        self["c"..i]:setVisible(false)
    end
end

function BrnnChipsPool:initTxt()
    local nameT = {"chips_num","my_chips"}
    for k,v in pairs(nameT) do
        self[v] = self:getChildByName(v)
        self[v]:setString(" ")
    end
end

function BrnnChipsPool:clearAll()
    local txtT = {"chips_num","my_chips"}
    for k, v in pairs(txtT) do
        self[v]:setString(" ")
    end
end

function BrnnChipsPool:giveCards(delay,cdelay,dpoint)
    delay = delay or 0
    cdelay = cdelay or 0
    self:clearCards()
    self.cards = {}
    for i = 1, 5 do
        local card = Card.new()
        self:addChild(card)
        Util:giveCardsAnimation({first = self.c1,delay = (i-1)*cdelay+delay,parent = self,c1 = self["c"..i],z = 2,c2 = card,dpoint = dpoint})
        self.cards[i] = card
    end
end

function BrnnChipsPool:showCards(delay,cdelay,dpoint)
    delay = delay or 0
    cdelay = cdelay or 0
    self:clearCards()
    self.cards = {}
    for i = 1, 5 do
        local card = Card.new()
        self:addChild(card)
        card:setScale(self["c"..i]:getScale())
        card:setLocalZOrder(2)
        card:setPosition(self["c"..i]:getPositionX(),self["c"..i]:getPositionY())
        self.cards[i] = card
    end
end

function BrnnChipsPool:reverseCards(delay,cb)
    for i = 1, 6 do
        local card = self.cards[i]
        if card == nil then
            self:delayRun(delay+0.3,function()
                self:showCardInfo()
                if cb then cb() end
            end)
        else
            self:delayRun(delay,function() 
                MusicPlayer:playMyEffect("FAPAI")
                card.value = Cache.BrniuniuDesk.br_pool[self.index].cards[i]
                if card.reverseSelf then
                    card:runAction(cc.Sequence:create(
                        cc.DelayTime:create(0.017),
                        cc.CallFunc:create(function ( ... )
                            card:reverseSelf(nil,Cache.BrniuniuDesk.br_pool[self.index].cards[i])
                            if i == #self.cards then
                                --只要是对应区域赢了 就播放胜利的特效 不管是不是庄家 看到的都是一样的
                                local uin = Cache.BrniuniuDesk.br_delar.uin
                                local flag = Cache.BrniuniuDesk:getPlayerPoolAreaResult(self.index, uin)
                                if Cache.user.uin == uin then
                                    flag = not flag
                                end
                                if not flag then
                                    self:delayRun(0.2, function ()
                                        self:showVictory()
                                    end)
                                end
                            end
                        end)
                    ))
                end
            end)
        end
    end 
end

function BrnnChipsPool:delayRun(time,cb)
    local action = cc.Sequence:create(
        cc.DelayTime:create(time),
        cc.CallFunc:create(function (  )
            if cb then cb() end
        end)
    )
    self:runAction(action)
end

function BrnnChipsPool:clearCards(bCloudCard)
    if self.cards == nil or #self.cards == 0 or (bCloudCard and bCloudCard == true) then return end
    for k, v in pairs(self.cards) do
        v:removeFromParent(true)
    end
    self.cards = {}
end

function BrnnChipsPool:updateTrend()
    local trend_layer = self:getChildByName("trand_layer")
    local historyInfo = Cache.BrniuniuInfo:getHistoryBySection(self.index)
    if historyInfo == nil then return end
    local count_index = 1
    for index= #historyInfo - 8 + 1, #historyInfo do
        local trendNode= trend_layer:getChildByName("trand_" .. count_index)
        if trendNode then

            if historyInfo[index] then
                odds = historyInfo[index].odds
            else
                odds = -1
            end
            trendNode:loadTexture(odds > 0 and BrniuniuRes.trend_win or BrniuniuRes.trend_lose)
            if index == #historyInfo then
                trend_layer:getChildByName("lasted_trend_mask"):loadTexture(odds > 0 and BrniuniuRes.trend_win_mask or BrniuniuRes.trend_lose_mask)
            end
        end
        count_index = count_index + 1
    end
end

function BrnnChipsPool:showCardInfo()
    local isWinner
    if not Cache.BrniuniuDesk.br_result or not Cache.BrniuniuDesk.br_result[self.index] 
        or not Cache.BrniuniuDesk.br_result[self.index][1] 
        or not Cache.BrniuniuDesk.br_result[self.index][1].odds then
        isWinner = false
    else
        isWinner = Cache.BrniuniuDesk.br_result[self.index][1].odds > 0
        if Cache.BrniuniuDesk.br_delar.uin == Cache.user.uin then
            isWinner = not isWinner
        end
    end

    local ty = BrniuniuRes.br_game_card_type_10
    if Cache.BrniuniuDesk:getRoomType() == 14 then    -- 3人场
        ty = BrniuniuRes.br_game_card_type
    end

    local res = string.format(ty, Cache.BrniuniuDesk.br_pool[self.index].card_type, Cache.BrniuniuDesk.br_pool[self.index].card_type == 0 and 0 or 1)
    local txt = self:getChildByName("card_type")
    txt:setVisible(true)
    txt:getChildByName("bg"):setVisible(false)
    -- txt:getChildByName("bg"):loadTexture(string.format(BrniuniuRes.br_game_card_type_bg, Cache.BrniuniuDesk.br_pool[self.index].card_type == 0 and 0 or 1),ccui.TextureResType.plistType)
    txt:getChildByName("type"):loadTexture(res,ccui.TextureResType.plistType)
    MusicPlayer:playMyEffectGames(BrniuniuRes, string.format("NIU_%d_%d",1, Cache.BrniuniuDesk.br_pool[self.index].card_type))
end

function BrnnChipsPool:hideCardInfo()
    self:getChildByName("card_type"):setVisible(false)
end

function BrnnChipsPool:betTime()
    
end

function BrnnChipsPool:restTime()
    self.clickMask:setVisible(false)
end

function BrnnChipsPool:showResult(delarIsme)
    local info = Cache.BrniuniuDesk.self_result[self.index]
    local bei_txt = self:getChildByName("bei_txt")
    bei_txt:setVisible(true)
    if not info or not info.odds then 
        bei_txt:setVisible(false)
    else
        bei_txt:setVisible(false)
        bei_txt:setFntFile(BrniuniuRes.bei_fnt)
        local odds = info.odds
        if Cache.BrniuniuDesk.br_delar.uin == Cache.user.uin then
            odds = -odds
        end
        if odds > 0 then
            bei_txt:setString(string.format("X %d", odds))
        else
            bei_txt:setString(string.format("X %d", math.abs(odds)))
        end
    end
end

function BrnnChipsPool:ready(bCloudCard)
    self:restTime()
    self:clearCards(bCloudCard)
    self:hideCardInfo()
    self:clearAllChips()
    self:clearMyselfChips()
    self:getChildByName("my_chips"):setString(" ")
    self:getChildByName("bei_txt"):setVisible(false)
    self.img_jackpot:setVisible(false)
    self.isWinner = false
end

return BrnnChipsPool
