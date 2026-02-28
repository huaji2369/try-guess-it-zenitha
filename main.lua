require"Zenitha"
GC.setDefaultFilter('linear','nearest')
STRING.installIndex()
SCR.setSize(720,1280)
SCN.setDefaultSwap('none')
ZENITHA.globalEvent.drawCursor=NULL
ZENITHA.globalEvent.keyDown=NULL

BGM.load{
    title ="bgm/title.ogg",
    main  ="bgm/main.ogg",
    main2 ="bgm/main2.ogg",
    trophy="bgm/trophy.ogg",
}

SFX.load{
    key1='sfx/1.mp3',
    key2='sfx/2.mp3',
    key3='sfx/3.mp3',
    key4='sfx/4.mp3',
    key5='sfx/5.mp3',
    key6='sfx/6.mp3',
    key7='sfx/7.mp3',
    key8='sfx/8.mp3',
    key9='sfx/9.mp3',
    key0='sfx/0.mp3',
    del_1='sfx/del_1.mp3',
    del_2='sfx/del_2.mp3',
    del_3='sfx/del_3.mp3',
    del_4='sfx/del_4.mp3',
    error='sfx/error.mp3',
    check='sfx/check.mp3',
    click='sfx/click.mp3',
    sweep='sfx/sweep.mp3',
    win='sfx/win.mp3',
    lose='sfx/lose.mp3',
    hint='sfx/hint.mp3',
}

IMG.init{
    cup={
        'image/cup1.png',
        'image/cup2.png',
        'image/cup3.png',
        'image/cup4.png',
        'image/cup5.png',
    }
}

local attempts={}
local answers={}
local started
local currentNum=""
local remain
local inGame
local mode
local showTag

local STAT={win={},winStreak={},mastered={}}
for i=1,5 do
    STAT.win[i]=0
    STAT.winStreak[i]=0
    STAT.mastered[i]=false
end

local SETTINGS={
    bgm=true,
    sfx=true,
    vib=MOBILE and true or false
}

local suc,res=pcall(FILE.load,'data.lua','-luaon')
if suc then
    TABLE.update(SETTINGS,res.settings)
    TABLE.update(STAT,res.stat)
end
SFX.setVol(SETTINGS.sfx and 1 or 0)

local modeColor={
    COLOR.Green,
    COLOR.White,
    COLOR.Red,
    COLOR.Yellow,
    COLOR.Blue,
}

local modeText={
    "Standard mode",
    "Easy mode",
    "Hard mode",
    "Extreme mode",
    "Lunatic mode",
}

local tagBoard={
    X=20,
    Y=650,
    W=680,
    H=600,
    CW=170,
    CH=60,
}

local tagList={}
for y=1,4 do
    tagList[y]={}
    for x=0,9 do
        tagList[y][x]=true
    end
end
local savedTagList={{},{},{},{}}

local function savedata()
    if TASK.lock('savedata',3) then
        pcall(FILE.save,{settings=SETTINGS,stat=STAT},'data.lua','-luaon')
    end
end

local function compare(tar,org)
    local A,B=0,0
    for i=1,4 do
        if tar[i]==org[i] then
            A=A+1
        else
            for j=1,4 do
                if tar[i]==org[j] then B=B+1 break end
            end
        end
    end
    return A,B
end

local function genNumComb()
    local comb=""
    local s={} for _=0,9 do s[_]=_ end
    for _=1,4 do
        comb=comb..TABLE.popRandom(s)
    end
    return comb
end

local function endGame(reason)
    inGame=false
    TEXT:add{
        text=reason=='win' and "You win!" or "You Lose!\nanswer="..TABLE.getRandom(answers),
        x=360,y=750,fontSize=65,duration=5,inPoint=.05
    }
    SFX.play(reason=='win' and 'win' or 'lose')
    -- vibrate
    if reason=='win' then STAT.win[mode]=STAT.win[mode]+1 end
    STAT.winStreak[mode]=(reason=='win' and STAT.winStreak[mode]+1 or 0)
    savedata()
end

