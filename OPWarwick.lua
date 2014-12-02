myHero = GetMyHero()
if myHero.charName ~= "Warwick" then return end

local autoUpdate   = true
local silentUpdate = false

local version = 0.01

local scriptName = "OPWarwick"

if autoUpdate then
    SourceUpdater(scriptName, version, "raw.github.com", "/wkair/OPWarwick/master/" .. scriptName .. ".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/wkair/OPWarwick/master/version.txt"):SetSilent(silentUpdate):CheckUpdate()
end

require 'SourceLib'
require 'SxOrbWalk'

local loadingdone = false
local Config = nil
local Target
local _SMITE = nil

local AfterRFalge = false
local AfterRTarget = nil
 
local qRange = 400
local wRange = 1250
local eRange = nil
local rRange = 700
local QAble, WAble, EAble, RAble, IAble = false, false, false, false
local TAble, HAble, BAble, RKAble       = false, false, false, false
local SAble, SmiteFlag = false, 0
local qDmg, rDmg, iDmg, tDmg, hDmg, rkDmg, bDmg, ksDmg

local items =
  {
    ["WIT"]     = {id=3091, range = nil, reqTarget = false, slot = nil, active = false},--1
    ["TRI"]     = {id=3078, range = nil, reqTarget = false, slot = nil, active = false},
    ["SHEEN"]   = {id=3057, range = nil, reqTarget = false, slot = nil, active = false},--3
    ["SABRE"]   = {id=3715, range = nil, reqTarget = false, slot = nil, active = false },
    ["BRK"]     = {id=3153, range = 450, reqTarget = true, slot = nil, active = true},--5
    ["BWC"]     = {id=3144, range = 450, reqTarget = true, slot = nil, active = true},
    ["Hyd"]     = {id=3074, range = 100, reqTarget = false, slot = nil, active = true},--7
    ["TMT"]     = {id=3077, range = 100, reqTarget = false, slot = nil, active = true},
    ["STT"]     = {id=3087, range = nil, reqTarget = false, slot = nil, active = false},--9
    ["SABREUP"] = {id=3718, range = nil, reqTarget = false, slot = nil, active = false},--10
  }
local pdmg = {3,3.4,4,4.5,5,5.5,6,6.6,7,8,9,10,11,12,13,14,15,16}

function OnLoad()
  --TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1575, DAMAGE_PHYSICAL)
  EnemyMinions  = minionManager(MINION_ENEMY, 500, myHero, MINION_SORT_HEALTH_ASC)
  JungleMinions = minionManager(MINION_JUNGLE, 500, myHero, MINION_SORT_MAXHEALTH_DEC)
  
  if _IGNITE == nil then 
      if myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") then
          _IGNITE = SUMMONER_1
      elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") then
          _IGNITE = SUMMONER_2
      end
  end

  if _SMITE == nil then 
      if myHero:GetSpellData(SUMMONER_1).name:find("smite") then
          _SMITE = SUMMONER_1
      elseif myHero:GetSpellData(SUMMONER_2).name:find("smite") then
          _SMITE = SUMMONER_2
      end
  end
  Menu()
  loadingdone = true
  PrintChat("OPWarwick is loaded.")
end

