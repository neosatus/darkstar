-----------------------------------
-- Area: Aydeewa Subterrane
--  ZNM: Pandemonium_Warden
-----------------------------------

require("scripts/globals/titles");
require("scripts/globals/status");
require("scripts/globals/magic");


-----------------------------------
-- Constant Initializations
-----------------------------------
-- General Variables POS: @pos 194 33 -104
local PW = 17056167;

-- Pet Array
local petIDs = {17056169, 17056170, 17056171, 17056172, 17056173, 17056174, 17056175, 17056176};

-- Phase Arrays 
-- To explain these by example, the first index of each array points to the HPP that causes phase 1 to begin as
-- well as the HP and modelIDs for the phase. Basically, when the previous phase ends and what to do when it does.
--
--                   Dverg,  Char1, Dverg,  Char2, Dverg,  Char3, Dverg,  Char4,  Dverg,   Mamo,  Dverg,  Lamia,  Dverg,  Troll,  Dverg,   Cerb,  Dverg,  Hydra,  Dverg,   Khim,  Dverg
--                       1       2      3       4      5       6      7       8       9      10      11      12      13      14      15      16      17      18      19      20
local triggerHPP = {    95,      1,    95,      1,    95,      1,    95,      1,     95,      1,     95,      1,     95,      1,     95,      1,     95,      1,     95,      1};
local mobHP =      { 10000, 147000, 10000, 147000, 10000, 147000, 10000, 147000,  15000, 147000,  15000, 147000,  15000, 147000,  20000, 147000,  20000, 147000,  20000, 147000};
local mobModelID = {  1825,   1839,  1825,   1839,  1825,   1839,  1825,   1839,   1863,   1839,   1865,   1839,   1867,   1839,   1793,   1839,   1796,   1839,   1805,   1839};
local petModelID = {  1820,   1841,  1820,   1841,  1820,   1841,  1820,   1841,   1639,   1841,   1643,   1841,   1680,   1841,    281,   1841,    421,   1841,   1746,   1841};

-- Avatar Arrays         Shiva, Ramuh, Titan, Ifrit, Levia, Garud, Fenri, Carby
local avatarAbilities = {  917,   918,   914,   913,   915,   916,   839,   919};
local avatarSkins =     {   23,    24,    25,    26,    27,    28,    29,    30};

-----------------------------------
-- onMobInitialize Action
-----------------------------------

function onMobInitialize(mob)
end;

-----------------------------------
-- onMobSpawn Action
-----------------------------------

function onMobSpawn(mob)
    -- Make sure model is reset back to start
	mob:setModelId(1839);
    
    -- Prevent death and hide HP until final phase
    mob:setUnkillable(true);
	mob:hideHP(true);

    -- Two hours to forced depop
    mob:setLocalVar("PWardenDespawnTime", os.time(t) + 7200);
    mob:setLocalVar("phase", 1);
    mob:setLocalVar("astralFlow", 1);
end;

-----------------------------------
-- onMobDisengage Action
-----------------------------------

function onMobDisengage(mob)
    -- Make sure model is reset back to start
	mob:setModelId(1839);
    
    -- Prevent death and hide HP until final phase
    mob:setUnkillable(true);
	mob:hideHP(true);

    -- Reset phases (but not despawn timer)
    mob:setLocalVar("phase", 1);
    mob:setLocalVar("astralFlow", 1);
end;

-----------------------------------
-- onMobEngaged
-----------------------------------

function onMobEngaged(mob,target)
    print ("[Phase: 1]");
    -- pop pets
    for i = 1, 8 do
        SpawnMob(petIDs[i]):updateEnmity(target);
        GetMobByID(petIDs[i]):setModelId(1841);
    end
end;

-----------------------------------
-- onMobFight
-----------------------------------

function onMobFight(mob,target)
    -- Init Vars
    local mobHPP = mob:getHPP();
    local depopTime = mob:getLocalVar("PWardenDespawnTime");
    local phase = mob:getLocalVar("phase");
    local astral = mob:getLocalVar("astralFlow");   
    local petStatus = {};
    for i = 1, 8 do
        petStatus[i] = GetMobAction(petIDs[i]);
    end
    
    -- Check for phase change
    if (phase < 21 and mobHPP <= triggerHPP[phase]) then           
        if (phase == 20) then -- Prepare for death
            mob:hideHP(false);
            mob:setUnkillable(false);
        end
        
        -- Change phase
        mob:setModelId(mobModelID[phase]);
        mob:setHP(mobHP[phase]);
        
        -- Handle pets
        for i = 1, 8 do
            if petStatus[i] == 0 then
                SpawnMob(petIDs[i]):updateEnmity(target);
            end
            GetMobByID(petIDs[i]):setModelId(petModelID[phase]);
        end
        
        -- Increment phase
        mob:setLocalVar("phase", phase + 1);
        printf("[Phase: %i -> %i]", phase, phase + 1);
        
    -- Or, check for Astral Flow    
    elseif (phase == 21 and astral < 4 and mobHPP <= (100 - 25 * astral)) then 
        if doAstralFlow then
            for i = 1, 8 do -- For 8x at once, we use our pets
                if petStatus[i] == 0 then
                    SpawnMob(petIDs[i]):updateEnmity(target);
                end
                local avatar = GetMobByID(petIDs[i]);
                --avatar:setModelId(avatarSkins[i]);
                avatar:useMobAbility(avatarAbilities[i]);
                --avatar:setModelId(1841);
            end
            
            -- Increment astral
            mob:setLocalVar("astralFlow", astral + 1);
        end
        
    -- Or, at least make sure pets weren't drug off...
    else 
        for i = 1, 8 do
            if (petStatus[i] == 16 or petStatus[i] == 18) then -- idle or disengaging pet
                GetMobByID(petIDs[i]):updateEnmity(target);
                GetMobByID(i):setPos(GetMobByID(PW):getXPos()+1, GetMobByID(PW):getYPos(), GetMobByID(PW):getZPos()+1);
            end
        end
    end
    
    -- Check for time limit, too
    if (os.time(t) > depopTime) then
        for i=1, 8 do
            DespawnMob(petIDs[i]);
        end
        DespawnMob(PW);
        printf("Timer expired at %i. Despawning Pandemonium Warden.", depopTime);       
    end
end;

-----------------------------------
-- onMobDeath
-----------------------------------

function onMobDeath(mob,killer)
    -- TODO: Death speech.
    killer:addTitle(PANDEMONIUM_QUELLER);
end;