local function check(comb)
    local A,B
    if #attempts==0 then
        if mode==1 then
            TABLE.insert(answers,genNumComb())
            A,B=compare(answers[1],comb)
            TABLE.insert(attempts,{attempt=comb,A=A,B=B})
            if answers[1]==comb then
                endGame('win')
            end
            return
        end
        local c=0
        for i=1,4 do
            c=c+1
            i=comb[i]+0
            for j=0,9 do if not STRING.find(comb,j) then
                for k=0,9 do if not STRING.find(comb,k) and k~=j then
                    for l=0,9 do if not STRING.find(comb,l) and l~=k and l~=j then
                        if c~=1 then TABLE.insert(answers,i..j..k..l) end
                        if c~=2 then TABLE.insert(answers,j..i..k..l) end
                        if c~=3 then TABLE.insert(answers,j..k..i..l) end
                        if c~=4 then TABLE.insert(answers,j..k..l..i) end
                    end end
                end end
            end end
        end
        TABLE.insert(attempts,{attempt=comb,A=0,B=1})
    elseif #answers>1 then
        local mat={}for i=0,20 do mat[i]=0 end
        for i=1,#answers do
            A,B=compare(answers[i],comb)
            mat[5*A+B]=mat[5*A+B]+1
        end
        local best,a,b
        if mode==2 then
            local m=0
            for i=0,19 do m=m+mat[i] end
            m=MATH.random(m)
            for i=0,19 do
                m=m-mat[i]
                if m<=0 then best=i break end
            end
        else
            local m=0
            best={}
            for i=0,19 do
                if mat[i]>m then
                    m=mat[i]
                    best={i}
                elseif mat[i]==m then
                    TABLE.insert(best,i)
                end
            end
            best=best[MATH.random(#best)]
        end
        a,b=MATH.floor(best*.2),best%5
        for i=#answers,1,-1 do
            A,B=compare(answers[i],comb)
            if B~=b or A~=a then TABLE.remove(answers,i) end
        end
        if mode==5 then
            -- info[#info-1]=gsub(info[#info-1],".A.B","?A?B")
            -- hide attempts other than recent 2
        end
        if mode==3 and #answers==1 then
            TABLE.insert(attempts,{attempt=comb,A=a,B=b,unique=true})
            SFX("hint")
        else
            TABLE.insert(attempts,{attempt=comb,A=a,B=b})
        end
    else
        A,B=compare(answers[1],comb)
        TABLE.insert(attempts,{attempt=comb,A=A,B=B})
        if answers[1]==comb then
            endGame('win')
        end
    end
end

local function rndCheck(n)
    local rndList={}
    repeat
        local comb=genNumComb()
        if not TABLE.find(rndList,comb) then
            TABLE.insert(rndList,comb)
        end
    until #rndList==n
    for _,v in next,rndList do
        check(v)
    end
end

local function reset()
    local attemptCount={12,11,8,7,6}
    TABLE.clear(attempts)
    TABLE.clear(answers)
    started=false
    currentNum=""
    remain=attemptCount[mode]
    inGame=true
    showTag=false
    for y=1,4 do
        tagList[y]={}
        for x=0,9 do
            tagList[y][x]=true
        end
    end
    savedTagList={{},{},{},{}}
    if mode==3 then
        rndCheck(1)
    elseif mode>=4 then
        rndCheck(2)
    end
    TEXT:clear()
end

local function numEnter(i)
    SFX.play('key'..i)
    if #currentNum<4 then
        currentNum=currentNum..i
    end
end

local function numDel()
    if #currentNum>0 then
        SFX.play("del_"..(5-#currentNum))
        currentNum=STRING.sub(currentNum,1,-2)
    end
end

local function quitCheck()
    if not started or not TASK.lock('quitCheck',1) then SCN.back() return end
    MSG('info',"Press again to exit",1)
end

local function isDuplicate(comb)
    for i=1,3 do for j=i+1,4 do
        if comb[i]==comb[j] then return true end
    end end
    return false
end

local function guess()
    if #currentNum<4 then
        TEXT:add{text="4 numbers!",x=360,y=650,fontSize=35,duration=3,inPoint=0.1}
        SFX.play('error')
    elseif isDuplicate(currentNum) then    
        TEXT:add{text="no duplicate!",x=360,y=650,fontSize=35,duration=3,inPoint=0.1}
        SFX.play('error')
    else
        for _ in next,attempts do
            if attempts[_].attempt==currentNum then
                TEXT:add{text="already guessed!",x=360,y=650,fontSize=35,duration=3,inPoint=0.1}
                SFX.play('error')
                return
            end
        end
        if not started then started=true end
        check(currentNum)
        currentNum=""
        SFX.play('check')
        remain=remain-1
        if remain==0 and inGame then
            endGame('lose')
        end
    end
end

local function getBoardPos(x,y)
    local cx=math.floor((x-tagBoard.X)/tagBoard.CW+1)
    local cy=math.floor((y-(tagBoard.Y))/tagBoard.CH)
    return MATH.clamp(cx,1,4),MATH.clamp(cy,0,9)
end



local scene_menu={}

function scene_menu.load()
    if SETTINGS.bgm then BGM.play('title') end
end

function scene_menu.draw()
    FONT.set(25)
    for i=1,5 do
        GC.setColor(modeColor[i])
        if STAT.win[i]>0 then
            GC.mStr(STAT.winStreak[i],580,265+100*i)
            GC.mStr(STAT.win[i],580,305+100*i)
        end
    end
end

function scene_menu.keyDown(k,rep)
    if rep then return end
    if k=="escape" then
        ZENITHA._quit('fade')
    end
end

scene_menu.widgetList={
    {type='button',text="Quit",x=360,y=980,w=300,h=100,fontSize=45,color='White', onClick=function() ZENITHA._quit('fade') end},
    --title and about
    {type='text',text="Try Guess it!",               x=360,y=150, fontSize=90},
    {type='text',text="rewrite ver     by huaji2369",x=365,y=220, fontSize=30},
    {type='text',text="Original Version By MrZ",     x=360,y=1140,fontSize=35},
    {type='text',text="V1.4   Powered by Zenitha",   x=360,y=1190,fontSize=50},
    --play button
    {type='button',text=modeText[1],x=360,y=400,w=400,h=80,fontSize=50,color=modeColor[1],onClick=function() mode=1 reset() SCN.go('play') end},
    {type='button',text=modeText[2],x=360,y=500,w=400,h=80,fontSize=50,color=modeColor[2],onClick=function() mode=2 reset() SCN.go('play') end},
    {type='button',text=modeText[3],x=360,y=600,w=400,h=80,fontSize=50,color=modeColor[3],onClick=function() mode=3 reset() SCN.go('play') end},
    {type='button',text=modeText[4],x=360,y=700,w=400,h=80,fontSize=50,color=modeColor[4],onClick=function() mode=4 reset() SCN.go('play') end},
    {type='button',text=modeText[5],x=360,y=800,w=400,h=80,fontSize=50,color=modeColor[5],onClick=function() mode=5 reset() SCN.go('play') end},
    --trophy
    {type='button',x=110,y=400,w=80,h=80,onClick=function() SCN.go('trophy','none',1) end,visibleFunc=function() return STAT.mastered[1] end,color=modeColor[1]},
    {type='button',x=110,y=500,w=80,h=80,onClick=function() SCN.go('trophy','none',2) end,visibleFunc=function() return STAT.mastered[2] end,color=modeColor[2]},
    {type='button',x=110,y=600,w=80,h=80,onClick=function() SCN.go('trophy','none',3) end,visibleFunc=function() return STAT.mastered[3] end,color=modeColor[3]},
    {type='button',x=110,y=700,w=80,h=80,onClick=function() SCN.go('trophy','none',4) end,visibleFunc=function() return STAT.mastered[4] end,color=modeColor[4]},
    {type='button',x=110,y=800,w=80,h=80,onClick=function() SCN.go('trophy','none',5) end,visibleFunc=function() return STAT.mastered[5] end,color=modeColor[5]},
    {type='image', x=110,y=400,w=80,h=80,image=IMG.cup[1],                                visibleFunc=function() return STAT.mastered[1] end,imageColor=modeColor[1]},
    {type='image', x=110,y=500,w=80,h=80,image=IMG.cup[2],                                visibleFunc=function() return STAT.mastered[2] end,imageColor=modeColor[2]},
    {type='image', x=110,y=600,w=80,h=80,image=IMG.cup[3],                                visibleFunc=function() return STAT.mastered[3] end,imageColor=modeColor[3]},
    {type='image', x=110,y=700,w=80,h=80,image=IMG.cup[4],                                visibleFunc=function() return STAT.mastered[4] end,imageColor=modeColor[4]},
    {type='image', x=110,y=800,w=80,h=80,image=IMG.cup[5],                                visibleFunc=function() return STAT.mastered[5] end,imageColor=modeColor[5]},
    --bgm/sfx/vib
    {type='checkBox',text="BGM",x=480,y=80,labelPos='top',disp=function() return SETTINGS.bgm end,
        code=function()
            SETTINGS.bgm=not SETTINGS.bgm
            BGM.setVol(SETTINGS.bgm and 1 or 0)
            savedata()
            if SETTINGS.bgm then
                BGM.play('title')
            else
                BGM.stop()
            end
        end},
    {type='checkBox',text="SFX",x=570,y=80,labelPos='top',disp=function() return SETTINGS.sfx end,
        code=function()
            SETTINGS.sfx=not SETTINGS.sfx
            SFX.setVol(SETTINGS.sfx and 1 or 0)
            savedata()
            SFX.play('click')
        end},
    {type='checkBox',text="VIB",x=660,y=80,labelPos='top',disp=function() return SETTINGS.vib end,visibleFunc=function() return MOBILE end,
        code=function()
            SETTINGS.vib=not SETTINGS.vib
            savedata()
            if SETTINGS.vib then VIB(10) end
        end},
}

SCN.add('menu',scene_menu)



local scene_play={}

function scene_play.load()
    if SETTINGS.bgm then BGM.play(mode>=4 and 'main2' or 'main') end
    SFX.play('check')
    scene_play.widgetList.attemptList:setList(attempts)
end

function scene_play.draw()
    GC.setColor(COLOR.White)
    GC.setLineWidth(5)
    FONT.set(60)
    GC.mStr(modeText[mode] or "",360,15)
    FONT.set(60,'mono')
    GC.rectangle("line",260,560,200,70)
    GC.print(currentNum,285,560)
    GC.setColor(
        remain<=2 and COLOR.Red or
        remain<=4 and COLOR.Yellow or
        COLOR.White
    )
    FONT.set(35)
    GC.print(remain,465,600)
    if showTag then
        GC.setColor(COLOR.White)
        local B=tagBoard
        GC.translate(B.X,B.Y)
        for i=0,4 do
            GC.line(B.CW*i,0,B.CW*i,B.H)
        end
        FONT.set(52)
        GC.line(0,B.H,B.W,B.H)
        for i=0,9 do
            GC.line(0,B.CH*i,B.W,B.CH*i)
            for j=1,4 do
                if tagList[j][i] then
                    GC.mStr(i,(2*j-1)*B.CW/2,(B.CH*i)-5)
                end
            end
        end
    end
end

function scene_play.keyDown(k,rep)
    if rep then return end
    if #k==1 and tonumber(k) or k:match('kp%d') then
        numEnter(tonumber(k:match('%d')))
    elseif k=='return' or k=='kpenter' then
        guess()
    elseif k=='backspace' then
        numDel()
    elseif k=='escape' then
        quitCheck()
    end
    return true
end

function scene_play.mouseDown(x,y,k)
    if showTag and k==1
    and MATH.between(x,tagBoard.X,tagBoard.X+tagBoard.W)
    and MATH.between(y,tagBoard.Y,tagBoard.Y+tagBoard.H)
    then
        local x,y=getBoardPos(x,y)
        tagList[x][y]=not tagList[x][y]
        SFX.play('sweep')
    end
end

function scene_play.touchDown(x,y)
    scene_play.mouseDown(x,y,1)
end

function scene_play.leave()
    TEXT:clear()
end

scene_play.widgetList={
    {type='button',text="X",x=675,y=45,w=40,h=40,visibleTick=function()
        return not (STAT.winStreak[mode]==5 and not STAT.mastered[mode] and not inGame)
    end,onClick=function() quitCheck() end},
    --buttons
    {type='button',text="1",x=200,y=800, w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',fontSize=90,onClick=function() numEnter(1) end},
    {type='button',text="2",x=360,y=800, w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',fontSize=90,onClick=function() numEnter(2) end},
    {type='button',text="3",x=520,y=800, w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',fontSize=90,onClick=function() numEnter(3) end},
    {type='button',text="4",x=200,y=930, w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',fontSize=90,onClick=function() numEnter(4) end},
    {type='button',text="5",x=360,y=930, w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',fontSize=90,onClick=function() numEnter(5) end},
    {type='button',text="6",x=520,y=930, w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',fontSize=90,onClick=function() numEnter(6) end},
    {type='button',text="7",x=200,y=1060,w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',fontSize=90,onClick=function() numEnter(7) end},
    {type='button',text="8",x=360,y=1060,w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',fontSize=90,onClick=function() numEnter(8) end},
    {type='button',text="9",x=520,y=1060,w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',fontSize=90,onClick=function() numEnter(9) end},
    {type='button',text="0",x=360,y=1190,w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',fontSize=90,onClick=function() numEnter(0) end},
    {type='button',text="<",x=520,y=1190,w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',fontSize=70,color='Red',onClick=function() numDel() end},
    {type='button',text="check",x=200,y=1190,w=135,h=100,visibleTick=function() return inGame and not showTag end,sound_release='click',color='Green',onClick=function() guess() end},
    {type='button',text="tag",x=660,y=595,w=70,h=70,visibleTick=function() return inGame end,sound_release='click',onClick=function() showTag=not showTag end,color='Yellow',},
    {type='button',text="save",x=60,y=595,w=70,h=70,visibleTick=function() return inGame and showTag end,sound_release='click',onClick=function()
        TABLE.update(savedTagList,tagList)
    end,fontSize=30,color='Red'},
    {type='button',text="load",x=150,y=595,w=70,h=70,visibleTick=function() return inGame and showTag and next(savedTagList[1]) end,sound_release='click',onClick=function()
        TABLE.update(tagList,savedTagList)
    end,fontSize=28,color='Green'},
    {type='button',text="reset",x=570,y=595,w=70,h=70,visibleTick=function() return inGame and showTag end,sound_release='error',onClick=function()
        for y=1,4 do
            tagList[y]={}
            for x=0,9 do
                tagList[y][x]=true
            end
        end
    end,fontSize=25,color='Blue'},
    --[=[
    {"R",570,595,70,70,function()
        SFX("error")
        for i=1,4 do
            for j=1,10 do
                tagList[i][j]=true
            end
        end
    end,font=60,rgb=color.blue},
    ]=]

    -- attempts list
    {type='listBox',name='attemptList',x=20,y=100,w=680,h=440,drawFunc=function(i,n)
        FONT.set(30,'mono')
        GC.setColor(COLOR.White)
        GC.print(i.attempt,20,-2)
        if mode==5 then
            GC.setAlpha(MATH.clamp(.5*(n-#attempts)+1,0,1))
        end
        GC.print(STRING.format("%01dA%01dB",i.A,i.B),120,0)
        if i.unique then
            GC.setColor(COLOR.Yellow)
            GC.rectangle('fill',0,0,10,30)
        end
    end},
    --restart/trophy button
    {type='button',text="Restart",x=360,y=950,w=360,h=120,color='Red',visibleTick=function()
        return not (STAT.winStreak[mode]==5 and not STAT.mastered[mode]) and not inGame
    end,onClick=function() reset() SFX.play('check') end},

    {type='button',text="Get Trophy",x=360,y=950,w=420,h=120,color='Yellow',visibleTick=function()
        return STAT.winStreak[mode]==5 and not STAT.mastered[mode] and not inGame
    end,onClick=function()
        STAT.mastered[mode]=true
        SCN.go('trophy')
        savedata()
    end},
}

SCN.add('play',scene_play)  



local scene_trophy={}

function scene_trophy.load()
    if SETTINGS.bgm then BGM.play('trophy') end
    SFX.play('win')
end

function scene_trophy.draw()
    FONT.set(60)
    GC.setColor(COLOR.White)
    GC.mStr(
        mode==1 and "Good.\nNot noob now."          or
        mode==2 and "Great.\nLet's go deeper."      or
        mode==3 and "Nice?\nMay very hard."         or
        mode==4 and "Awesome!\nYou are master now." or
        mode==5 and "Incredible!!!\nGrand Master."
    ,360,250)
    GC.setColor(modeColor[mode])
    GC.draw(IMG.cup[mode],360,600,0,20,20,10,10)
end

function scene_trophy.keyDown(k,rep)
    if rep then return end
    if k=="escape" then
        SCN.back()
    end
end

scene_trophy.widgetList={
    {type='button',text="Back",x=360,y=1000,w=400,h=100,onClick=function() SCN.back('none',mode) end},
}

SCN.add('trophy',scene_trophy)



ZENITHA.setFirstScene('menu')