function Menu()
  Config = scriptConfig("Warwick", "Warwick")

  Config:addSubMenu("OrbWalk", "OW")
      SxOrb:LoadToMenu(Config.OW)

  Config:addSubMenu("When use R", "roption")
    Config.roption:addParam("enable"    , "Auto Combo Enable", SCRIPT_PARAM_ONOFF, true)

  Config:addSubMenu("Combo", "combo")
    Config.combo:addParam("key"   , "set key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    Config.combo:addParam("sep"   , "-- Combo Options --", SCRIPT_PARAM_INFO, "")
    Config.combo:addParam("useQ"  , "Use - Hungering Strike", SCRIPT_PARAM_ONOFF, true)
    Config.combo:addParam("useW"  , "Use - Hunters Call", SCRIPT_PARAM_ONOFF, true)

  Config:addSubMenu("Harras", "harras")
    Config.harras:addParam("key"   , "set key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
    Config.harras:addParam("sep", "-- Mixed Mode Options --", SCRIPT_PARAM_INFO, "")
    Config.harras:addParam("useQ2", "Use - Hungering Strike", SCRIPT_PARAM_ONOFF, true)
    Config.harras:addParam("useW2", "Use - Hunters Call", SCRIPT_PARAM_ONOFF, false)

  Config:addSubMenu("Farm/Jungle", "farm")
    Config.farm:addParam("key1"   , "set LastHit  key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
    Config.farm:addParam("key2"   , "set LanClear key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
    Config.farm:addParam("key3"   , "set Jungle   key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
    Config.farm:addParam("sep1", "-- Last Hit Options --", SCRIPT_PARAM_INFO, "")
    Config.farm:addParam("qFarm", "Farm - Hungering Strike", SCRIPT_PARAM_ONOFF, true)
    Config.farm:addParam("sep2", "-- Lane Clear Options --", SCRIPT_PARAM_INFO, "")
    Config.farm:addParam("qClear", "Farm - Hungering Strike", SCRIPT_PARAM_ONOFF, false)
    Config.farm:addParam("sep3", "-- Jungle Options --", SCRIPT_PARAM_INFO, "")
    Config.farm:addParam("useQ3", "jungle - Hungering Strike", SCRIPT_PARAM_ONOFF, true)
    Config.farm:addParam("useW3", "jungle - Hunters Call", SCRIPT_PARAM_ONOFF, false)

  Config:addSubMenu("Display", "draw")
    Config.draw:addParam("sep", "-- Drawing Options --", SCRIPT_PARAM_INFO, "")
    Config.draw:addParam("drawQ", "Draw - Hungering Strike", SCRIPT_PARAM_ONOFF, true)
    Config.draw:addParam("drawW", "Draw - Hunters Call", SCRIPT_PARAM_ONOFF, true)
    Config.draw:addParam("drawE", "Draw - Blood Scent", SCRIPT_PARAM_ONOFF, true)
    Config.draw:addParam("drawR", "Draw - Infinite Duress", SCRIPT_PARAM_ONOFF, true)
    Config.draw:addParam("Dmgtxt","Draw - Full dmg Text", SCRIPT_PARAM_ONOFF, true)

  Config:addSubMenu("Jungle Item Stack", "stacks")
    Config.stacks:addParam("info1"    , "Enchantment: Devourer Stack for Dmg calculation", SCRIPT_PARAM_INFO, "")
    Config.stacks:addParam("info2"    , "If VIP, It will change automatically", SCRIPT_PARAM_INFO, "")
    Config.stacks:addParam("info3"    , "freeuser must change manually", SCRIPT_PARAM_INFO, "")
    Config.stacks:addParam("stack"    , "Jungle Item Stack", SCRIPT_PARAM_SLICE, 0, 0, 150, 0)
    Config.stacks.stack = 0

  Config:addSubMenu("Info", "info")
    Config.info:addParam("info1"    , "FullCombo: smite, ignite, items, SpellR", SCRIPT_PARAM_INFO, "")
    Config.info:addParam("info2"    , "Items: BOTRK, BW, Hydra, Tiamat", SCRIPT_PARAM_INFO, "")
end

function OnTick()
  if not loadingdone then return end
  Checks()
  CheckELevel()

  if Config.roption.enable then OnUlt() end

  if Config.combo.key then 
    OnCombo() 
  end

  if Config.harras.key then 
    OnHarras()
  end

  if Config.farm.key1 or Config.farm.key2 then
    OnFarm()
  end

  if Config.farm.key3 then
    OnJungle()
  end
end

function Checks()
  for _,item in pairs(items) do
      item.slot = GetInventorySlotItem(item.id)
  end

  QAble = (myHero:CanUseSpell(_Q) == READY)
  WAble = (myHero:CanUseSpell(_W) == READY)
  EAble = (myHero:CanUseSpell(_E) == READY)
  RAble = (myHero:CanUseSpell(_R) == READY)
  IAble = (_IGNITE and myHero:CanUseSpell(_IGNITE) == READY)
  SAble = (_SMITE and (items["SABRE"].slot or items["SABREUP"].slot) and myHero:CanUseSpell(_SMITE) == READY)
  TAble = (items["TMT"].slot and myHero:CanUseSpell(items["TMT"].slot) == READY)
  HAble = (items["Hyd"].slot and myHero:CanUseSpell(items["Hyd"].slot) == READY)
  BAble = (items["BWC"].slot and myHero:CanUseSpell(items["BWC"].slot) == READY)
  RKAble= (items["BRK"].slot and myHero:CanUseSpell(items["BRK"].slot) == READY)
  Target = SxOrb:GetTarget() 

  if not SAble and SmiteFlag < 2 then SmiteFlag = 0 end
end

function CheckELevel()
  if myHero:GetSpellData(_E).level == 1 then eRange = 1500
  elseif myHero:GetSpellData(_E).level == 2 then eRange = 2300
  elseif myHero:GetSpellData(_E).level == 3 then eRange = 3100
  elseif myHero:GetSpellData(_E).level == 4 then eRange = 3900
  elseif myHero:GetSpellData(_E).level == 5 then eRange = 4700
  end
end

function OnCombo()
  if Target then
    if QAble and Config.combo.useQ and GetDistance(Target) < qRange then
      CastSpell(_Q, Target) 
    end
    if WAble and Config.combo.useW and GetDistance(Target) <= 300 and SxOrb:CanAttack() then
      CastSpell(_W) 
    end
  end
end

function OnHarras()
  if Target then
    if QAble and Config.harras.useQ and GetDistance(Target) < qRange then
      CastSpell(_Q, Target) 
    end
    if WAble and Config.harras.useW and GetDistance(Target) <= 250 and SxOrb:CanAttack() then
      CastSpell(_W) 
    end
  end
end

function OnFarm()
  if Config.farm.key1 then
    local Minion = nil
    EnemyMinions:update()
    Minion = EnemyMinions.objects[1]
    --LastHitting
    if QAble and Config.farm.qFarm then
      if Minion and not Minion.type == "obj_Turret" and not Minion.dead and GetDistance(Minion) <= qRange and Minion.health < getDmg("Q", Minion, myHero) then 
          CastSpell(_Q, Minion)
      else 
        for _, minion in pairs(EnemyMinions.objects) do
          if minion and not minion.dead and GetDistance(minion) <= qRange and minion.health < getDmg("Q", minion, myHero) then 
            CastSpell(_Q, minion)
          end
        end
      end
    end
  end

  if Config.farm.key2 then
    local Minion = nil
    EnemyMinions:update()
    Minion = EnemyMinions.objects[1]
    --LaneClear
    if QAble and Config.farm.qClear then
      if Minion and not Minion.type == "obj_Turret" and not Minion.dead and GetDistance(Minion) <= qRange and Minion.health < getDmg("Q", Minion, myHero) then 
        CastSpell(_Q, Minion)
      else 
        for _, minion in pairs(EnemyMinions.objects) do
          if minion and not minion.dead and GetDistance(minion) <= qRange and minion.health < getDmg("Q", minion, myHero) then 
            CastSpell(_Q, minion)
          end
        end
      end
    end
  end
end

function OnJungle()
  local Minion = nil
  JungleMinions:update()
  Minion = JungleMinions.objects[1]
  if QAble and Config.farm.useQ3 then
      if Minion and not Minion.dead and GetDistance(Minion) <= qRange then 
        CastSpell(_Q, Minion)
      end
  end
  if WAble and Config.farm.useW3 and OW.Menu.Mode2 then
    CastSpell(_Q, Minion)
  end
end

function OnUlt()
  if AfterR == false or not ValidTarget(AfterRTarget,rRange) then return end
  local enemy = AfterRTarget
  local flag = 0
  if SAble  and GetDistance(enemy) < rRange then CastSpell(_SMITE, enemy) else flag = flag + 1 end
  if QAble  and GetDistance(enemy) < qRange then CastSpell(_Q, enemy) else flag = flag + 1 end
  if TAble  and GetDistance(enemy) < items["TMT"].range then CastSpell(items["TMT"].slot) else flag = flag + 1 end
  if HAble  and GetDistance(enemy) < items["Hyd"].range then CastSpell(items[7].slot) else flag = flag + 1 end
  if RKAble and GetDistance(enemy) < items["BRK"].range then CastSpell(items["BRK"].slot, enemy) else flag = flag + 1 end
  if BAble  and GetDistance(enemy) < items["BWC"].range then CastSpell(items["BWC"].slot, enemy) else flag = flag + 1 end
  if IAble  and GetDistance(enemy) < 600 then CastSpell(_IGNITE, enemy) else flag = flag + 1 end

  if flag == 7 then AfterR = false AfterRTarget = nil end
end

function OnRecvPacket(p)
  if p.header == 0xFE then
    local info ={netid, subheader, type, state, stack}
    p.pos =1
    info.netid = p:DecodeF()
    info.subheader = p:Decode1()
    if info.netid == myHero.networkID and info.subheader == 0x09 then
      info.type = p:Decode1()
      info.state = p:Decode1()
      info.stack = p:Decode1()
      --PrintChat(string.format("%02X, %02X, %02X",info.type,info.state,info.stack))
      if info.stack and info.stack > 0x05 then 
        Config.stacks.stack = info.stack
      end
    end
  end
end

function OnProcessSpell(unit, spell)
  if Config.roption.enable and unit.isMe and spell.name == "InfiniteDuress" then
    AfterR = true
    AfterRTarget = spell.target
    SxOrb:ForceTarget(AfterRTarget)
  end
end

function GetRDamage(target)
    local witDmg = ( items["WIT"].slot ) and 75  or 0 -- by wit's end
    local Rdamage = (getDmg("R",target,myHero)+ myHero:CalcMagicDamage(target,pdmg[myHero.level]) )* 5 + witDmg * 2
    if items["WIT"].slot then
        Rdamage = Rdamage + myHero:CalcMagicDamage(target, 210) + witDmg
    end
    if items["BRK"].slot then
        Rdamage = Rdamage + myHero:CalcDamage(target, (target.hpPool - (target.hpPool*0.77)))   
    end
    if items["TRI"].slot then
        Rdamage = Rdamage + myHero:CalcDamage(target, myHero.damage*2)    
    end
    if items["SHEEN"].slot then
        Rdamage = Rdamage + myHero:CalcDamage(target, myHero.damage)    
    end
    if items["STT"].slot then
        Rdamage = Rdamage + myHero:CalcMagicDamage(target, 100) 
    end   
    if items["SABRE"].slot then
      if SAble then
        Rdamage = Rdamage + (15+(3 * myHero.level))*5 
      end
    end
    if items["SABREUP"].slot then
      if SAble then
          Rdamage = Rdamage + (15+(3 * myHero.level))*5 
      end
      Rdamage = Rdamage + myHero:CalcMagicDamage(target, (40+ Config.stacks.stack)*5)  + witDmg 
    end
    return Rdamage
end

function OnDraw()
  if not loadingdone then return end
  if myHero.dead then return end

  if Config.draw.Dmgtxt then
    Fulldmg() 
  end

  if QAble and Config.draw.drawQ then
    DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x00FF00)
  end
  if WAble and Config.draw.drawW then
    DrawCircle(myHero.x, myHero.y, myHero.z, wRange, 0x9933FF)
  end
  if EAble and Config.draw.drawE then
    DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0xFF0000)
  end
  if RAble and Config.draw.drawR then
    DrawCircle(myHero.x, myHero.y, myHero.z, rRange, 0x9933FF)
  end
end

function Fulldmg()
  for i, enemy in ipairs(GetEnemyHeroes()) do
    if ValidTarget(enemy) then
      if QAble  then qDmg  = getDmg("Q", enemy, myHero)           else qDmg  = 0 end
      if RAble  then rDmg  = GetRDamage(enemy)                    else rDmg  = 0 end
      if IAble  then iDmg  = 50+20*myHero.level                   else iDmg  = 0 end
      if TAble  then tDmg  = getDmg("AD", enemy, myHero)          else tDmg  = 0 end
      if HAble  then hDmg  = getDmg("AD", enemy, myHero)          else hDmg  = 0 end
      if RKAble then rkDmg = getDmg("RUINEDKING", enemy, myHero,2)else rkDmg = 0 end
      if BAble  then bDmg  = getDmg("BWC", enemy, myHero,2)       else bDmg  = 0 end
      ksDmg = rDmg + iDmg + tDmg + hDmg + rkDmg + bDmg + qDmg
      if ksDmg > enemy.health then 
        DrawText3D("Dmg: "..tostring( string.format("%d",ksDmg) ), enemy.x, 0, enemy.z+200, 25,  ARGB(255,255,0,0), true)
      else
        DrawText3D(tostring(math.floor(enemy.health-ksDmg)).." HP Left", enemy.x, 0, enemy.z+300, 20,  ARGB(255,0,255,0), true)
      end
    end
  end
end
