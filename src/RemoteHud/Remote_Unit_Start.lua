pitchInput = 0
rollInput = 0
yawInput = 0
drift = false
pitchSpeedFactor = 0.8 --export: This factor will increase/decrease the player input along the pitch axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
yawSpeedFactor = 1 --export: This factor will increase/decrease the player input along the yaw axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
rollSpeedFactor = 1.5 --export: This factor will increase/decrease the player input along the roll axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
screenHeight = system.getScreenHeight()
screenWidth = system.getScreenWidth()
unit.hideWidget()
Nav = Navigator.new(system, core, unit)
Nav.axisCommandManager:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, { 1000, 5000, 10000, 20000, 30000 })
Nav.axisCommandManager:setTargetGroundAltitude(4)


brakeToggle = true --export:

if brakeToggle then
	isBraking = true
	brakeInput = 1
else
	isBraking = false
	brakeInput = 0
end

alarm = false
system.showHelper(0)

function brakeTroogle()
	if isBraking then
		isBraking = false
		brakeInput = 0
	else
		isBraking = true
		brakeInput = brakeInput + 1
		local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
		if (longitudinalCommandType == axisCommandType.byTargetSpeed) then
			local targetSpeed = Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal)
			if (math.abs(targetSpeed) > constants.epsilon) then
				Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, -utils.sign(targetSpeed))
			end
		end
	end
end

function hideWarpDrive()
	if warpdrive ~= nil then
		if warpdrive.getStatus() ~= 11 or warpdrive.getStatus() ~= 7 then
			warpdrive.showWidget()
		else
			warpdrive.hideWidget()
		end
	end
end

atlas = require('atlas')

