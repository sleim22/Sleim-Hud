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

if amS > prevAmS or amSRaw > prevAmSRaw or amS == 1 then
	hitTable[hitcount]={"AM",hitpoints,rawHitpoints}
	amDmg = hitpoints
	system.print("Antimatter")
elseif elS > prevElS or elSRaw > prevElSRaw or elS == 1 then
	hitTable[hitcount]={"EL",hitpoints,rawHitpoints}
	elDmg = hitpoints
	system.print("Electro")
elseif kiS > prevKiS or kiSRaw > prevKiSRaw or kiS == 1 then
	hitTable[hitcount]={"KI",hitpoints,rawHitpoints}
	kiDmg = hitpoints
	system.print("Kinetic")
elseif thS > prevThS or thSRaw > prevElSRaw or thS == 1 then
	hitTable[hitcount]={"TH",hitpoints,rawHitpoints}
	thmDmg = hitpoints
	system.print("Thermic")
else
	if noDoubles() then
		if amDmg == hitpoints then
			hitTable[hitcount]={"AM",hitpoints,rawHitpoints}
			amDmg = hitpoints
			system.print("Antimatter")
		elseif elDmg == hitpoints then
			hitTable[hitcount]={"EL",hitpoints,rawHitpoints}
			elDmg = hitpoints
			system.print("Electro")
		elseif kiDmg == hitpoints then
			hitTable[hitcount]={"KI",hitpoints,rawHitpoints}
			kiDmg = hitpoints
			system.print("Kinetic")
		elseif thmDmg == hitpoints then
			hitTable[hitcount]={"TH",hitpoints,rawHitpoints}
			thmDmg = hitpoints
			system.print("Thermic")
		end
	else
		hitTable[hitcount]={"Error",hitpoints,rawHitpoints}
		system.print("Error")
	end
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

function noDoubles()
	local values = {amDmg,elDmg,kiDmg,thDmg}
	for i=1,4 do
		for k=1,4 do
			if i~=k then
				if values[i]==values[k] and values[k] ~= 0 and values[i] ~= 0 then
					return false
				end
			end
		end
	end
	return true
end
