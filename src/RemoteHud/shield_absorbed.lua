prevAmS = 0
prevElS = 0
prevKiS = 0
prevThS = 0
hitcount = 1
hitTable = {}
--
local currentStressRaw = shield.getStressRatioRaw()
local amSRaw = currentStressRaw[1]
local elSRaw = currentStressRaw[2]
local kiSRaw = currentStressRaw[3]
local thSRaw = currentStressRaw[4]

local currentStress = shield.getStressRatioRaw()
local amS = currentStress[1]
local elS = currentStress[2]
local kiS = currentStress[3]
local thS = currentStress[4]

local amDmg = 0
local elDmg = 0
local kiDmg = 0
local thDmg = 0

if amS > prevAmS or amSRaw > prevAmSRaw or amS == 1 or amDmg == rawHitpoints then
	hitTable[hitcount]={"AM",hitpoints,rawHitpoints}
	amDmg = rawHitpoints
	system.print("Antimatter")
elseif elS > prevElS or elSRaw > prevElSRaw or elS == 1 or elDmg == rawHitpoints then
	hitTable[hitcount]={"EL",hitpoints,rawHitpoints}
	elDmg = rawHitpoints
	system.print("Electro")
elseif kiS > prevKiS or kiSRaw > prevKiSRaw or kiS == 1 or kiDmg == rawHitpoints then
	hitTable[hitcount]={"KI",hitpoints,rawHitpoints}
	kiDmg = rawHitpoints
	system.print("Kinetic")
elseif thS > prevThS or thSRaw > prevElSRaw or thS == 1 or thmDmg == rawHitpoints then
	hitTable[hitcount]={"TH",hitpoints,rawHitpoints}
	thmDmg = rawHitpoints
	system.print("Thermic")
else
	hitTable[hitcount]={"Error",hitpoints,rawHitpoints}
	system.print("Error: "..errorType)
end
if hitcount < 30 then
	hitcount = hitcount + 1
else
	hitcount = 1
end
prevAmS = amS
prevElS = elS
prevKiS = kiS
prevThS = thS

prevAmSRaw = amSRaw
prevElSRaw = elSRaw
prevKiSRaw = kiSRaw
prevThSRaw = thSRaw