planetList = {}
for k, nextPlanet in pairs(atlas[0]) do
	if nextPlanet.type[1] == "Planet" then
		planetList[#planetList + 1] = nextPlanet
		--system.print(nextPlanet.name[1])
	end
end

function newGetClosestPipe(wp)
	local pipeDistance
	nearestDistance = nil
	local nearestPipePlanet = nil
	local pipeOriginPlanet = nil

	for i = 1, #planetList, 1 do
		for k = #planetList, i + 1, -1 do
			originPlanet = planetList[i]
			nextPlanet = planetList[k]
			local distance = getPipeDistance(vec3(originPlanet.center), vec3(nextPlanet.center), wp)
			if (nearestDistance == nil or distance < nearestDistance) then
				nearestPipePlanet = nextPlanet
				nearestDistance = distance
				pipeOriginPlanet = originPlanet
			end
			--system.print(planetList[i].name[1].."-"..planetList[k].name[1])
		end
	end
	pipeDistance = getDistanceDisplayString(nearestDistance)
	return pipeOriginPlanet.name[1], nearestPipePlanet.name[1], pipeDistance
end

function round(num, numDecimalPlaces)
	local mult = 10 ^ (numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function getDistanceDisplayString(distance)
	local su = distance > 100000
	if su then
		-- Convert to SU
		return round(distance / 1000 / 200, 2) .. "SU"
	elseif distance < 1000 then
		return round(distance, 2) .. "M"
	else
		-- Convert to KM
		return round(distance / 1000, 2) .. "KM"
	end
end

function getCurrentBody()
	local coordinates = construct.getWorldPosition()
	local minDistance2, body
	local coord = vec3(coordinates)
	for i, v in pairs(atlas[0]) do
		local distance2 = (vec3(v.center) - coord):len2()
		if (not body or distance2 < minDistance2) then -- Never return space.
			body = v
			minDistance2 = distance2
		end
	end
	return body
end

function getPipeDistance(origCenter, destCenter, pos)
	local pipeDistance
	local worldPos = vec3(pos)
	local pipe = (destCenter - origCenter):normalize()
	local r = (worldPos - origCenter):dot(pipe) / pipe:dot(pipe)

	if r <= 0. then
		pipeDistance = (worldPos - origCenter):len()
		return pipeDistance
	elseif r >= (destCenter - origCenter):len() then
		pipeDistance = (worldPos - destCenter):len()
		return pipeDistance
	else
		local L = origCenter + (r * pipe)
		pipeDistance = (L - worldPos):len()
		return pipeDistance
	end
end

function updatePipeInfo()
	currentPos = construct.getWorldPosition()
	local notPvPZone = construct.isInPvPZone() == 0
	local pvpDist = construct.getDistanceToSafeZone()
	if pvpDist < 0 then pvpDist = pvpDist * (-1) end

	local o, p, d = newGetClosestPipe(currentPos)
	return o, p, d, notPvPZone, pvpDist
end

function drawPipeInfo()
	local zone = ""
	local originPlanet, pipePlanet, pipeDist, notPvPZone, pvpDist = updatePipeInfo()
	if notPvPZone then
		zone = "PvP"
	else
		zone = "Safe"
	end
	pvpDist = getDistanceDisplayString(pvpDist)
	pipeInfoHtml = [[
                                    <style>
                                        .pipeInfo{
                                            position: fixed;
                                            top: 10px;
                                            left: 50%;
                                            transform: translateX(-50%);
                                            text-align: center;
                                            margin-bottom: 20px;
                                        }
                                    </style>
                                    <div class="pipeInfo">
                                        <h1>]] .. originPlanet .. " - " .. pipePlanet .. [[: ]] .. pipeDist .. [[</h1>
                                        <h2>]] .. zone .. [[ Zone in: ]] .. pvpDist .. [[<h2>
                                    </div>
                                    ]]
end

function drawFuelInfo()
	local fuelCSS = [[<style>
                    .fuelInfo {
                        position: fixed;
                        bottom: 40px;
                        left: 28%;
                        witdh: 200px;
                    }
                    .fuel-bar {
                        text-align: center;
                        background: #142027;
                        color: white;
                        font-family: "Lucida" Grande, sans-serif;
                        font-size: 10px;
                        border-radius: 5vh;
                        border: 1px solid;
                        border-color: #098dfe;
                    }
                    .barFullness {
                        padding: 5px;
                        border-radius: 5vh;
                        height: 95%;
                        position: center;
                        text-align: left;
                    }
                    </style>]]

	function addFuelTank(tank, i)
		local color = "green"
		local percent = json.decode(tank.getWidgetData()).percentage
		if percent == nil then
			percent = 0
			color = "red"
		elseif percent < 15 then
			color = "red"
		elseif percent < 50 then
			color = "orange"
		end
		return [[
                       <tr><td style="width:200px"><div class="fuel-bar">
                            <div class="barFullness" style="width: ]] .. percent .. [[%;
                        background:]] .. color .. [[;">]] .. percent .. [[%</div>
                        </div></td></tr>
                    ]]
	end

	fuelHtml = fuelCSS .. [[<table class="fuelInfo">
                        ]]
	if spacefueltank_size > 0 then
		fuelHtml = fuelHtml .. [[<tr>
                            <th>Space</th>
                        </tr>]]
	end
	for i = 1, #spacefueltank do

		fuelHtml = fuelHtml .. addFuelTank(spacefueltank[i], i)
	end
	if atmofueltank_size > 0 then
		fuelHtml = fuelHtml .. [[<tr>
                            <th>Atmo</th>
                        </tr>]]
	end

	for i = 1, #atmofueltank do
		fuelHtml = fuelHtml .. addFuelTank(atmofueltank[i], i)
	end

	if rocketfueltank_size > 0 then
		fuelHtml = fuelHtml .. [[<tr>
                            <th>Rocket</th>
                        </tr>]]
	end

	for i = 1, #rocketfueltank do
		fuelHtml = fuelHtml .. addFuelTank(rocketfueltank[i], i)
	end
	fuelHtml = fuelHtml .. "</table></div>"
end

function brakeHud()
	if isBraking then
		brakeHtml = [[
                        <style>
                        .brake{
                            position: fixed;
                            left: 50%;
                            bottom: 25%;
                            transform: translateX(-50%); 
                            text-align: center;
                            color: red;
                            text-shadow: 2px 2px 2px black;
                        }
                        </style>
                        <h1><div class="brake">Brake Engaged</div></h1>
                    ]]
	else
		brakeHtml = ""
	end
end

function speedInfo()
	local throttle = math.floor(unit.getThrottle())
	local speed = math.floor(vec3(construct.getWorldVelocity()):len() * 3.6)
	local accel = math.floor((vec3(construct.getWorldAcceleration()):len() / 9.80665) * 10) / 10
	local maxSpeed = math.floor(construct.getMaxSpeed() * 3.6)
	local c = 100000000 / 3600
	local m0 = construct.getMass()
	local v0 = vec3(construct.getWorldVelocity())
	local maxBrakeThrust = construct.getMaxBrake()
	local time = 0.0
	dis = 0.0
	local v = v0:len()
	if maxBrakeThrust > 0 then
		while v > 1.0 do
			time = time + 1
			local m = m0 / (math.sqrt(1 - (v * v) / (c * c)))
			local a = maxBrakeThrust / m
			if v > a then
				v = v - a --*1 sec
				dis = dis + v + a / 2.0
			elseif a ~= 0 then
				local t = v / a
				dis = dis + v * t + a * t * t / 2
				v = v - a
			end
		end
	end
	local resString = ""
	if dis > 100000 then
		resString = resString .. string.format(math.floor((dis / 200000) * 10) / 10)
		brakeText = "SU"
	elseif dis > 1000 then
		resString = resString .. string.format(math.floor((dis / 1000) * 10) / 10)
		brakeText = "KM"
	else
		resString = resString .. string.format(math.floor(dis))
		brakeText = "M"
	end

	speedHtml = [[
                                        <style>
                                            h1,h6{
                                            color: #80ffff;
                                            }
                                        table.speed{
                                            position: fixed;
                                            table-layout: fixed;
                                            left: 60%;
                                            bottom: 35%;
                                            border-spacing: 0 10px;
                                            border-collapse: separate;
                                            }
                                        table.speed td{
                                            width: 110px;
                                        }          
                                        </style>
                                            <table class="speed">
                                                <tr>
                                                    <td style="text-align: right;"><h1>]] .. throttle .. [[</h1></td>
                                                    <td>%</td>
                                                </tr>
                                                <tr>
                                                    <td style="text-align: right;"><h1>]] .. speed .. [[</h1></td>
                                                    <td>km/h <h6>(max ]] .. maxSpeed .. [[)</h6></td>
                                                </tr>
                                                <tr>
                                                    <td style="text-align: right;"><h1>]] .. accel .. [[</h1></td>
                                                    <td>g</td>
                                                </tr>
                                                <tr>
                                                    <td style="text-align: right;"><h1>]] .. resString .. [[</h1></td>
                                                    <td>]] .. brakeText .. [[ Brake-Dist</td>
                                                </tr>
                                            </table>

                                    ]]
end

counter = 1
dpmTable = {}
dps = "Calculating"
ttZ = 0
ttZString = "Calculating"
calculating = false
lastShield = shield.getShieldHitpoints()
adjustShield = false
autoAdjustShield = false --export: NOT RECOMMENDED! Will audo adjust every minute based on current stress
shieldDownColor = ""
function enemyDPS()
	local incDmg = 0
	local newShield = shield.getShieldHitpoints()
	local diff = lastShield - newShield
	dpmTable[counter] = diff
	counter = counter + 1
	lastShield = newShield
	local dpmTableLenght = #dpmTable
	for i = 1, dpmTableLenght do
		incDmg = incDmg + dpmTable[i]
	end

	if counter > 60 then
		adjustShield = true
		counter = 1
	end
	if autoAdjustShield then
		autoAdjust()
	end
	if dpmTableLenght > 10 then
		dps = incDmg / dpmTableLenght
		if counter % 5 == 0 then
			ttZ = newShield / dps
			if ttZ < 60 then
				shieldDownColor = "red"
			elseif ttZ < 180 then
				shieldDownColor = "orange"
			end
			ttZString = "~" .. seconds_to_clock(ttZ)
		elseif ttZ > 0 then
			ttZ = ttZ - 1
			ttZString = "~" .. seconds_to_clock(ttZ)
		end

		dps = round(dps / 1000, 2) .. "k"
	end
	if incDmg < 1 and dpmTableLenght == 60 then
		unit.stopTimer("dps")
		dpmTable = {}
		counter = 1
		dps = "Calculating"
		ttZ = 0
		ttZString = "Calculating"
		calculating = false
	end
end

function autoAdjust()
	if adjustShield then
		adjustShield = false
		local sRR = shield.getStressRatioRaw()
		local tot = 0.5999
		if sRR[1] == 0.0 and sRR[2] == 0.0 and sRR[3] == 0.0 and sRR[4] == 0.0 then return end
		local setResist = shield.setResistances((tot * sRR[1]), (tot * sRR[2]), (tot * sRR[3]), (tot * sRR[4]))
	end
end

function drawEnemyDPS()
	local resistances = shield.getResistances()
	local amRes = math.ceil(10 + resistances[1] * 100)
	local elRes = math.ceil(10 + resistances[2] * 100)
	local kiRes = math.ceil(10 + resistances[3] * 100)
	local thRes = math.ceil(10 + resistances[4] * 100)
	local resCd = math.floor(shield.getResistancesCooldown())
	local ventCd = math.floor(shield.getVentingCooldown())

	local sRR = shield.getStressRatioRaw()
	function stressColor(stress)
		if stress > 55 then
			return "red"
		elseif stress > 0 then
			return "orange"
		else
			return ""
		end
	end

	local amStress = math.floor(sRR[1] * 100)
	local elStress = math.floor(sRR[2] * 100)
	local kiStress = math.floor(sRR[3] * 100)
	local thStress = math.floor(sRR[4] * 100)

	if (calculating and shield.isActive() == 1) or shield.isVenting() == 1 or ventCd > 0 then
		enemyDPSHtml = [[
                    <style>
                        .enemyDPS{
                            position: fixed;
                            left: 25%;
                            bottom: 35%;
                        }
                        table.cd{
                            table-layout: fixed;
                            text-align: left;
                        }
                        table.resTable{
                            table-layout: fixed;
                            text-align: center;
                        }
                        table.resTable th {
                            width: 33% ;
                        } 
                    </style>
                    <div class="enemyDPS">
                        <h3>Enemy-DPS: ]] .. dps .. [[</h3>
                        <h3 style="color:]] .. shieldDownColor .. [[">Shield Down in: ]] .. ttZString .. [[</h3>
                        <table class="cd">
                            <tr>
                                <th>Vent-CD: ]] .. ventCd .. [[s</th>
                                <th>Res-CD: ]] .. resCd .. [[s</th>
                            </tr>
                        </table>
                        <table class="resTable">
                            <tr>
                                <th>Type</th>
                                <th>Res</th>
                                <th>Stress</th>
                            </tr>
                            <tr style="color:]] .. stressColor(amStress) .. [[">
                                <td>AM</td>
                                <td>]] .. amRes .. [[%</td>
                                <td>]] .. amStress .. [[%</td>
                            </tr>
                            <tr style="color:]] .. stressColor(elStress) .. [[">
                                <td>EL</td>
                                <td>]] .. elRes .. [[%</td>
                                <td>]] .. elStress .. [[%</td>
                            </tr>
                            <tr style="color:]] .. stressColor(kiStress) .. [[">
                                <td>KI</td>
                                <td>]] .. kiRes .. [[%</td>
                                <td>]] .. kiStress .. [[%</td>
                            </tr>
                            <tr style="color:]] .. stressColor(thStress) .. [[">
                                <td>TH</td>
                                <td>]] .. thRes .. [[%</td>
                               <td>]] .. thStress .. [[%</td>
                            </tr>
                        </table>
                    </div>
                    ]]
	else
		enemyDPSHtml = ""
	end
end

function seconds_to_clock(time_amount)
	local start_seconds = time_amount
	local start_minutes = math.modf(start_seconds / 60)
	local seconds = start_seconds - start_minutes * 60
	local start_hours = math.modf(start_minutes / 60)
	local minutes = start_minutes - start_hours * 60
	local start_days = math.modf(start_hours / 24)
	local hours = start_hours - start_days * 24
	if hours > 0 then
		local wrapped_time = { h = hours, m = minutes, s = seconds }
		return string.format('%02.f:%02.f:%02.f', wrapped_time.h, wrapped_time.m, wrapped_time.s)
	else
		local wrapped_time = { m = minutes, s = seconds }
		return string.format('%02.f:%02.f', wrapped_time.m, wrapped_time.s)
	end
end

shieldMax = shield.getMaxShieldHitpoints()
venting = ""
stressBarHeight = "5"
function drawShield()
	shieldHp = shield.getShieldHitpoints()
	shieldPercent = shieldHp / shieldMax * 100
	if shieldPercent == 100 then shieldPercent = "100"
	else
		shieldPercent = string.format('%0.2f', shieldPercent)
	end
	coreStressPercent = string.format('%0.2f', core.getCoreStressRatio() * 100)
	local shieldHealthBar = [[
                    <style>
                    .health-bar {
                        position: fixed;
                        width: 13em; 
                        padding: 1vh; 
                        bottom: 5vh;
                        left: 50%;
                        transform: translateX(-50%);
                        text-align: center;
                        background: #142027;
                        opacity: 0.8;
                        color: white;
                        font-family: "Lucida" Grande, sans-serif;
                        font-size: 1.5em;
                        border-radius: 5vh;
                        border: 0.2vh solid;
                        border-color: #098dfe;
                    }
                    .bar {
                        padding: 5px;
                        border-radius: 5vh;
                        background: #09c3fe;
                        opacity: 0.8;
                        width: ]] .. shieldPercent .. [[%;
                        height: 40px;
                        position: relative;
                    }


                    </style>
                    <html>
                        <div class="health-bar">
                            <div class="bar">]] .. venting .. shieldPercent .. [[%</div>
                        </div>
                    </html>
                    ]]
	local coreStressBar = [[
                    <style>
                    .stress-health-bar {
                        position: fixed;
                        width: 13em; 
                        padding: 1vh; 
                        bottom:]] .. stressBarHeight .. [[vh;
                        left: 50%;
                        transform: translateX(-50%);
                        text-align: center;
                        background: #142027;
                        opacity: 0.8;
                        color: white;
                        font-family: "Lucida" Grande, sans-serif;
                        font-size: 1.5em;
                        border-radius: 5vh;
                        border: 0.2vh solid;
                        border-color: #a00000;
                    }
                    .stress-bar {
                        padding: 5px;
                        border-radius: 5vh;
                        background: #ff0000;
                        opacity: 0.8;  
                        width: ]] .. coreStressPercent .. [[%;
                        height: 40px;
                        position: relative;
                    }


                    </style>
                    <html>
                        <div class="stress-health-bar">
                            <div class="stress-bar">]] .. coreStressPercent .. [[%</div>
                        </div>
                    </html>
                    ]]
	if shield.isVenting() == 1 then
		stressBarHeight = "15"
		venting = "Venting "
		healthHtml = coreStressBar .. shieldHealthBar
	elseif shield.isActive() == 0 or shield.getShieldHitpoints() == 0 then
		stressBarHeight = "5"
		healthHtml = coreStressBar
	else
		stressBarHeight = "5"
		venting = ""
		healthHtml = shieldHealthBar
	end
end

planetAR = ""
function drawPlanetsOnScreen()
	screenHeight = system.getScreenHeight()
	screenWidth = system.getScreenWidth()
	if lshiftPressed then
		planetAR = [[<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">]]
		for _, v in pairs(planetList) do
			local point = vec3(v.center)
			local distance = (point - vec3(construct.getWorldPosition())):len()
			local planetPosOnScreen = library.getPointOnScreen({ point['x'], point['y'], point['z'] })
			local xP = screenWidth * planetPosOnScreen[1]
			local yP = screenHeight * planetPosOnScreen[2]
			local deth = 12
			local su = (distance / 200 / 1000)
			if su < 10 then
				deth = 250 - 800 * (distance / 1000 / 200 / 40)
			elseif su < 40 then

				deth = 20
			end
			if xP > 0 and yP > 0 then
				alienAR = alienAR .. [[<div style="position: fixed;left: ]] .. xP .. [[px;top:"]] .. yP .. [[px;"</div>]]
				planetAR = planetAR ..
					[[<circle cx="]] ..
					xP ..
					[[" cy="]] ..
					yP ..
					[[" r="]] .. deth .. [[" stroke="orange" stroke-width="1" style="fill-opacity:0" /><text x="]] ..
					xP + deth ..
					[[" y="]] ..
					yP + deth .. [[" fill="#c7dcff">]] .. v.name[1] ..
					" " .. getDistanceDisplayString(distance) .. [[</text>]]
			end
		end
		planetAR = planetAR .. "</svg>"
	else
		planetAR = ""
	end
end

aliencores = { [1] = {
	name = "Alpha",
	pos = { 33946188.8008, 71382020.5906, 28850112.1181 }
}, [2] = {
	name = "Beta",
	pos = { -145633811.1992, -10577969.4094, -739352.8819 }
},
	[3] = {
		name = "Epsilon",
		pos = { 48566188.8008, 19622030.5906, 101000112.1181 }
	},
	[4] = {
		name = "Eta",
		pos = { -73133811.1992, 18722030.5906, -93699887.8819 }
	},
	[5] = {
		name = "Delta",
		pos = { 13666188.8008, 1622030.5906, -46839887.8819 }
	},
	[6] = {
		name = "Kappa",
		pos = { -45533811.1992, -46877969.4094, -739352.8819 }
	},
	[7] = {
		name = "Zeta",
		pos = { 81766188.8008, 16912030.5906, 23860112.1181 }
	},
	[8] = {
		name = "Theta",
		pos = { 58166188.8008, -52377969.4094, -739352.8819 }
	},
	[9] = {
		name = "Iota",
		pos = { 966188.8008, -149277969.4094, -739352.8819 }
	}, [10] = {
		name = "Gamma",
		pos = { -64333811.1992, 55522030.5906, -14399887.8819 }
	},
}

alienAR = ""
function drawAlienCores()
	if lshiftPressed then
		alienAR = ""
		for _, v in pairs(aliencores) do
			local point = vec3(v.pos)
			local distance = (point - vec3(construct.getWorldPosition())):len()
			local alienPosOnScreen = library.getPointOnScreen({ point['x'], point['y'], point['z'] })
			local xP = screenWidth * alienPosOnScreen[1]
			local yP = screenHeight * alienPosOnScreen[2]
			if xP > 0 and yP > 0 then
				alienAR = alienAR ..
					[[<div style="position: fixed;left: ]] .. xP .. [[px;top:]] .. yP .. [[px;"><svg height="30" width="15">
                                <g>
                                    <path style="fill:purple;" d="M8.472,0l-1.28,0.003c-2.02,0.256-3.679,1.104-4.671,2.386C1.685,3.47,1.36,4.78,1.553,6.283
                                        c0.37,2.87,2.773,6.848,4.674,8.486c0.475,0.41,1.081,0.794,1.353,0.899c0.129,0.044,0.224,0.073,0.333,0.073
                                        c0.11,0,0.217-0.031,0.319-0.091c1.234-0.603,2.438-1.88,3.788-4.02c0.936-1.485,2.032-3.454,2.2-5.495
                                        C14.492,2.843,12.295,0.492,8.472,0z M8.435,0.69c3.431,0.447,5.337,2.462,5.097,5.391c-0.156,1.913-1.271,3.875-2.097,5.182
                                        c-1.278,2.027-2.395,3.226-3.521,3.777c-0.005,0.002-0.009,0.004-0.012,0.005c-0.029-0.006-0.068-0.021-0.087-0.027
                                        c-0.149-0.057-0.706-0.401-1.135-0.771c-1.771-1.525-4.095-5.375-4.44-8.052C2.07,4.879,2.348,3.741,3.068,2.812
                                        c0.878-1.135,2.363-1.889,4.168-2.12L8.435,0.69z"/>
                                    <path style="fill:purple;" d="M3.504,6.83C3.421,6.857,3.37,6.913,3.373,7.024c0.308,1.938,1.616,3.536,3.842,3.126
                                        C7.002,8.019,5.745,6.933,3.504,6.83z"/>
                                    <path style="fill:purple;" d="M8.778,10.215c2.196-0.125,3.61-1.379,3.776-3.319C10.321,6.727,8.55,7.923,8.778,10.215z"/>
                                </g>
                            </svg>]] .. v.name .. " " .. getDistanceDisplayString(distance) .. [[</div>]]
			end
		end
	else
		alienAR = ""
	end
end

function combineHudElements()
	drawFuelInfo()
	brakeHud()
	speedInfo()
	drawPipeInfo()
	drawEnemyDPS()
	drawShield()
	system.setScreen(alienAR .. planetAR .. fuelHtml .. brakeHtml .. speedHtml .. pipeInfoHtml .. enemyDPSHtml .. healthHtml)
end

unit.setTimer("hud", 0.1)
system.showScreen(1)
if switch_1 ~= nil then switch_1.activate() end
